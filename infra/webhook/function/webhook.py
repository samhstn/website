import boto3, hmac, hashlib, json, re, os
from botocore.exceptions import ClientError

def handler(event, _context): # pragma: no cover
    environ = {
        'github_master_branch': os.environ['GITHUB_MASTER_BRANCH'],
        'push': os.environ['BUILD_PROJECT'],
        'delete': os.environ['DELETE_PROJECT']
    }

    client = {
        'codepipeline': boto3.client('codepipeline'),
        'codebuild': boto3.client('codebuild'),
        'sqs': boto3.client('sqs')
    }

    secretsmanager = boto3.client('secretsmanager')

    github_secret = secretsmanager.get_secret_value(SecretId='/GithubSecret')['SecretString']

    return handle_event(event, github_secret, client, environ)

def handle_event(event, secret, client, environ):
    signature = event['headers']['x-hub-signature']
    github_event = event['headers']['x-github-event']

    sha1 = hmac.new(secret.encode(), event['body'].encode(), hashlib.sha1).hexdigest()

    if not hmac.compare_digest('sha1=%s' % sha1, signature):
        return response(403, 'x-hub-signature mismatch')

    body = json.loads(event['body'])

    if github_event == 'ping':
        return response(200, 'OK')

    branch = re.sub('^refs/heads/', '', body['ref'])

    if github_event == 'push' and branch == environ['github_master_branch']:
        # client['codepipeline'].start_pipeline_execution(name=branch)
        return response(200, 'Running codepipeline')

    if github_event in ['push', 'delete']:
        if '#' not in branch:
            return response(200, 'Not buildable branch: %s' % branch)

        queue_url = None
        thirty_mins = '1800'
        ISSUE_NUMBER = branch.split('#')[-1]

        try:
            sqs_response = client['sqs'].create_queue(
                QueueName='samhstn-%d' % ISSUE_NUMBER,
                Attributes={
                    'ContentBasedDeduplication': 'false',
                    'FifoQueue': 'true',
                    'MessageRetentionPeriod': thirty_mins
                }
            )
            queue_url = sqs_response['QueueUrl']
            client['sqs'].send_message(
                QueueUrl=queue_url,
                MessageBody=body['head_commit']['id'],
                MessageGroupId='samhstn-%d' % ISSUE_NUMBER,
                MessageDeduplicationId=str(uuid.uuid4())
            )
        except ClientError as err:
            return response(500, 'Error creating queue for branch %s. Err: %s' % (branch, err))

        try:
            client['codebuild'].start_build(
                projectName=environ[github_event],
                sourceVersion=branch,
                artifactsOverride={'type': 'NO_ARTIFACTS'},
                environmentVariablesOverride=[
                    {
                        'name': 'ISSUE_NUMBER',
                        'value': branch.split('#')[-1],
                        'type': 'PLAINTEXT'
                    },
                    {
                        'name': 'QUEUE_URL',
                        'value': queue_url,
                        'type': 'PLAINTEXT'
                    }
                ]
            )
        except ClientError as err:
            return response(500, 'Build failed for branch %s. Err: %s' % (branch, err))

        return response(200, 'Starting build for branch: %s' % branch)
    else:
        return response(500, 'Unknown github_event: %s' % github_event)

def response(statusCode, body):
    return {'statusCode': statusCode, 'body': body}
