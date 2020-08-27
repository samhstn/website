#!/bin/bash

if ! [ -d venv ]; then
  echo "creating new venv"
  python3 -m venv venv
  venv/bin/python3 -m pip install --upgrade pip
fi

if ! [[ $(venv/bin/pip list) =~ "boto3" ]]; then
  venv/bin/pip install boto3
fi

venv/bin/python << EOF
import boto3

client = boto3.client('logs')

log_streams = client.describe_log_streams(logGroupName='/aws/lambda/Webhook', orderBy='LastEventTime', descending=True)

for log_stream in log_streams['logStreams']:
  print(log_stream['logStreamName'])

  log_events = client.get_log_events(logGroupName='aws/lambda/Webhook', logStreamName=log_stream['logStreamName'])

EOF
