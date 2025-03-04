import sys
import io
import zipfile
import boto3
from pyspark.sql import functions as F
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Get job arguments
args = getResolvedOptions(sys.argv,
                          ['JOB_NAME',
                           'TABLE_NAME',
                           'S3_BUCKET'
                         ])
sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Configuration
DATABASE_NAME = "epb-stag-glue-catallogue"
TABLE_NAME = args['TABLE_NAME']
S3_BUCKET = args['S3_BUCKET']
S3_PREFIX = f"glue-data/pre-canned/{TABLE_NAME}/full-load/"
S3_OUTPUT_PATH = f"s3://{S3_BUCKET}/{S3_PREFIX}"
ZIP_FILE_KEY = f"{S3_PREFIX}{TABLE_NAME}.zip"

s3_client = boto3.client('s3')

# Read data from Glue Catalog
dynamic_frame = glueContext.create_dynamic_frame.from_catalog(
    database=DATABASE_NAME, table_name=TABLE_NAME
)

df = dynamic_frame.toDF().withColumn("year", F.year(F.col("lodgement_date")))

# Get unique years
years = [row.year for row in df.select("year").filter(df["year"].isNotNull()).distinct().collect()]

zip_buffer = io.BytesIO()
with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for year in years:
        year_df = df.filter(F.col("year") == year).drop("year").repartition(1)
        logger.warn(f"Processing year: {year}")

        output_folder = f"{S3_OUTPUT_PATH}{TABLE_NAME}-{year}/"
        year_df.write.mode("overwrite").option("header", "true").csv(output_folder)

        prefix = f"{S3_PREFIX}{TABLE_NAME}-{year}/"
        response = s3_client.list_objects_v2(Bucket=S3_BUCKET, Prefix=prefix)

        if 'Contents' in response:
            for obj in response['Contents']:
                if obj['Key'].endswith('.csv'):
                    logger.warn(f"Processing file: {obj['Key']}")
                    file_obj = s3_client.get_object(Bucket=S3_BUCKET, Key=obj['Key'])
                    zipf.writestr(f"{TABLE_NAME}-{year}.csv", file_obj['Body'].read())

                    for obj in response['Contents']:
                        s3_client.delete_object(Bucket=S3_BUCKET, Key=obj['Key'])
                    break  # Only process the first CSV file
        else:
            logger.warn(f"No CSV found for year {year}")

# Upload ZIP to S3
zip_buffer.seek(0)
s3_client.put_object(Bucket=S3_BUCKET, Key=ZIP_FILE_KEY, Body=zip_buffer)

job.commit()