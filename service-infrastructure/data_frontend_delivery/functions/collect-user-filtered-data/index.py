import json
import logging
import os
import boto3

"""
This function processes a data request from an SQS queue (triggered by SNS),
queries data from Athena based on the provided filters, and uploads the results to S3.
"""

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", logging.INFO))

ATHENA_DATABASE = os.getenv("ATHENA_DATABASE")
ATHENA_TABLE = os.getenv("ATHENA_TABLE")
ATHENA_WORKGROUP = os.getenv("ATHENA_WORKGROUP")


def construct_athena_query(filters):
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
                    if (
                        sub_value
                        and sub_value.lower() != "select all"
                        and sub_value != ""
                    ):
                        if sub_key == "local-authority":
                            clauses.append(f"\"local_authority_label\" = '{sub_value}'")
                        elif sub_key == "parliamentary-constituency":
                            clauses.append(f"\"constituency_label\" = '{sub_value}'")
                        else:
                            clauses.append(f"{sub_key} = '{sub_value}'")
            else:
                continue

    base_query = f'SELECT * FROM "{ATHENA_DATABASE}"."{ATHENA_TABLE}"'
    if clauses:
        return f"{base_query} WHERE {' AND '.join(clauses)}"
    return base_query


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


def lambda_handler(event, context):
    logger.debug("EVENT INFO:")
    logger.debug(json.dumps(event))

    for record in event["Records"]:
        sns_message = json.loads(record["body"])
        filters = json.loads(sns_message["Message"])

        # Construct Athena query
        athena_query = construct_athena_query(filters)
        logger.info(f"Athena Query: {athena_query}")

        # Execute Athena query
        query_execution_id = execute_athena_query(athena_query)
        if not query_execution_id:
            logger.error("Failed to execute Athena query")
            return {
                "statusCode": 500,
                "body": json.dumps("Failed to execute Athena query"),
            }
        logger.info(f"Query Execution ID: {query_execution_id}")
