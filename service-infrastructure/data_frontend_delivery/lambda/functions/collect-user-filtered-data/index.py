import json
import logging
import os
import boto3
import uuid
import time

"""
This function processes a data request from an SQS queue (triggered by SNS),
queries data from Athena based on the provided filters, and uploads the results to S3.
"""

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", logging.INFO))

ATHENA_DATABASE = os.getenv("ATHENA_DATABASE")
ATHENA_WORKGROUP = os.getenv("ATHENA_WORKGROUP")
OUTPUT_BUCKET = os.getenv("OUTPUT_BUCKET")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")

max_wait = 900


def table(filters):
    return filters["property_type"]


def rr_table(filters):
    return f"{filters["property_type"]}_rr"


def query_search_filter_setup(filters):
    clauses = []

    clauses.append(
        f"lodgement_date BETWEEN '{filters.pop("date_start")}' AND '{filters.pop("date_end")}'"
    )

    for key, value in filters.items():
        if value is not None:
            if key == "efficiency_ratings":
                if value:
                    quoted_values = [f"'{v}'" for v in value]
                    clauses.append(
                        f"\"current_energy_rating\" IN ({', '.join(quoted_values)})"
                    )
            elif key == "area":
                for sub_key, sub_value in value.items():
                    if sub_value:
                        if sub_key == "local-authority":
                            valid_authorities = [
                                f"'{v}'"
                                for v in sub_value
                                if v.lower() != "select all" and v != ""
                            ]
                            if valid_authorities:
                                clauses.append(
                                    f"\"local_authority_label\" IN ({', '.join(valid_authorities)})"
                                )
                        elif sub_key == "parliamentary-constituency":
                            valid_constituencies = [
                                f"'{v}'"
                                for v in sub_value
                                if v.lower() != "select all" and v != ""
                            ]
                            if valid_constituencies:
                                clauses.append(
                                    f"\"constituency_label\" IN ({', '.join(valid_constituencies)})"
                                )
                        elif sub_key == "postcode":
                            if sub_value:
                                clauses.append(f"{sub_key} = '{sub_value}'")
            else:
                continue

    return clauses


def construct_athena_query(filters):
    clauses = query_search_filter_setup(filters)
    base_query = f'SELECT * FROM "{ATHENA_DATABASE}"."{table(filters)}"'
    query = f"{base_query} WHERE {' AND '.join(clauses)}"
    logger.info(f"Athena Query: {query}")
    return query


def construct_domestic_rr_athena_query(filters):
    clauses = query_search_filter_setup(filters)
    base_rr_query = f'SELECT rr.certificate_number, \
                      improvement_item, \
                      improvement_id, \
                      indicative_cost, \
                      improvement_summary_text, \
                      improvement_descr_text \
                      FROM "{ATHENA_DATABASE}"."{rr_table(filters)}" rr \
                      JOIN "{ATHENA_DATABASE}"."{table(filters)}" m ON m.certificate_number=rr.certificate_number'

    query = f"{base_rr_query} WHERE {' AND '.join(clauses)}"
    logger.info(f"Athena Recommendations Query: {query}")
    return query


def construct_commercial_rr_athena_query(filters):
     clauses = query_search_filter_setup(filters)
     base_rr_query = f'SELECT rr.certificate_number, \
                       payback_type, \
                       recommendation_item, \
                       related_certificate_number, \
                       recommendation_code, \
                       recommendation \
                       FROM "{ATHENA_DATABASE}"."{rr_table(filters)}" rr \
                       JOIN "{ATHENA_DATABASE}"."{table(filters)}" m ON m.certificate_number=rr.related_certificate_number'

     query = f"{base_rr_query} WHERE {' AND '.join(clauses)}"
     logger.info(f"Athena Recommendations Query: {query}")
     return query


def execute_athena_query(query):
    athena_client = boto3.client("athena")
    try:
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={"Database": ATHENA_DATABASE},
            WorkGroup=ATHENA_WORKGROUP,
        )
        return response["QueryExecutionId"]
    except Exception as e:
        logger.error(f"Error executing Athena query: {e}")
        raise


def get_query_results_location(query_execution_id):
    athena_client = boto3.client("athena")
    try:
        response = athena_client.get_query_execution(
            QueryExecutionId=query_execution_id
        )
        status = response["QueryExecution"]["Status"]["State"]
        if status in ["QUEUED", "RUNNING"]:
            logger.info(
                f"Query {query_execution_id} is still running. Status: {status}"
            )
            return None
        elif status == "SUCCEEDED":
            return response["QueryExecution"]["ResultConfiguration"]["OutputLocation"]
        else:
            logger.error(f"Athena query {query_execution_id} failed. Status: {status}")
            return None
    except Exception as e:
        logger.error(f"Error getting Athena query execution status: {e}")
        return None


def copy_results_to_user_location(
    athena_results_location, user_email, query_execution_id, table
):
    bucket_name = OUTPUT_BUCKET
    source_prefix = "output/"
    destination_prefix = f"{table}/user-exports/{query_execution_id}/{uuid.uuid4()}/"
    copied_file_key = None

    try:
        s3_client = boto3.client("s3")
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix=source_prefix)
        if "Contents" not in response:
            logger.warning(f"No results found in: s3://{bucket_name}/{source_prefix}")
            return None

        for obj in response["Contents"]:
            if obj["Key"].endswith(os.path.basename(athena_results_location)):
                file_name = os.path.basename(obj["Key"])
                copy_source = {"Bucket": bucket_name, "Key": obj["Key"]}
                destination_key = f"{destination_prefix}{file_name}"
                s3_client.copy(copy_source, bucket_name, destination_key)
                copied_file_key = destination_key
                break  # Assuming only one relevant file (csv)

        if not copied_file_key:
            logger.warning(
                f"Could not find the expected Athena results file in: s3://{bucket_name}/{source_prefix}"
            )

        return copied_file_key

    except Exception as e:
        logger.error(f"Error copying results to user location: {e}")
        return None


def send_email_and_s3_key_to_sqs(user_email, s3_keys, file_sizes):
    try:
        sqs_client = boto3.client("sqs")

        message = {
            "email": user_email,
            "s3_keys": s3_keys,
            "bucket_name": OUTPUT_BUCKET,
            "file_sizes": file_sizes
        }
        logger.info(f"Sending user email and S3 key to SQS: {message}")
        response = sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message)
        )
        logger.info(
            f"Sent user email and S3 key to SQS. Message ID: {response['MessageId']}"
        )
    except Exception as e:
        logger.error(f"Error sending message to email notification SQS: {e}")


def get_result_location(query_execution_id):
    results_location = None
    wait_time = 0

    logger.info(f"Checking Athena query {query_execution_id}")
    poll_interval = 5  # Check every 5 seconds
    while not results_location and wait_time < max_wait:
        logger.info(
            f"Waiting for Athena query {query_execution_id}. Elapsed time: {wait_time}/{max_wait} seconds."
        )
        time.sleep(poll_interval)
        wait_time += poll_interval
        results_location = get_query_results_location(query_execution_id)

    return results_location


def build_certificates(filters):
    filters_copy = filters.copy()
    # Construct Athena query
    athena_query = construct_athena_query(filters_copy)

    # Execute Athena query
    query_execution_id = execute_athena_query(athena_query)
    if not query_execution_id:
        return log_error(
            "Failed to execute Athena query", "Failed to execute Athena query"
        )

    logger.info(f"Query Execution ID: {query_execution_id}")

    return query_execution_id


def build_recommendations(filters):
    filters_copy = filters.copy()

    # Construct Athena rr query
    if table(filters) == "domestic":
        athena_rr_query = construct_domestic_rr_athena_query(filters_copy)
    else:
        athena_rr_query = construct_commercial_rr_athena_query(filters_copy)

    # Execute Athena rr query
    query_execution_rr_id = execute_athena_query(athena_rr_query)
    if not query_execution_rr_id:
        return log_error(
            "Failed to execute Athena Recommendations query",
            "Failed to execute Athena Recommendations query",
        )

    logger.info(f"Query Execution Recommendations ID: {query_execution_rr_id}")

    return query_execution_rr_id


def log_error(error_message, body):
    logger.error(error_message)
    return {"statusCode": 500, "body": json.dumps(body)}


def get_s3_file_size(s3_key):
    s3 = boto3.client('s3')
    response = s3.head_object(Bucket=OUTPUT_BUCKET, Key=s3_key)
    size_in_bytes = response['ContentLength']
    return size_in_bytes


def get_s3_file_sizes(keys):
    file_sizes = []
    for key, value in keys.items():
        file_sizes.append(get_s3_file_size(value))
    return file_sizes


def lambda_handler(event, context):
    logger.info("EVENT INFO:")
    logger.info(json.dumps(event))

    for record in event["Records"]:
        sns_message = json.loads(record["body"])
        filters = json.loads(sns_message["Message"])
        user_email = filters.pop("email_address")
        table_name = table(filters)
        rr_table_name = rr_table(filters)
        s3_keys = {}

        query_execution_id = build_certificates(filters)

        if filters["include_recommendations"]:
            query_execution_rr_id = build_recommendations(filters)

        # Wait for Athena query to complete and get results location
        results_location = get_result_location(query_execution_id)
        if not results_location:
            return log_error(
                f"Athena query {query_execution_id} did not complete within the allowed time ({max_wait} seconds).",
                f"Athena query did not complete in time ({max_wait} seconds).",
            )

        logger.info(f"Athena Results Location: {results_location}")

        s3_key = copy_results_to_user_location(
            results_location, user_email, query_execution_id, table_name
        )

        if s3_key:
            s3_keys["certificates"] = s3_key
        else:
            return log_error(
                f"Failed to generate S3 key for user with email {user_email}",
                "Failed to generate the S3 key.",
            )

        if filters["include_recommendations"]:
            # Wait for Athena query to complete and get results location
            results_rr_location = get_result_location(query_execution_rr_id)
            if not results_rr_location:
                return log_error(
                    f"Athena Recommendations query {query_execution_rr_id} did not complete within the allowed time ({max_wait} seconds).",
                    f"Athena query did not complete in time ({max_wait} seconds).",
                )

            logger.info(
                f"Athena Results Recommendations Location: {results_rr_location}"
            )

            s3_rr_key = copy_results_to_user_location(
                results_rr_location, user_email, query_execution_rr_id, rr_table_name
            )

            if s3_rr_key:
                s3_keys["recommendations"] = s3_rr_key
            else:
                return log_error(
                    f"Failed to generate S3 Recommendations key for user with email {user_email}",
                    "Failed to generate the S3 Recommendations key.",
                )

        file_sizes = get_s3_file_sizes(s3_keys)
        # Get and put email and results location to the SQS queue
        send_email_and_s3_key_to_sqs(user_email, s3_keys, file_sizes)
