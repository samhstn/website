import boto3, hmac, hashlib, json, re, os
from botocore.exceptions import ClientError

CODEBUILD = boto3.client('codebuild')
CODEPIPELINE = boto3.client('codepipeline')
SECRETSMANAGER = boto3.client('secretsmanager')

def handler(event, _context):
    environ = {
        'push': os.environ['BUILD_PROJECT'],
        'delete': os.environ['DELETE_PROJECT']
    }

    github_secret = SECRETSMANAGER.get_secret_value(SecretId='/GithubSecret')['SecretString']
    github_event = event['headers']['x-github-event']

    sha1 = hmac.new(github_secret.encode(), event['body'].encode(), hashlib.sha1).hexdigest()

    if not hmac.compare_digest('sha1=%s' % sha1, event['headers']['x-hub-signature']):
        return response(403, 'x-hub-signature mismatch')

    body = json.loads(event['body'])

    if github_event == 'ping':
        return response(200, 'OK')

    branch = re.sub('^refs/heads/', '', body['ref'])

    if github_event == 'push' and branch == os.environ['GITHUB_MASTER_BRANCH']:
        CODEPIPELINE.start_pipeline_execution(name='master')
        return response(200, 'Running codepipeline')

    if github_event in ['push', 'delete']:
        if '#' not in branch:
            return response(200, 'Not buildable branch: %s' % branch)

        try:
            boto3.client('codebuild').start_build(
                projectName=environ[github_event],
                sourceVersion=branch,
                artifactsOverride={'type': 'NO_ARTIFACTS'},
                environmentVariablesOverride=[
                    {
                        'name': 'ISSUE_NUMBER',
                        'value': branch.split('#')[-1],
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
