import json
from handle_filter_properties_request import lambda_handler  # Import your Lambda function

with open("example_sqs_data.json", "r") as f:
    sns_message = json.load(f)

# Wrap it in the SQS Records structure
event = {
    "Records": [
        {"body": json.dumps(sns_message)}
    ]
}

# Call the Lambda function manually
response = lambda_handler(event, None)

print("Lambda Response:", response)
