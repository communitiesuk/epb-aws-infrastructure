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

record_count = df.count()

print(f"Number of JSON records read: {record_count}")

# -----------------------------
# Filter valid OSG_UPRN rows
# -----------------------------
with_osg = df.filter(F.col("OSG_UPRN").isNotNull())

# -----------------------------
# Build update dataset
# -----------------------------
updates = (
    with_osg.select(
        F.col("RRN").alias("assessment_id"),
        F.concat(
            F.lit("UPRN-"),
            F.lpad(F.col("OSG_UPRN").cast("string"), 12, "0")
        ).alias("address_id"),
        F.lit("EST_OSG_UPRN").alias("source")
    )
    # important for large datasets → improves JDBC parallelism
    .repartition(50)
    .dropDuplicates(["assessment_id"])
    .cache()
)

update_count = updates.count()

print(f"Number of updates to process: {update_count}")

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

try:
    cur = conn.cursor()

    # Ensure single atomic update
    cur.execute("BEGIN")

    cur.execute("""
        UPDATE scotland.assessments_address_id a
        SET
            address_id = u.address_id,
            source = u.source
        FROM scotland.assessments_address_id_updates u
        WHERE a.assessment_id = u.assessment_id
    """)

    cur.execute("DROP TABLE IF EXISTS scotland.assessments_address_id_updates")

    cur.execute("COMMIT")

finally:
    cur.close()
    conn.close()

job.commit()