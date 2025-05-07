import sys
import io
import zipfile
import boto3
from pyspark.sql import functions as F
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

required_args = ["JOB_NAME", "TABLE_NAME", "S3_BUCKET", "DATABASE_NAME"]

if any(arg.startswith("--TABLE_NAME_RR") for arg in sys.argv):
    required_args.append("TABLE_NAME_RR")


# Get job arguments
args = getResolvedOptions(sys.argv, required_args)

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Configuration
DATABASE_NAME = args["DATABASE_NAME"]
TABLE_NAME = args["TABLE_NAME"]
S3_BUCKET = args["S3_BUCKET"]
S3_PREFIX = f"{TABLE_NAME}/full-load/"
S3_OUTPUT_PATH = f"s3://{S3_BUCKET}/{S3_PREFIX}"
ZIP_FILE_KEY = f"{S3_PREFIX}{TABLE_NAME}.zip"
TABLE_NAME_RR = args.get("TABLE_NAME_RR")


s3_client = boto3.client("s3")

# Read data from Glue Catalog
dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=DATABASE_NAME, table_name=TABLE_NAME
)

df = dynamic_frame.toDF().withColumn("year", F.year(F.col("lodgement_date")))

# Get unique years
years = [
    row.year
    for row in df.select("year").filter(df["year"].isNotNull()).distinct().collect()
]


if TABLE_NAME_RR:
    logger.warn(f'Received table "{TABLE_NAME_RR}" for recommendations')

    df_rr = glueContext.create_dynamic_frame.from_catalog(
        database=DATABASE_NAME, table_name=TABLE_NAME_RR
    ).toDF()

    joined_df = (
        df.select("rrn", "year")
        .dropDuplicates(["rrn"])
        .join(df_rr, on="rrn", how="inner")
    )


def process_and_zip(df, table_name, years, zipf, csv_filename=None):
    if not csv_filename:
        csv_filename = table_name

    for year in years:
        logger.warn(f'Processing table "{table_name}" year: {year}')
        year_df = df.filter(F.col("year") == year).drop("year").repartition(1)

        output_folder = f"{S3_OUTPUT_PATH}{table_name}-{year}/"
        year_df.write.mode("overwrite").option("header", "true").csv(output_folder)

        prefix = f"{S3_PREFIX}{table_name}-{year}/"
        response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)

        if "Contents" in response:
            for obj in response["Contents"]:
                if obj["Key"].endswith(".csv"):
                    logger.warn(f"Processing file: {obj['Key']}")
                    file_obj = s3_client.get_object(Bucket=S3_BUCKET, Key=obj["Key"])
                    zipf.writestr(f"{csv_filename}-{year}.csv", file_obj["Body"].read())

                    for obj in response["Contents"]:
                        s3_client.delete_object(Bucket=S3_BUCKET, Key=obj["Key"])
                    break  # Only process the first CSV file
        else:
            logger.warn(f'No CSV found for table "{table_name}" year {year}')


zip_buffer = io.BytesIO()
with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zipf:
    logger.warn(f'Will start processing "{TABLE_NAME}"')
    process_and_zip(df, TABLE_NAME, years, zipf, csv_filename="certificates")

    if TABLE_NAME_RR:
        logger.warn(f'Will start processing "{TABLE_NAME_RR}" for recommendations')
        process_and_zip(joined_df, TABLE_NAME_RR, years, zipf, csv_filename="recommendations")

# Upload ZIP to S3
zip_buffer.seek(0)
s3_client.put_object(Bucket=S3_BUCKET, Key=ZIP_FILE_KEY, Body=zip_buffer)

job.commit()
