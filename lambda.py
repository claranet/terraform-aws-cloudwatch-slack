"""
Receives SNS notifications with CloudWatch Metric Alarm events in them.
Sends a message to a Slack Webhook URL with information about the event.

"""

import boto3
import json
import logging
import os

from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


cloudwatch = boto3.client('cloudwatch')

if os.environ['ACCOUNT_APPEND'].lower() == 'true':
  account_id = boto3.client('sts').get_caller_identity()['Account']

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


def is_first_state_update(alarm_name):
    """
    Checks if this is the very first state update for the alarm. CloudWatch
    creates alarms in the INSUFFICIENT_DATA state. They usually immediately
    change to another state (OK or FAILED) according to the metrics.

    """

    # Check the alarm history for 2 state updates.
    response = cloudwatch.describe_alarm_history(
        AlarmName=alarm_name,
        HistoryItemType='StateUpdate',
        MaxRecords=2,
    )
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        # Log errors rather than raising exceptions, in the hope that it can
        # still notify the Slack channel about the alarm.
        logger.error('Could not check alarm history: %s', response)
        return False
    else:
        # If 2 state updates weren't returned, then this was the first one.
        state_update_count = len(response['AlarmHistoryItems'])
        return state_update_count != 2


def lambda_handler(event, context):
    logger.info('Event: ' + str(event))

    data = json.loads(event['Records'][0]['Sns']['Message'])

    state_value = data['NewStateValue']

    if state_value == 'OK':
        if data['OldStateValue'] == 'INSUFFICIENT_DATA':
            if is_first_state_update(data['AlarmName']):
                logger.info('Ignoring initial OK alarm state')
                return

    description = data['AlarmDescription']

    state = STATES[state_value]

    attachments = [{
        'text': '{status_emoji}  {state}'.format(
            status_emoji=state['status_emoji'],
            state=state_value,
        )
    }]

    if os.environ['ACCOUNT_APPEND'].lower() == 'true':
        if os.environ['ACCOUNT_NAME'] != '':
            account_string = '{name} ({id})'.format(
                name=os.environ['ACCOUNT_NAME'],
                id=account_id,
            )
        else:
            account_string = '{id}'.format(
                id=account_id,
            )

        attachments.append({
            'text': 'Account: {account_string}'.format(
                account_string=account_string,
            )
        })

    data = {
        'text': description,
        'attachments': attachments,
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
