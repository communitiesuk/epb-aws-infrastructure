import io
import sys
import zipfile

import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from boto3.s3.transfer import TransferConfig
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql import SparkSession

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



sql_spark = (
    SparkSession.builder
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_OUTPUT_PATH)
    .config("spark.sql.catalog.glue_catalog.job-language", "python")
    .getOrCreate()
)

s3_client = boto3.client("s3")

# Read data from Glue Catalog
frame = glueContext.create_data_frame.from_catalog(
    database=DATABASE_NAME, table_name=TABLE_NAME
)

df = frame.withColumn("year", F.year(F.col("lodgement_date")))

# Get unique years
years = [
    row.year
    for row in df.select("year").filter(df["year"].isNotNull()).distinct().collect()
]


if TABLE_NAME_RR:
    logger.warn(f'Received table "{TABLE_NAME_RR}" for recommendations')

    df_rr = glueContext.create_data_frame.from_catalog(
        database=DATABASE_NAME, table_name=TABLE_NAME_RR
    )

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

# The start of upload ZIP to S3
zip_buffer.seek(0)
chunk_size_bytes = 1024 * 1024 * 300
logger.warn(f'The chunk size will be "{chunk_size_bytes}"')

# Create a multipart upload
response = s3_client.create_multipart_upload(Bucket=S3_BUCKET, Key=ZIP_FILE_KEY)
upload_id = response["UploadId"]

# Initialize part number and parts list
part_number = 1
parts = []

try:
    while True:
        chunk = zip_buffer.read(chunk_size_bytes)
        if not chunk:
            break
        part = s3_client.upload_part(
            Bucket=S3_BUCKET,
            Key=ZIP_FILE_KEY,
            Body=chunk,
            PartNumber=part_number,
            UploadId=upload_id,
        )
        logger.warn(f'Part number uploaded "{part_number}"')
        parts.append({"PartNumber": part_number, "ETag": part["ETag"]})
        part_number += 1

    logger.warn(f'All parts uploaded. Ready to complete the upload"')

    # Complete the multipart upload
    s3_client.complete_multipart_upload(
        Bucket=S3_BUCKET,
        Key=ZIP_FILE_KEY,
        UploadId=upload_id,
        MultipartUpload={"Parts": parts},
    )
    logger.warn(f'Completed the multipart upload"')

except Exception as e:
    # Handle any exceptions, such as cleanup or logging
    logger.error(f'Error: "{e}"')
    # Optionally abort the multipart upload if an error occurs
    s3_client.abort_multipart_upload(
        Bucket=S3_BUCKET, Key=ZIP_FILE_KEY, UploadId=upload_id
    )
    raise  # Re-raise the exception after cleanup

job.commit()
