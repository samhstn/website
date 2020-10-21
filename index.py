import boto3, uuid, random, time

ISSUE_NUMBER = 123

SQS = boto3.client('sqs')

sqs_response = SQS.create_queue(
    QueueName='samhstn-%d.fifo' % ISSUE_NUMBER,
    Attributes={
        'ContentBasedDeduplication': 'false',
        'FifoQueue': 'true',
        'MessageRetentionPeriod': '1800' # 30 mins
    }
)

r = random.randint(1, 1000)

print(r)

print(sqs_response)

queue_url = sqs_response['QueueUrl']

sqs_response = SQS.send_message(
    QueueUrl=queue_url,
    MessageBody='HelloWorld %d' % r,
    MessageGroupId='samhstn-123',
    MessageDeduplicationId=str(uuid.uuid4())
)

for i in range(7):
    print('index %d' % (i + 1))
    time.sleep(5)

    sqs_response = SQS.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        VisibilityTimeout=0
    )

    print(sqs_response)
