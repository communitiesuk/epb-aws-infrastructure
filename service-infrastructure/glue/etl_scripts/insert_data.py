import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'CONNECTION_NAME', 'DATABASE_NAME', 'CATALOG_TABLE_NAME', 'SOURCE_VIEW_TABLE_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

DATABASE_NAME = args['DATABASE_NAME']
CONNECTION_NAME = args['CONNECTION_NAME']
CATALOG_TABLE_NAME =  args['CATALOG_TABLE_NAME']
SOURCE_VIEW_TABLE_NAME = args['SOURCE_VIEW_TABLE_NAME']

# Script generated for node PostgreSQL
PostgreSQL_node1749737305383 = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": SOURCE_VIEW_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_node1749737305383"
)
# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1749633070809_df = glueContext.create_data_frame.from_catalog(database=DATABASE_NAME, table_name=CATALOG_TABLE_NAME)

postgres_df = PostgreSQL_node1749737305383.toDF()
postgres_df.createOrReplaceTempView(SOURCE_VIEW_TABLE_NAME)

columns = [f.name for f in spark.table(SOURCE_VIEW_TABLE_NAME).schema.fields]
column_list = ", ".join(columns)
value_list = ", ".join([f"source.{col}" for col in columns])

spark.sql(f"""
MERGE INTO glue_catalog.{DATABASE_NAME}.{CATALOG_TABLE_NAME} AS target
USING {SOURCE_VIEW_TABLE_NAME} AS source 
ON target.certificate_number = source.certificate_number 
WHEN MATCHED 
            THEN UPDATE SET *
WHEN NOT MATCHED THEN 
    INSERT ({column_list}) VALUES ({value_list})
""")

job.commit()