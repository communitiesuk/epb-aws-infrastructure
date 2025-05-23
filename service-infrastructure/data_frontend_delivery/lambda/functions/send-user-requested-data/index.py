import json
import logging
import os
import boto3
import sys
import subprocess

subprocess.call("pip install notifications-python-client -t /tmp/ --no-cache-dir".split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
sys.path.insert(1, "/tmp/")

from notifications_python_client.notifications import NotificationsAPIClient

"""
This function processes a data object with email address, S3 key and bucket name from an SQS queue and sends an email to the user containing this link.
"""

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", logging.INFO))

NOTIFY_API_KEY = os.getenv("NOTIFY_DATA_API_KEY")
NOTIFY_TEMPLATE_ID = os.getenv("NOTIFY_DATA_DOWNLOAD_TEMPLATE_ID")
NOTIFY_DATA_EMAIL_RECIPIENT = os.getenv("NOTIFY_DATA_EMAIL_RECIPIENT")
FRONTEND_URL = os.getenv("FRONTEND_URL")

def send_notify_email(email_address, urls):
    logger.info(f"Sending email to {email_address}: {urls}")

    if not NOTIFY_API_KEY or not NOTIFY_TEMPLATE_ID:
        logger.warning("NOTIFY_API_KEY or NOTIFY_TEMPLATE_ID environment variables not set. Cannot send email.")
        return

    notify_client = NotificationsAPIClient(NOTIFY_API_KEY)
    response = notify_client.send_email_notification(
        email_address=email_address,
        template_id=NOTIFY_TEMPLATE_ID,
        personalisation={
            "subject": "Your data download link",
            "link": urls
        },
    )

def lambda_handler(event, context):
    logger.debug("EVENT INFO:")
    logger.debug(json.dumps(event))

    for record in event["Records"]:
        try:
            sns_message = json.loads(record["body"])
            email_address = NOTIFY_DATA_EMAIL_RECIPIENT
            s3_keys = sns_message.get("s3_keys")
            urls = []
            
            for file_name, s3_link in s3_keys.items():
                urls.append(f"[{file_name}.csv]({FRONTEND_URL}/download?file={s3_link})")

            if not email_address or not s3_keys:
                logger.error(f"Missing required fields (email, s3_keys) in SQS message: {sns_message}")
                continue

            logger.info(f"Processing request for email: {email_address}, S3 keys: {s3_keys}")

            # Send an email via Notify
            if s3_keys:
                send_notify_email(email_address, urls)
                logger.info(f"Successfully sent email to {email_address} with S3 key: {s3_keys}")
            else:
                logger.error(f"Failed to send the email via Notify")
        except Exception as e:
            logger.error(f"An error occurred: {e}")

    return {
        "statusCode": 200,
        "body": json.dumps("Processed SQS messages and attempted to send emails."),
    }
