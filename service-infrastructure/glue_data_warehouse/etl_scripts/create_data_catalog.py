import boto3
import sys

from pathlib import Path
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'S3_BUCKET', 'CONNECTION_NAME', 'CATALOG_TABLE_NAME', "DB_TABLE_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Default ruleset used by all target nodes with data quality enabled
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

DATABASE_NAME =  args['DATABASE_NAME']
S3_BUCKET = args['S3_BUCKET']
CONNECTION_NAME = args['CONNECTION_NAME']
CATALOG_TABLE_NAME = args['CATALOG_TABLE_NAME']
DB_TABLE_NAME = args['DB_TABLE_NAME']

possible_locations = [f"{CATALOG_TABLE_NAME}_{i}" for i in ["A", "B"]]

glue = boto3.client('glue')

try:
    table_response = glue.get_table(DatabaseName=DATABASE_NAME, Name=CATALOG_TABLE_NAME)
    table_info = table_response['Table']
except glue.exceptions.EntityNotFoundException:
    logger.warn(f"Table \"{CATALOG_TABLE_NAME}\" not found")
    table_info = {}

if table_info:
    current_s3_location = table_info['StorageDescriptor']['Location']
    logger.warn(f"Current S3 location for table {CATALOG_TABLE_NAME}: {current_s3_location}")
    current_location = Path(current_s3_location).name
    try:
        next_location_index = (possible_locations.index(current_location) + 1) % (len(possible_locations))
    except ValueError:
        next_location_index = 0
else:
    next_location_index = 0

next_location = possible_locations[next_location_index]

S3_OUTPUT_PATH=f"s3://{S3_BUCKET}/{next_location}/"

logger.warn(f"Data location in S3 for table \"{CATALOG_TABLE_NAME}\": {S3_OUTPUT_PATH}")

# Script generated for node PostgreSQL
PostgreSQL_node1738584178209 = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": DB_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_node1738584178209"
)

# Script generated for node Amazon S3
EvaluateDataQuality().process_rows(frame=PostgreSQL_node1738584178209, ruleset=DEFAULT_DATA_QUALITY_RULESET, publishing_options={"dataQualityEvaluationContext": "EvaluateDataQuality_node1738584171296", "enableDataQualityResultsPublishing": True}, additional_options={"dataQualityResultsPublishing.strategy": "BEST_EFFORT", "observations.scope": "ALL"})
AmazonS3_node1738584350700 = glueContext.getSink(path=S3_OUTPUT_PATH, connection_type="s3", updateBehavior="UPDATE_IN_DATABASE", partitionKeys=[], enableUpdateCatalog=True, transformation_ctx="AmazonS3_node1738584350700")
AmazonS3_node1738584350700.setCatalogInfo(catalogDatabase=DATABASE_NAME,catalogTableName=CATALOG_TABLE_NAME)
AmazonS3_node1738584350700.setFormat("glueparquet", compression="snappy")
AmazonS3_node1738584350700.writeFrame(PostgreSQL_node1738584178209)

# Switch Glue Table location only if the table was present
if table_info:
    logger.warn("Updating Location on glue table")

    # Switch over to the new S3 location
    table_info['StorageDescriptor']['Location'] = S3_OUTPUT_PATH
    glue.update_table(
        DatabaseName=DATABASE_NAME,
        TableInput={
            'Name': table_info['Name'],
            'StorageDescriptor': table_info['StorageDescriptor'],
            'PartitionKeys': table_info.get('PartitionKeys', []),
            'TableType': table_info.get('TableType', 'EXTERNAL_TABLE'),
            'Parameters': table_info.get('Parameters', {})
        }
    )
    logger.warn(f"Location updated, deleting old S3 bucket directory \"{current_location}\"")

    s3 = boto3.resource('s3')
    bucket = s3.Bucket(S3_BUCKET)
    bucket.objects.filter(Prefix=f"{current_location}/").delete()

    logger.warn("S3 bucket directory removed")

job.commit()