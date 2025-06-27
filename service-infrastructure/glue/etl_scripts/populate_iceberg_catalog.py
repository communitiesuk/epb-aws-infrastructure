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
S3_PATH=f"s3://{S3_BUCKET}/{CATALOG_TABLE_NAME}/"
COLUMNS =  args['COLUMNS']

sql_spark = (
    SparkSession.builder
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_PATH)
    .config("spark.sql.catalog.glue_catalog.job-language", "python")
    .getOrCreate()
)

sql_spark.sql(f"""
  CREATE TABLE IF NOT EXISTS glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME}(
      {COLUMNS}
)
USING iceberg
LOCATION '{S3_PATH}'
TBLPROPERTIES (
  'write.format.default' = 'parquet',
  'write.compression.codec' = 'zstd',
  'optimize_rewrite_delete_file_threshold'='5'
)
""");

sts = boto3.client("sts")
iam = boto3.client("iam")
glue = boto3.client("glue")

identity = sts.get_caller_identity()

role_name = identity["Arn"].split("/")[-2]
role = iam.get_role(RoleName=role_name)
role_arn = role["Role"]["Arn"]


def get_catalog_id(catalog_name):
    response = glue.get_databases()

    for db in response["DatabaseList"]:
        if db["Name"] == catalog_name:
            return db["CatalogId"]


optimizer_configurations = {
    "compaction": {},
    "retention": {
        "retentionConfiguration": {
            "icebergConfiguration": {
                "snapshotRetentionPeriodInDays": 3,
                "numberOfSnapshotsToRetain": 1,
                "cleanExpiredFiles": True,
            }
        }
    },
    "orphan_file_deletion": {},
}


for optimizer_type in optimizer_configurations.keys():

    try:
        logger.warn(f"Trying to create optimizer for {optimizer_type}")

        glue.create_table_optimizer(
            CatalogId=get_catalog_id(DATABASE_NAME),
            DatabaseName=DATABASE_NAME,
            TableName=CATALOG_TABLE_NAME,
            Type=optimizer_type,
            TableOptimizerConfiguration={
                "roleArn": role_arn,
                "enabled": True,
                **optimizer_configurations[optimizer_type],
            },
        )
        logger.warn(f"Optimizer {optimizer_type} configured")
    except glue.exceptions.AlreadyExistsException:
        logger.warn(f"Table optimizer of type {optimizer_type} already present")


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
AWSGlueDataCatalog_node1748526922140_df = glueContext.create_data_frame.from_catalog(database=DATABASE_NAME, table_name=CATALOG_TABLE_NAME)

postgres_df = PostgreSQL_node1748526875522.toDF()
postgres_df.createOrReplaceTempView(DB_TABLE_NAME)

columns = [f.name for f in spark.table(DB_TABLE_NAME).schema.fields]
column_list = ", ".join(columns)
value_list = ", ".join([f"source.{col}" for col in columns])

spark.sql(f"""
MERGE INTO glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME} AS target
USING {DB_TABLE_NAME} AS source
ON target.rrn = source.rrn
WHEN NOT MATCHED THEN
    INSERT ({column_list}) VALUES ({value_list})
""")

job.commit()
