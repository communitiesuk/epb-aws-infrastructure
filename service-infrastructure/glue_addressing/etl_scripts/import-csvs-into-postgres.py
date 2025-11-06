import boto3
import json
import sys
import psycopg2

from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import lit
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
logger = glueContext.get_logger()
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
DB_IMPORT_VERSION_KEY = "database.version"
NGD_IMPORT_VERSION_KEY = "ngd.version"

s3_client = boto3.client("s3")

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

def get_table_columns(conn_info, table_name):
    conn = psycopg2.connect(
        dbname=conn_info["database"],
        user=conn_info["user"],
        password=conn_info["password"],
        host=conn_info["host"],
        port=conn_info["port"]
    )
    cur = conn.cursor()
    cur.execute("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = %s
        ORDER BY ordinal_position
    """, (table_name,))
    columns = [row[0] for row in cur.fetchall()]
    cur.close()
    conn.close()
    return columns

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
        DROP TABLE {DB_TABLE_NAME_STAGING};
        CREATE TABLE {DB_TABLE_NAME_STAGING} (LIKE {DB_TABLE_NAME} INCLUDING ALL);
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

def list_csv_files(bucket, prefix):
    objects = s3_client.list_objects_v2(Bucket=bucket, Prefix=prefix)
    files = [obj['Key'] for obj in objects.get('Contents', []) if obj['Key'].endswith(".csv")]
    return files

ngd_version_s3_obj = s3_client.get_object(Bucket=S3_BUCKET, Key=NGD_IMPORT_VERSION_KEY)
ngd_data_version = ngd_version_s3_obj['Body'].read().decode().strip()

logger.warn(f"Importing NGD version: {ngd_data_version}. Proceeding with ETL.")

conn_info = get_connection_info()
create_staging_table(conn_info)

file_keys = list_csv_files(S3_BUCKET, "ngd/")
logger.warn(f"CSV files found: {', '.join(file_keys)}")

columns_to_keep = get_table_columns(conn_info, DB_TABLE_NAME)

for file_key in file_keys:

    # Script generated for node Amazon S3
    AmazonS3_node1757327398684 = glueContext.create_dynamic_frame.from_options(format_options={"quoteChar": "\"", "withHeader": True, "separator": ",", "optimizePerformance": False}, connection_type="s3", format="csv", connection_options={"paths": [f"s3://{S3_BUCKET}/{file_key}"], "recurse": True}, transformation_ctx="AmazonS3_node1757327398684")


    df = AmazonS3_node1757327398684.toDF()
    df = df.withColumn("source", lit(file_key))
    df = df.select(*columns_to_keep)

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

logger.warn(f"NGD data version imported successfully: {ngd_data_version}.")

s3_client.put_object(
    Bucket=S3_BUCKET,
    Key=DB_IMPORT_VERSION_KEY,
    Body=ngd_data_version.encode("utf-8")
)

job.commit()