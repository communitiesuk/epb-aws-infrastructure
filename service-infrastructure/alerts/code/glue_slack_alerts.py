import urllib3
import urllib.parse
import json
import os
import logging

slack_hook = os.getenv("SLACK_WEBHOOK_URL")
environment = os.getenv("ENVIRONMENT")
http = urllib3.PoolManager()

def lambda_handler(event, context):
    logging.debug(event)
    sns_message = json.loads(event["Records"][0]["Sns"]["Message"])

    event = get_event_attributes(sns_message)
    logging.debug(sns_message)

    msg = str()

    logging.debug(msg)
    if event['source'] == "aws.glue" and event['state'] in ("FAILED", "TIMEOUT"):
        msg = send_slack_alert(event)

    encoded_msg = json.dumps(msg).encode("utf-8")
    resp = http.request("POST", slack_hook, body=encoded_msg)

    return {
            "message": msg,
            "status_code": resp.status,
            "response": resp.data,
        }

def get_event_attributes(sns_message):
    detail = sns_message["detail"]

    event = {
        'source': sns_message['source'],
        'region': sns_message['region'],
        'environment': environment,
        'job_name': detail.get("jobName", "unknown"),
        'job_run_id': detail.get("jobRunId", "unknown"),
        'state': detail.get("state", "UNKNOWN")
    }

    return event


def send_slack_alert(event):
    encoded_job_name = urllib.parse.quote(event['job_name'])
    job_url = f"https://{event['region']}.console.aws.amazon.com/gluestudio/home?region={event['region']}#/job/{encoded_job_name}/run/{event['job_run_id']}"

    return {
        "type": "home",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f":red_circle: Glue job failed in {event['environment']}: {event['job_name']}",
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Job Run ID:* {event['job_run_id']}\n*State:* {event['state']}\n*Environment:* {event['environment']}\n*Console Link:* <{job_url}|Open in AWS Console>"
                }
            }
        ]
    }

