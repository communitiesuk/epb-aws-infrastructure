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

# -------------------------------------------------------
#               PARSE JOB ARGUMENTS
# -------------------------------------------------------
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'S3_BUCKET', 'CONNECTION_NAME', 'CATALOG_TABLE_NAME', "DB_TABLE_NAME"])

DATABASE_NAME =  args['DATABASE_NAME']
S3_BUCKET = args['S3_BUCKET']
CONNECTION_NAME = args['CONNECTION_NAME']
CATALOG_TABLE_NAME = args['CATALOG_TABLE_NAME']
DB_TABLE_NAME = args['DB_TABLE_NAME']

S3_PATH=f"s3://{S3_BUCKET}/{CATALOG_TABLE_NAME}/"
GLUE_TABLE_PATH = f"glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME}"

# -------------------------------------------------------
#               SETUP SPARK + GLUE CONTEXT
# -------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info("Glue job initialized successfully.")

# -------------------------------------------------------
#        INITIALIZE ICEBERG CATALOG IF NECESSARY
# -------------------------------------------------------
logger.info("Creating Iceberg table if it does not exist.")

sql_spark = (
    SparkSession.builder
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_PATH)
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.glue_catalog.job-language", "python")
    .getOrCreate()
)

sql_spark.sql(f"""
  CREATE TABLE IF NOT EXISTS {GLUE_TABLE_PATH}
  USING iceberg
  LOCATION '{S3_PATH}'
  TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.compression.codec' = 'zstd',
    'optimize_rewrite_delete_file_threshold'='5'
 )
""");

logger.info("Iceberg table ensured.")

# -------------------------------------------------------
#             CONFIGURE TABLE OPTIMIZERS
# -------------------------------------------------------
sts = boto3.client("sts")
iam = boto3.client("iam")
glue = boto3.client("glue")

identity = sts.get_caller_identity()

role_name = identity["Arn"].split("/")[-2]
role = iam.get_role(RoleName=role_name)
role_arn = role["Role"]["Arn"]


def get_catalog_id(glue_client, catalog_name):
    response = glue_client.get_databases()

    for db in response["DatabaseList"]:
        if db["Name"] == catalog_name:
            return db["CatalogId"]

def set_optimizers_status(glue_client, db, table, optimizer_types, enabled=True):
    for opt_type in optimizer_types:
        try:
            optimizer = glue_client.get_table_optimizer(
                CatalogId=get_catalog_id(glue_client, db),
                DatabaseName=db,
                TableName=table,
                Type=opt_type
            )

            if optimizer['TableOptimizerConfiguration']['enabled'] != enabled:
                logger.info(f"Setting {opt_type} optimizer 'enabled' to {enabled}")

                new_config = optimizer['TableOptimizerConfiguration'].copy()
                new_config['enabled'] = enabled

                glue_client.update_table_optimizer(
                    CatalogId=get_catalog_id(glue_client, db),
                    DatabaseName=db,
                    TableName=table,
                    Type=opt_type,
                    TableOptimizerConfiguration=new_config
                )
        except glue_client.exceptions.EntityNotFoundException:
            logger.warn(f"Optimizer {opt_type} not found. Skipping status update.")
        except Exception as e:
            logger.error(f"Failed to update {opt_type}: {str(e)}")

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
            CatalogId=get_catalog_id(glue, DATABASE_NAME),
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

logger.warn("Pausing optimizers to prevent race conditions.")
set_optimizers_status(glue, DATABASE_NAME, CATALOG_TABLE_NAME, optimizer_configurations.keys(), enabled=False)

# -------------------------------------------------------
#       EXTRACT DATA FROM POSTGRESQL SOURCE
# -------------------------------------------------------
logger.info("Reading source table from PostgreSQL.")

PostgreSQL_src = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": DB_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_src"
)

postgres_df = PostgreSQL_src.toDF()
postgres_df.createOrReplaceTempView(DB_TABLE_NAME)

logger.info(f"Loaded PostgreSQL table: {DB_TABLE_NAME}")

# -------------------------------------------------------
#  DYNAMICALLY UPDATE GLUE TABLE COLUMN DEFINITIONS
# -------------------------------------------------------
def get_postgres_columns_and_types(spark, postgres_table_name):
    postgres_table_schema = spark.table(postgres_table_name).schema
    postgres_columns_with_types = {f.name: f.dataType.simpleString() for f in postgres_table_schema.fields}
    return postgres_columns_with_types

def dynamically_update_catalog_table(glue_spark, postgres_columns_with_types, GLUE_TABLE_PATH):
    logger.info("Synchronizing Iceberg table schema with PostgreSQL schema.")
    postgres_columns = postgres_columns_with_types.keys()

    glue_table_schema = glue_spark.table(GLUE_TABLE_PATH).schema
    glue_columns = [f.name for f in glue_table_schema.fields]

    # Identify new columns
    new_columns = set(postgres_columns) - set(glue_columns)
    for column_name in new_columns:
        col_type = postgres_columns_with_types[column_name]
        logger.info(f"Adding new column → {column_name}: {col_type}")

        glue_spark.sql(f"""
            ALTER TABLE {GLUE_TABLE_PATH}
            ADD COLUMN {column_name} {col_type}
        """)

    # Identify columns to drop
    drop_columns = set(glue_columns) - set(postgres_columns)
    for column_name in drop_columns:
        logger.info(f"Dropping column → {column_name}")
        glue_spark.sql(f"""
          ALTER TABLE {GLUE_TABLE_PATH}
          DROP COLUMN {column_name}
          """
                       )


postgres_columns_with_types = get_postgres_columns_and_types(spark, DB_TABLE_NAME)
columns = postgres_columns_with_types.keys()

dynamically_update_catalog_table(sql_spark, postgres_columns_with_types, GLUE_TABLE_PATH)

# -------------------------------------------------------
#      PERFORM ICEBERG MERGE INTO TABLE
# -------------------------------------------------------
try:
    logger.info("Performing MERGE INTO operation on Iceberg table.")

    column_list = ", ".join(columns)
    value_list = ", ".join([f"source.{col}" for col in columns])

    if "_rr" in CATALOG_TABLE_NAME:
        spark.sql(f"""
        MERGE INTO {GLUE_TABLE_PATH} AS target
        USING {DB_TABLE_NAME} AS source
        ON target.certificate_number = source.certificate_number
        WHEN NOT MATCHED THEN
            INSERT ({column_list}) VALUES ({value_list})
        """)
    else:
        spark.sql(f"""
        MERGE INTO {GLUE_TABLE_PATH} AS target
        USING {DB_TABLE_NAME} AS source
        ON target.certificate_number = source.certificate_number
        WHEN MATCHED
                    THEN UPDATE SET *
        WHEN NOT MATCHED THEN
            INSERT ({column_list}) VALUES ({value_list})
        """)
except Exception as e:
    logger.error(f"Job failed during Merge: {str(e)}")
    raise e
finally:
    logger.info("Resuming optimizers for background maintenance.")
    set_optimizers_status(glue, DATABASE_NAME, CATALOG_TABLE_NAME, optimizer_configurations.keys(), enabled=True)

    job.commit()
    logger.info("Glue job completed successfully.")
