import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'S3_BUCKET', 'CONNECTION_NAME', 'DB_TABLE_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

DATABASE_NAME = args['DATABASE_NAME']
S3_BUCKET = args['S3_BUCKET']
CONNECTION_NAME = args['CONNECTION_NAME']
DB_TABLE_NAME = args['DB_TABLE_NAME']


# Script generated for node Amazon S3
AmazonS3_node1757327398684 = glueContext.create_dynamic_frame.from_options(format_options={"quoteChar": "\"", "withHeader": True, "separator": ",", "optimizePerformance": False}, connection_type="s3", format="csv", connection_options={"paths": ["s3://epb-intg-ngd-data/ngd/"], "recurse": True}, transformation_ctx="AmazonS3_node1757327398684")

df = AmazonS3_node1757327398684.toDF()
schema = df.schema

# Map Spark types -> Postgres types
type_mapping = {
    "StringType": "TEXT",
    "IntegerType": "INTEGER",
    "LongType": "BIGINT",
    "DoubleType": "DOUBLE PRECISION",
    "FloatType": "REAL",
    "BooleanType": "BOOLEAN",
    "TimestampType": "TIMESTAMP",
    "DateType": "DATE"
}

# Temporary Build CREATE TABLE DDL
columns = []
for field in schema.fields:
    col_type = type_mapping.get(field.dataType.simpleString().capitalize() + "Type", "TEXT")
    columns.append(f"{field.name} {col_type}")

ddl = f"CREATE TABLE IF NOT EXISTS {DB_TABLE_NAME} (\n  {', '.join(columns)}\n);"

print("DDL to run:\n", ddl)

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=AmazonS3_node1757327398684,
    catalog_connection=CONNECTION_NAME,
    connection_options={
        "dbtable": DB_TABLE_NAME,     # target table in Postgres
        "database": DATABASE_NAME,
        "preactions": ddl
    },
    transformation_ctx="PostgresSink"
)

job.commit()