import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'CONNECTION_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

DATABASE_NAME =  args['DATABASE_NAME']
CONNECTION_NAME = args['CONNECTION_NAME']
CATALOG_TABLE_NAME = ['domestic', 'domestic_rr', 'non_domestic', 'non_domestic_rr', 'json_documents', 'display', 'display_rr']
SOURCE_TABLE_NAME = 'audit_logs'

# Script generated for node PostgreSQL
PostgreSQL_node1749632960903 = glueContext.create_dynamic_frame.from_options(
    connection_type = "postgresql",
    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": SOURCE_TABLE_NAME,
        "connectionName": CONNECTION_NAME,
    },
    transformation_ctx = "PostgreSQL_node1749632960903"
)

postgres_df = PostgreSQL_node1749632960903.toDF()
postgres_df.createOrReplaceTempView(SOURCE_TABLE_NAME)

for table_name in CATALOG_TABLE_NAME:
    spark.sql(f"""
        DELETE FROM glue_catalog.{DATABASE_NAME}.{table_name}
        WHERE certificate_number IN (
            SELECT assessment_id FROM {SOURCE_TABLE_NAME}
            WHERE event_type IN ('cancelled', 'opt_out')
        )
    """)

job.commit()