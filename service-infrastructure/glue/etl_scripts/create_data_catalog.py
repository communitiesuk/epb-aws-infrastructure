import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'S3_BUCKET', 'CONNECTION_NAME', 'CATALOG_TABLE_NAME', "DB_TABLE_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
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
S3_OUTPUT_PATH=f"s3://{S3_BUCKET}/{CATALOG_TABLE_NAME}/"

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
job.commit()