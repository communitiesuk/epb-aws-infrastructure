import json

def lambda_handler(event, context):
    for record in event["Records"]:
        sns_message = json.loads(record["body"])  # SQS body contains SNS payload
        actual_message = json.loads(sns_message["Message"])  # Extract actual message

        print("Extracted JSON Payload:", actual_message)

        property_type = actual_message["property_type"]
        date_start = actual_message["date_start"]
        date_end = actual_message["date_end"]
        area = actual_message["area"]
        efficiency_ratings = actual_message["efficiency_ratings"]
        include_recommendations = actual_message["include_recommendations"]
        email_address = actual_message["email_address"]

        print(email_address)
