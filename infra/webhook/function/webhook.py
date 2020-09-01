import boto3, hmac, hashlib, base64, json, urllib.parse, re, os
from botocore.exceptions import ClientError

def handler(event, _context): # pragma: no cover
    print('event', event)

    environ = {
        'github_master_branch': os.environ['GITHUB_MASTER_BRANCH'],
        'build_project': os.environ['BUILD_PROJECT'],
        'delete_project': os.environ['DELETE_PROJECT']
    }

    client = {
        'codepipeline': boto3.client('codepipeline'),
        'codebuild': boto3.client('codebuild')
    }

    secretsmanager = boto3.client('secretsmanager')

    github_secret = secretsmanager.get_secret_value(SecretId='/GithubSecret')['SecretString']

    return handle_event(event, github_secret, client, environ)

def handle_event(event, secret, client, environ):
    signature = event['headers']['x-hub-signature']
    github_event = event['headers']['x-github-event']
    body_encoded = base64.b64decode(event['body'])

    sha1 = hmac.new(secret.encode(), body_encoded, hashlib.sha1).hexdigest()

    if not hmac.compare_digest('sha1=%s' % sha1, signature):
        return response(403, 'x-hub-signature mismatch')

    body_unquoted = urllib.parse.unquote(body_encoded.decode())
    body = json.loads(re.sub('^payload=', '', body_unquoted))

    if github_event == 'ping':
        return response(200, 'OK')

    branch = re.sub('^refs/heads/', '', body['ref'])

    if github_event == 'push' and branch == environ['github_master_branch']:
        # client['codepipeline'].start_pipeline_execution(name=branch)
        return response(200, 'Running codepipeline')

    if github_event in ['push', 'delete']:
        if '#' not in branch:
            return response(200, 'Not buildable branch: %s' % branch)

        try:
            client['codebuild'].start_build(
                projectName=environ[github_event],
                sourceVersion=branch,
                artifactsOverride={'type': 'NO_ARTIFACTS'},
                environmentVariableOverride=[
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
