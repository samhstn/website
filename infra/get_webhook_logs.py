import boto3

client = boto3.client('logs')

logGroupName = '/aws/lambda/Webhook'

log_streams = client.describe_log_streams(logGroupName=logGroupName)

for log_stream in log_streams['logStreams']:
    logStreamName = log_stream['logStreamName']

    log_events = client.get_log_events(
            logGroupName=logGroupName,
            logStreamName=logStreamName
        )

    print(log_events.keys())
    for event in log_events['events']:
        print(event)
