import boto3
import json
import sys
import psycopg2

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(
    sys.argv,
    [
        'JOB_NAME',
        'DATABASE_NAME',
        'DATABASE_CREDS_SECRET',
        'SECRETS_REGION',
        'DATABASE_HOST',
        'S3_BUCKET',
        'CONNECTION_NAME',
        'DB_TABLE_NAME',
        'DB_TABLE_NAME_STAGING'
    ]
)

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

DATABASE_NAME = args['DATABASE_NAME']
DATABASE_CREDS_SECRET = args['DATABASE_CREDS_SECRET']
SECRETS_REGION = args['SECRETS_REGION']
DATABASE_HOST = args['DATABASE_HOST']
S3_BUCKET = args['S3_BUCKET']
CONNECTION_NAME = args['CONNECTION_NAME']
DB_TABLE_NAME = args['DB_TABLE_NAME']
DB_TABLE_NAME_STAGING = args['DB_TABLE_NAME_STAGING']

def get_connection_info():
    client = boto3.client("secretsmanager", region_name=SECRETS_REGION)
    response = client.get_secret_value(SecretId=DATABASE_CREDS_SECRET)
    secret = json.loads(response["SecretString"])

    return {
        "host": DATABASE_HOST,
        "port": "5432",
        "database": DATABASE_NAME,
        "user": secret["username"],
        "password": secret["password"]
    }

def create_staging_table(conn_info):
    conn = psycopg2.connect(
        dbname=conn_info["database"],
        user=conn_info["user"],
        password=conn_info["password"],
        host=conn_info["host"],
        port=conn_info["port"]
    )
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute(f"""
        CREATE TABLE IF NOT EXISTS {DB_TABLE_NAME_STAGING} (LIKE {DB_TABLE_NAME} INCLUDING ALL);
        TRUNCATE {DB_TABLE_NAME_STAGING};
    """)

    cur.close()
    conn.close()

def swap_tables(conn_info):
    conn = psycopg2.connect(
        dbname=conn_info["database"],
        user=conn_info["user"],
        password=conn_info["password"],
        host=conn_info["host"],
        port=conn_info["port"]
    )
    conn.autocommit = True
    cur = conn.cursor()

    cur.execute(f"""
        DROP TABLE IF EXISTS {DB_TABLE_NAME}_old;
        ALTER TABLE IF EXISTS {DB_TABLE_NAME} RENAME TO {DB_TABLE_NAME}_old;
        ALTER TABLE {DB_TABLE_NAME_STAGING} RENAME TO {DB_TABLE_NAME};
        ALTER TABLE {DB_TABLE_NAME}_old RENAME TO {DB_TABLE_NAME_STAGING};
        TRUNCATE {DB_TABLE_NAME_STAGING};
    """)

    cur.close()
    conn.close()


conn_info = get_connection_info()
create_staging_table(conn_info)

# Script generated for node Amazon S3
AmazonS3_node1757327398684 = glueContext.create_dynamic_frame.from_options(format_options={"quoteChar": "\"", "withHeader": True, "separator": ",", "optimizePerformance": False}, connection_type="s3", format="csv", connection_options={"paths": ["s3://epb-intg-ngd-data/ngd/"], "recurse": True}, transformation_ctx="AmazonS3_node1757327398684")

columns_to_keep = [
    "uprn",
    "parentuprn",
    "organisationname",
    "poboxnumber",
    "subname",
    "name",
    "number",
    "streetname",
    "locality",
    "townname",
    "postcode",
    "fulladdress",
    "country",
    "classificationcode"
]

df = AmazonS3_node1757327398684.toDF().select(*columns_to_keep)
schema = df.schema

filtered_frame = DynamicFrame.fromDF(df, glueContext, "filtered_frame")

glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=filtered_frame,
    catalog_connection=CONNECTION_NAME,
    connection_options={
        "dbtable": DB_TABLE_NAME_STAGING,
        "database": DATABASE_NAME
    },
    transformation_ctx="PostgresSink"
)

swap_tables(conn_info)

job.commit()