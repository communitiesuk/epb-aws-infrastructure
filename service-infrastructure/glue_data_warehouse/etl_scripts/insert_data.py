import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql import SparkSession

# -------------------------------------------------------
#               PARSE JOB ARGUMENTS
# -------------------------------------------------------
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'CONNECTION_NAME', 'DATABASE_NAME', 'CATALOG_TABLE_NAME', 'SOURCE_VIEW_TABLE_NAME', 'S3_BUCKET'])

DATABASE_NAME = args['DATABASE_NAME']
CONNECTION_NAME = args['CONNECTION_NAME']
CATALOG_TABLE_NAME =  args['CATALOG_TABLE_NAME']
S3_BUCKET = args['S3_BUCKET']
SOURCE_VIEW_TABLE_NAME = args['SOURCE_VIEW_TABLE_NAME']

S3_PATH=f"s3://{S3_BUCKET}/{CATALOG_TABLE_NAME}/"
GLUE_TABLE_PATH = f"glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME}"

# -------------------------------------------------------
#               SETUP SPARK + GLUE CONTEXT
# -------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
logger = glueContext.get_logger()
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

logger.info("Glue job initialized successfully.")

# -------------------------------------------------------
#        INITIALIZE ICEBERG CATALOG IF NECESSARY
# -------------------------------------------------------
sql_spark = (
    SparkSession.builder
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
    .config("spark.sql.catalog.glue_catalog.warehouse", S3_PATH)
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
""")

logger.info("Iceberg table ensured.")

# -------------------------------------------------------
#       EXTRACT DATA FROM POSTGRESQL SOURCE
# -------------------------------------------------------
logger.info("Reading source table from PostgreSQL.")

PostgreSQL_src = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": SOURCE_VIEW_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_src"
)

postgres_df = PostgreSQL_src.toDF()
postgres_df.createOrReplaceTempView(SOURCE_VIEW_TABLE_NAME)

logger.info(f"Loaded PostgreSQL table: {SOURCE_VIEW_TABLE_NAME}")

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
    logger.info(f"postgres_columns: {postgres_columns}")


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

postgres_columns_with_types = get_postgres_columns_and_types(spark, SOURCE_VIEW_TABLE_NAME)
logger.info(f"postgres_columns_with_types: {postgres_columns_with_types}")

columns = postgres_columns_with_types.keys()
logger.info(f"columns: {columns}")

dynamically_update_catalog_table(sql_spark, postgres_columns_with_types, GLUE_TABLE_PATH)

# -------------------------------------------------------
#      PERFORM ICEBERG MERGE INTO TABLE
# -------------------------------------------------------
logger.info("Performing MERGE INTO operation on Iceberg table.")

column_list = ", ".join(columns)
value_list = ", ".join([f"source.{col}" for col in columns])

if "_rr" in CATALOG_TABLE_NAME:
    spark.sql(f"""
    MERGE INTO {GLUE_TABLE_PATH} AS target
    USING {SOURCE_VIEW_TABLE_NAME} AS source
    ON target.certificate_number = source.certificate_number 
    WHEN NOT MATCHED THEN
        INSERT ({column_list}) VALUES ({value_list})
    """)
else:
    spark.sql(f"""
    MERGE INTO {GLUE_TABLE_PATH} AS target
    USING {SOURCE_VIEW_TABLE_NAME} AS source
    ON target.certificate_number = source.certificate_number 
    WHEN MATCHED
                THEN UPDATE SET *
    WHEN NOT MATCHED THEN
        INSERT ({column_list}) VALUES ({value_list})
    """)

job.commit()
logger.info("Glue job completed successfully.")