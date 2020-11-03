import boto3, hmac, hashlib, json, re, os
from botocore.exceptions import ClientError

CODEBUILD = boto3.client('codebuild')
CODEPIPELINE = boto3.client('codepipeline')
SECRETSMANAGER = boto3.client('secretsmanager')

def handler(event, _context):
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

    if '#' not in branch:
        return response(200, 'Not buildable branch: %s' % branch)

    try:
        if github_event == 'push' and not body['deleted']:
            boto3.client('codebuild').start_build(
                projectName=os.environ['BUILD_PROJECT'],
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
            return response(200, 'Starting build project for branch: %s' % branch)

        elif github_event == 'delete':
            boto3.client('codebuild').start_build(
                projectName=os.environ['DELETE_PROJECT'],
                sourceVersion=os.environ['GITHUB_MASTER_BRANCH'],
                artifactsOverride={'type': 'NO_ARTIFACTS'},
                environmentVariablesOverride=[
                    {
                        'name': 'ISSUE_NUMBER',
                        'value': branch.split('#')[-1],
                        'type': 'PLAINTEXT'
                    }
                ]
            )
            return response(200, 'Starting delete project for branch: %s' % branch)

        else:
            return response(500, 'Unknown github_event: %s' % github_event)

    except ClientError as err:
        return response(500, 'Build failed for branch %s. Err: %s' % (branch, err))

def response(statusCode, body):
    return {'statusCode': statusCode, 'body': body}
