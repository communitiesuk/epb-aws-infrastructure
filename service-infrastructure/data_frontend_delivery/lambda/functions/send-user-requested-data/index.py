import json
import logging
import os
import boto3
import sys
import subprocess
import time
from datetime import datetime

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
FRONTEND_URL = os.getenv("FRONTEND_URL")

def get_property_type_title(property_type):
    titles = {
        "domestic": "Domestic Energy Performance Certificates",
        "non_domestic": "Non-domestic Energy Performance Certificates",
        "display": "Display Energy Certificates"
    }
    return titles.get(property_type, "Energy Performance Certificates")

def extract_request_summary(sns_message):
    request_timestamp = sns_message.get("request_timestamp", time.time())
    dt_obj = datetime.fromtimestamp(request_timestamp)

    return {
        "time": dt_obj.strftime("%H:%M"),
        "date": dt_obj.strftime("%d %B %Y"),
        "property_type_title": get_property_type_title(sns_message.get("property_type")),
        "date_start": sns_message.get("date_start"),
        "date_end": sns_message.get("date_end"),
        "area": sns_message.get("area"),
        "include_recommendations": sns_message.get("include_recommendations", False),
        "efficiency_ratings": sns_message.get("efficiency_ratings"),
    }

def send_notify_email(email_address, urls, request_data):
    logger.info(f"Sending email to {email_address}: {urls}")

    if not NOTIFY_API_KEY or not NOTIFY_TEMPLATE_ID:
        logger.warning("NOTIFY_API_KEY or NOTIFY_TEMPLATE_ID environment variables not set. Cannot send email.")
        return

    notify_client = NotificationsAPIClient(NOTIFY_API_KEY)
    response = notify_client.send_email_notification(
        email_address=email_address,
        template_id=NOTIFY_TEMPLATE_ID,
        personalisation={
            "subject": "Your energy performance of buildings data request",
            "link": urls,
            "time": request_data["time"],
            "date": request_data["date"],
            "property_type_title": request_data["property_type_title"],
            "include_recommendations": "and recommendations" if request_data["include_recommendations"] else "",
            "date_start": request_data["date_start"],
            "date_end": request_data["date_end"],
            "area_value": request_data["area"],
            "efficiency_ratings": request_data["efficiency_ratings"],
            "show_ratings": bool(request_data["efficiency_ratings"])
        },
    )

def lambda_handler(event, context):
    logger.debug("EVENT INFO:")
    logger.debug(json.dumps(event))

    for record in event["Records"]:
        try:
            sns_message = json.loads(record["body"])
            request_data = extract_request_summary(sns_message)
            email_address = sns_message.get("email")
            s3_keys = sns_message.get("s3_keys")
            file_sizes = sns_message.get("file_sizes")

            urls = []
            file_sizes_in_mbs = []

            for file_name, s3_link in s3_keys.items():
                urls.append(f"[{file_name}.csv]({FRONTEND_URL}/download?file={s3_link})")

            for file_size in file_sizes:
                file_size_in_mb = round(file_size / (1024 * 1024), 2)
                file_sizes_in_mbs.append(f"{file_size_in_mb}")

            if len(urls) != len(file_sizes_in_mbs):
                return {
                    "statusCode": 400,
                    "body": json.dumps("Mismatched urls and file sizes."),
                }

            count = 0
            while count < len(urls):
                urls[count] = f"{urls[count]} (estimated size: {file_sizes_in_mbs[count]} MB)"
                count += 1

            if not email_address or not s3_keys:
                logger.error(f"Missing required fields (email, s3_keys) in SQS message: {sns_message}")
                continue

            logger.info(f"Processing request for email: {email_address}, S3 keys: {s3_keys}")

            # Send an email via Notify
            if s3_keys:
                send_notify_email(email_address, urls, request_data)
                logger.info(f"Successfully sent email to {email_address} with S3 key: {s3_keys}")
            else:
                logger.error(f"Failed to send the email via Notify")
        except Exception as e:
            logger.error(f"An error occurred: {e}")

    return {
        "statusCode": 200,
        "body": json.dumps("Processed SQS messages and attempted to send emails."),
    }
