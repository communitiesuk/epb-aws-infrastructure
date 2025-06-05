import boto3
import sys

from pathlib import Path
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality

from pyspark.sql import SparkSession

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'S3_BUCKET', 'CONNECTION_NAME', 'CATALOG_TABLE_NAME', "DB_TABLE_NAME", "COLUMNS"])

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
S3_OUTPUT_PATH=f"s3://{S3_BUCKET}/{CATALOG_TABLE_NAME}/"
COLUMNS =  args['COLUMNS']

sql_spark = (
    SparkSession.builder
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_OUTPUT_PATH)
    .config("spark.sql.catalog.glue_catalog.job-language", "python")
    .getOrCreate()
)

sql_spark.sql(f"""
  CREATE TABLE IF NOT EXISTS glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME}(
      {COLUMNS}
)
USING iceberg
LOCATION '{S3_OUTPUT_PATH}'
TBLPROPERTIES (
  'write.format.default' = 'parquet',
  'write.compression.codec' = 'zstd'
)
""");


# Script generated for node PostgreSQL
PostgreSQL_node1748526875522 = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": DB_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_node1748526875522"
)

# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1748526922140_df = PostgreSQL_node1748526875522.toDF()
AWSGlueDataCatalog_node1748526922140 = glueContext.write_data_frame.from_catalog(frame=AWSGlueDataCatalog_node1748526922140_df, database=DATABASE_NAME, table_name=CATALOG_TABLE_NAME, additional_options={})
job.commit()