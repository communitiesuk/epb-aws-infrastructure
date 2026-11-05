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
        .cache()
)


# Add optional columns if they were completely absent to prevent later errors
optional_columns = [
    "RRN",
    "DEC-RRN",
    "AR-RRN",
    "CreatedAt"
]

for column in optional_columns:
    if column not in df.columns:
        df = df.withColumn(
            column,
            F.lit(None).cast("string")
        )

record_count = df.count()

print(f"Number of JSON records read: {record_count}")

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
# Filter valid CreatedAt rows
# -----------------------------
with_created_at = df.filter(F.col("CreatedAt").isNotNull())

# -----------------------------
# Build update dataset
# -----------------------------
updates = (
    with_created_at.select(
        F.col("assessment_id").alias("assessment_id"),
        F.to_timestamp(F.col("CreatedAt")).alias("created_at")
    )
    # important for large datasets → improves JDBC parallelism
    .repartition(50)
    .dropDuplicates(["assessment_id"])
    .cache()
)

update_count = updates.count()

print(f"Number of updates to process: {update_count}")

# -----------------------------
# Write staging table (overwrite) CHECK!!!!
# -----------------------------
(
    updates.write
        .format("jdbc")
        .option("url", JDBC_URL)
        .option("dbtable", "scotland.assessments_updates")
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

try:
    cur = conn.cursor()

    # Ensure single atomic update
    cur.execute("BEGIN")

    cur.execute("""
        UPDATE scotland.assessments a
        SET
            created_at = u.created_at
        FROM scotland.assessments_updates u
        WHERE a.assessment_id = u.assessment_id
    """)

    cur.execute("DROP TABLE IF EXISTS scotland.assessments_updates")

    cur.execute("COMMIT")

finally:
    cur.close()
    conn.close()

job.commit()