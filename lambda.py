"""
Receives SNS notifications with CloudWatch Metric Alarm events in them.
Sends a message to a Slack Webhook URL with information about the event.

"""

import json
import logging
import os

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


logger = logging.getLogger()
logger.setLevel(logging.INFO)

SLACK_URL = os.environ['SLACK_URL']

STATES = {
    'OK': {
        'username': os.environ['OK_USER_NAME'],
        'icon_emoji': os.environ['OK_USER_EMOJI'],
        'status_emoji': os.environ['OK_STATUS_EMOJI'],
    },
    'ALARM': {
        'username': os.environ['ALARM_USER_NAME'],
        'icon_emoji': os.environ['ALARM_USER_EMOJI'],
        'status_emoji': os.environ['ALARM_STATUS_EMOJI'],
    },
    'INSUFFICIENT_DATA': {
        'username': os.environ['INSUFFICIENT_DATA_USER_NAME'] or os.environ['ALARM_USER_NAME'],
        'icon_emoji': os.environ['INSUFFICIENT_DATA_USER_EMOJI'] or os.environ['ALARM_USER_EMOJI'],
        'status_emoji': os.environ['INSUFFICIENT_DATA_STATUS_EMOJI'] or os.environ['ALARM_STATUS_EMOJI'],
    },
}


def lambda_handler(event, context):
    logger.info('Event: ' + str(event))

    data = json.loads(event['Records'][0]['Sns']['Message'])

    state_value = data['NewStateValue']
    description = data['AlarmDescription']

    state = STATES[state_value]

    data = {
        'text': description,
        'attachments': [{
            'text': '{status_emoji}  {state}'.format(
                status_emoji=state['status_emoji'],
                state=state_value,
            )
        }],
    }

    if state['username']:
        data['username'] = state['username']

    if state['icon_emoji']:
        data['icon_emoji'] = state['icon_emoji']

    post_data = json.dumps(data).encode('utf-8')

    req = Request(SLACK_URL, post_data)
    try:
        response = urlopen(req)
        response.read()
        logger.info('Message posted to %s', SLACK_URL)
    except HTTPError as e:
        logger.error('Request failed: %d %s', e.code, e.reason)
    except URLError as e:
        logger.error('Server connection failed: %s', e.reason)
