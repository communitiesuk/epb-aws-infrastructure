import io
import sys
import boto3
import json
import requests
import stream_unzip

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from boto3.s3.transfer import TransferConfig
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql import SparkSession

class S3MultipartWriter(io.RawIOBase):
    def __init__(self, s3_client, bucket, key, chunk_size=50 * 1024 * 1024):
        self.s3_client = s3_client
        self.bucket = bucket
        self.key = key
        self.chunk_size = chunk_size
        self.parts = []
        self.part_number = 1
        self.buffer = bytearray()
        resp = s3_client.create_multipart_upload(Bucket=bucket, Key=key)
        self.upload_id = resp["UploadId"]

    def write(self, b):
        self.buffer.extend(b)
        while len(self.buffer) >= self.chunk_size:
            self._upload_part(self.buffer[:self.chunk_size])
            del self.buffer[:self.chunk_size]
        return len(b)

    def _upload_part(self, data):
        part = self.s3_client.upload_part(
            Bucket=self.bucket,
            Key=self.key,
            PartNumber=self.part_number,
            UploadId=self.upload_id,
            Body=bytes(data),
        )
        self.parts.append({"PartNumber": self.part_number, "ETag": part["ETag"]})
        self.part_number += 1

    def close(self):
        if self.buffer:
            self._upload_part(self.buffer)
        self.s3_client.complete_multipart_upload(
            Bucket=self.bucket,
            Key=self.key,
            UploadId=self.upload_id,
            MultipartUpload={"Parts": self.parts},
        )
        super().close()

    def abort(self):
        self.s3_client.abort_multipart_upload(
            Bucket=self.bucket, Key=self.key, UploadId=self.upload_id
        )

    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is None:
            self.close()
        else:
            self.abort()

def get_download_urls_from_data_package(api_key, data_package_id):
    data_package_url = f"https://api.os.uk/downloads/v1/dataPackages/{data_package_id}?key={api_key}"
    data_package_response = requests.get(data_package_url)
    data_package = json.loads(data_package_response.text)

    created_on_dates = [version["createdOn"] for version in data_package["versions"]]
    latest_created_on_date = max(created_on_dates)

    urls = []
    for version in data_package["versions"]:
        if version["createdOn"] != latest_created_on_date:
            continue

        data_package_version_response = requests.get(version["url"])
        data_package_version = json.loads(data_package_version_response.text)

        for file in data_package_version["downloads"]:
            if file["fileName"].endswith(".zip"):
                urls.append(file["url"])
    return urls

required_args = ["JOB_NAME", "S3_BUCKET", "OS_API_KEY", "DATA_PACKAGE_ID"]


# Get job arguments
args = getResolvedOptions(sys.argv, required_args)

sc = SparkContext()
glueContext = GlueContext(sc)
logger = glueContext.get_logger()
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Configuration
S3_BUCKET = args["S3_BUCKET"]
OS_API_KEY = args["OS_API_KEY"]
DATA_PACKAGE_ID = args["DATA_PACKAGE_ID"]

s3_client = boto3.client("s3")


logger.warn(f'Starting ZIP file stream to S3"')


urls = get_download_urls_from_data_package(OS_API_KEY, DATA_PACKAGE_ID)

chunk_size_bytes = 1024 * 1024 * 50
zip_chunk_size_bytes = 65536

for url in urls:
    logger.warn(f"Streaming Zip file: {url}" )
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        for file_name, file_size, file_chunks in stream_unzip.stream_unzip(r.iter_content(zip_chunk_size_bytes)):
            name = file_name.decode("utf-8")
    
            if not name.endswith("_builtaddress.csv"):
                for chunk in file_chunks:
                    pass
                continue
    
            logger.warn(f"Found CSV: {name}, size={file_size} bytes")
            with S3MultipartWriter(s3_client, S3_BUCKET, "ngd/" + name, chunk_size=chunk_size_bytes) as mpw:
                logger.warn(f'S3MultipartWriter created"')
    
                for chunk in file_chunks:
                    mpw.write(chunk)

job.commit()