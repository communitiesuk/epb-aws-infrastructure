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

class S3MultipartWriter(io.RawIOBase):
    def __init__(self, s3_client, bucket, key, chunk_size=50 * 1024 * 1024):
        self.s3_client = s3_client
        self.bucket = bucket
        self.key = key
        self.chunk_size = chunk_size
        self.parts = []
        self.part_number = 1
        self.buffer = bytearray()
        resp = s3_client.create_multipart_upload(Bucket=bucket, Key=key)
        self.upload_id = resp["UploadId"]

    def write(self, b):
        self.buffer.extend(b)
        while len(self.buffer) >= self.chunk_size:
            self._upload_part(self.buffer[:self.chunk_size])
            del self.buffer[:self.chunk_size]
        return len(b)

    def _upload_part(self, data):
        part = self.s3_client.upload_part(
            Bucket=self.bucket,
            Key=self.key,
            PartNumber=self.part_number,
            UploadId=self.upload_id,
            Body=bytes(data),
        )
        self.parts.append({"PartNumber": self.part_number, "ETag": part["ETag"]})
        self.part_number += 1

    def close(self):
        if self.buffer:
            self._upload_part(self.buffer)
        self.s3_client.complete_multipart_upload(
            Bucket=self.bucket,
            Key=self.key,
            UploadId=self.upload_id,
            MultipartUpload={"Parts": self.parts},
        )
        super().close()

    def abort(self):
        self.s3_client.abort_multipart_upload(
            Bucket=self.bucket, Key=self.key, UploadId=self.upload_id
        )

    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is None:
            self.close()
        else:
            self.abort()


required_args = ["JOB_NAME", "TABLE_NAME", "S3_BUCKET", "DATABASE_NAME", "ASSESSMENT_TYPES", "EPC_TYPE"]


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
EPC_TYPE = args["EPC_TYPE"]
ASSESSMENT_TYPES = args.get("ASSESSMENT_TYPES")
S3_PREFIX = f"{EPC_TYPE}/{TABLE_NAME}/full-load/"
S3_OUTPUT_PATH = f"s3://{S3_BUCKET}/{S3_PREFIX}"
ZIP_FILE_KEY = f"{S3_PREFIX}{TABLE_NAME}.zip"


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
df = glueContext.create_data_frame.from_catalog(
    database=DATABASE_NAME, table_name=TABLE_NAME
)

# Get unique years
years = [
    row.year
    for row in df.select("year").filter(df["year"].isNotNull()).distinct().collect()
]

assessment_types = [t for t in ASSESSMENT_TYPES.split(",")]

def generate_json_per_year(df, table_name, years, assessment_types):
    for year in years:
        logger.warn(f'Processing table "{table_name}" year: {year}')

        assessment_types_df = df.filter(F.col("assessment_type").isin(assessment_types))
        year_df = assessment_types_df.filter(F.col("year") == year).drop("year").repartition(1)

        output_folder = f"{S3_OUTPUT_PATH}{table_name}-{year}/"
        year_df.write.mode("overwrite").json(output_folder)
        logger.warn(f'Finished processing table: "{table_name}" year: {year}')

logger.warn(f'Will start processing "{TABLE_NAME}"')

generate_json_per_year(df, TABLE_NAME, years, assessment_types)

logger.warn(f'Starting ZIP file stream to S3"')
chunk_size_bytes = 1024 * 1024 * 50
logger.warn(f'The chunk size will be "{chunk_size_bytes}"')

with S3MultipartWriter(s3_client, S3_BUCKET, ZIP_FILE_KEY, chunk_size=chunk_size_bytes) as mpw:
    logger.warn(f'S3MultipartWriter created"')

    with zipfile.ZipFile(mpw, mode="w", compression=zipfile.ZIP_DEFLATED, allowZip64=True) as zipf:
        for year in years:
            prefix = f"{S3_PREFIX}{TABLE_NAME}-{year}/"
            logger.warn(f'S3 Prefix to inspect "{prefix}"')

            response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)
            if "Contents" in response:
                logger.warn(f'Response has Contents')

                for obj in response["Contents"]:
                    logger.warn(f'File from S3 being processed: "{obj["Key"]}"')

                    if obj["Key"].endswith(".json"):
                        logger.warn(f"Streaming {obj['Key']} into zip")
                        zi = zipfile.ZipInfo(f"certificates-{year}.json")
                        zi.compress_type = zipfile.ZIP_DEFLATED
                        with zipf.open(zi, mode="w", force_zip64=True) as zf_entry:
                            body = s3_client.get_object(Bucket=S3_BUCKET, Key=obj["Key"])["Body"]
                            for chunk in iter(lambda: body.read(10 * 1024 * 1024), b""):  # 10 MB
                                zf_entry.write(chunk)
                        s3_client.delete_object(Bucket=S3_BUCKET, Key=obj["Key"])

                        break
job.commit()