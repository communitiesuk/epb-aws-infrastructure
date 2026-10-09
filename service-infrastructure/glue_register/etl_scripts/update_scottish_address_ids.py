import sys
import pg8000
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql import Window
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "INPUT_S3_PATH",
        "GLUE_CONNECTION_NAME",
        "DB_HOST",
        "DB_PORT",
        "DB_NAME"
    ]
)

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session
job = Job(glue_context)
job.init(args["JOB_NAME"], args)

# -----------------------------
# Get database details from connection
# -----------------------------
connection_options = glue_context.extract_jdbc_conf(
    args["GLUE_CONNECTION_NAME"]
)

JDBC_URL = connection_options["fullUrl"]
DB_USER = connection_options["user"]
DB_PASSWORD = connection_options["password"]

# -----------------------------
# Read JSON (optimised parsing)
# -----------------------------

df = (
    spark.read
        .option("multiLine", "true")
        .json(args["INPUT_S3_PATH"])
)

# Add optional columns if they were completely absent to prevent later errors
optional_columns = [
    "OSG_UPRN",
    "EST_UPRN",
    "RRN",
    "DEC-RRN",
    "AR-RRN"
]

for column in optional_columns:
    if column not in df.columns:
        df = df.withColumn(
            column,
            F.lit(None).cast("string")
        )

input_record_count = df.count()

print(
    f"Number of JSON records read: {input_record_count}"
)

# For DEC-AR metadata this will split out records with both DEC and AR RRNs so both records get updated
# If there is just a DEC-RRN, this will be used as the assessment_id
# For everything else it will use the RRN as the assessment_id
df = (
    df
    .withColumn(
        "assessment_ids",
        F.when(
            F.col("RRN").isNotNull(),
            F.array(F.col("RRN"))
        ).otherwise(
            F.array(
                F.col("DEC-RRN"),
                F.col("AR-RRN")
            )
        )
    )
    .withColumn(
        "assessment_id",
        F.explode("assessment_ids")
    )
    .filter(F.col("assessment_id").isNotNull())
)

df = df.cache()

assessment_record_count = df.count()

print(
    f"Number of assessment IDs found: {assessment_record_count}"
)

# -----------------------------
# Filter valid rows with and without an OSG_UPRN assigned
# -----------------------------
with_osg = df.filter(F.col("OSG_UPRN").isNotNull())

without_osg = (
    df.filter(
        (F.col("OSG_UPRN").isNull())
        & (F.col("EST_UPRN").isNotNull())
    )
    .withColumn(
        "created_at_timestamp",
        F.to_timestamp("CreatedAt")
    )
)

unmatched = df.filter(
    (F.col("OSG_UPRN").isNull())
    & (F.col("EST_UPRN").isNull())
)

unmatched_count = unmatched.count()

print(f"Number of records with neither OSG_UPRN nor EST_UPRN: {unmatched_count}")

# -----------------------------
# Build uprn update dataset
# -----------------------------
uprn_updates = (
    with_osg.select(
        F.col("assessment_id").alias("assessment_id"),
        F.concat(
            F.lit("UPRN-"),
            F.lpad(F.col("OSG_UPRN").cast("string"), 12, "0")
        ).alias("address_id"),
        F.lit("est_osg_uprn").alias("source")
    )
)

uprn_update_count = uprn_updates.count()

print(f"Number of uprn address_id updates to process: {uprn_update_count}")

# -----------------------------
# Build rrn update dataset
# -----------------------------
# For assessments without UPRNs, we want to group them by EST_UPRN, find the oldest assessment in each group,
# and then use the rrn from that assessment as the new address_id for all the assessments in that group

oldest_assessment_window = (
    Window
        .partitionBy("EST_UPRN")
        .orderBy(
            F.col("created_at_timestamp").asc_nulls_last(),
            F.col("assessment_id").asc() # deterministic tie break
        )
)

oldest_assessments = (
    without_osg
        .withColumn(
            "row_number",
            F.row_number().over(oldest_assessment_window)
            )
        .filter(F.col("row_number") == 1)
        .select(
            "EST_UPRN",
            F.concat(
                F.lit("RRN-"),
                F.col("assessment_id")
                ).alias("address_id")
            )
    )

rrn_updates = (
    without_osg.alias("wo")
        .join(
            oldest_assessments.alias("o"),
            F.col("wo.EST_UPRN") == F.col("o.EST_UPRN"),
            "inner"
        )
        .select(
            F.col("wo.assessment_id").alias("assessment_id"),
            F.col("o.address_id").alias("address_id"),
            F.lit("est_rrn").alias("source")
        )
    )

rrn_update_count = rrn_updates.count()

print(f"Number of rrn address_id updates to process: {rrn_update_count}")

# -----------------------------
# Build combined update dataset
# -----------------------------

duplicate_count = (
    uprn_updates
        .select("assessment_id")
        .intersect(
            rrn_updates.select("assessment_id")
        )
        .count()
)

if duplicate_count > 0:
    raise ValueError(
        f"Found {duplicate_count} assessment_ids in both datasets"
    )

updates = (uprn_updates
          .unionByName(rrn_updates)
          .withColumn(
              "address_updated_at",
              F.current_timestamp()
              )
          .repartition(50)
          .cache()
          )

update_count = updates.count()

print(f"Number of combined address_id updates to process: {update_count}")

# -----------------------------
# Write staging table (overwrite)
# -----------------------------
(
    updates.write
        .format("jdbc")
        .option("url", JDBC_URL)
        .option("dbtable", "scotland.assessments_address_id_updates")
        .option("user", DB_USER)
        .option("password", DB_PASSWORD)
        .option("driver", "org.postgresql.Driver")
        .option("batchsize", "10000")
        .mode("overwrite")
        .save()
)

# -----------------------------
# Apply update in Postgres
# -----------------------------
conn = pg8000.connect(
    host=args["DB_HOST"],
    port=int(args["DB_PORT"]),
    database=args["DB_NAME"],
    user=DB_USER,
    password=DB_PASSWORD
)

cur = None

try:
    cur = conn.cursor()

    cur.execute("""
        UPDATE scotland.assessments_address_id a
        SET
            address_id = u.address_id,
            source = u.source,
            address_updated_at = u.address_updated_at
        FROM scotland.assessments_address_id_updates u
        WHERE a.assessment_id = u.assessment_id
    """)

    address_ids_updated = cur.rowcount

    cur.execute("DROP TABLE IF EXISTS scotland.assessments_address_id_updates")

    conn.commit()

    print(f"Number of address_ids updated: {address_ids_updated}")

except Exception:

    conn.rollback()
    raise

finally:
    if cur is not None:
        cur.close()

    conn.close()

job.commit()