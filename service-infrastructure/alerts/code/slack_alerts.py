import urllib3
import json
import os
import logging

slack_hook = os.getenv("SLACK_WEBHOOK_URL")
environment = os.getenv("ENVIRONMENT")
http = urllib3.PoolManager()

def lambda_handler(event, context):
    logging.debug(event)
    sns_message = json.loads(event["Records"][0]["Sns"]["Message"])
    
    alarm = get_alarm_attributes(sns_message)
    logging.debug(sns_message)

    msg = str()

    logging.debug(msg)
    if alarm['previous_state'] == "INSUFFICIENT_DATA" and alarm['state'] == 'OK':
        msg = register_alarm(alarm)
    elif alarm['previous_state'] == 'OK' and alarm['state'] == 'ALARM':
        msg = activate_alarm(alarm)
    elif alarm['previous_state'] == 'ALARM' and alarm['state'] == 'OK':
        msg = resolve_alarm(alarm)

    encoded_msg = json.dumps(msg).encode("utf-8")
    resp = http.request("POST", slack_hook, body=encoded_msg)

    return {
            "message": msg,
            "status_code": resp.status,
            "response": resp.data,
        }

def get_alarm_attributes(sns_message):
    alarm = {
        'name': sns_message['AlarmName'],
        'description': sns_message['AlarmDescription'],
        'reason': sns_message['NewStateReason'],
        'region': sns_message['Region'],
        'resource_name': " - ".join([d['value'] for d in sns_message['Trigger']['Dimensions']]),
        'state': sns_message['NewStateValue'],
        'previous_state': sns_message['OldStateValue'],
        'environment': environment,
    }

    return alarm


def register_alarm(alarm):
    return {
        "type": "home",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f":new: {alarm['name']} alarm was registered in {alarm['environment']}"
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Service: *{alarm['resource_name']}*"
                    }
                ]
            }
        ]
    }


def activate_alarm(alarm):
    return {
        "type": "home",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f":red_circle: Alarm in {alarm['environment']}: {alarm['description']}",
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"_{alarm['reason']}_"
                },
                "block_id": "text1"
            },
            {
                "type": "divider"
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Service: *{alarm['resource_name']}*"
                    }
                ]
            }
        ]
    }


def resolve_alarm(alarm):
    return {
        "type": "home",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f":large_green_circle: Resolved in {alarm['environment']}: {alarm['description']}",
                }
            },
            {
                "type": "divider"
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"_{alarm['reason']}_"
                },
                "block_id": "text1"
            },
            {
                "type": "divider"
            },
            {
                "type": "context",
                "elements": [
                    {
                        "type": "mrkdwn",
                        "text": f"Service: *{alarm['resource_name']}*"
                    }
                ]
            }
        ]
    }
