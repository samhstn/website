import dotenv, jmespath, os, boto3, requests, json

dotenv.load_dotenv(dotenv.find_dotenv())

SAMHSTN_PA_TOKEN = os.environ['SAMHSTN_PA_TOKEN']

admin_session = boto3.Session(profile_name='samhstn-admin')

cloudformation_admin_client = admin_session.client('cloudformation')
secretsmanager_admin_client = admin_session.client('secretsmanager')

WEBHOOK_URL = jmespath.search(
        "Exports[?Name=='WebhookEndpoint'].Value|[0]",
        cloudformation_admin_client.list_exports()
    )
GITHUB_SECRET = secretsmanager_admin_client.get_secret_value(
        SecretId='/GithubSecret'
    )['SecretString']

hookUrl = 'https://api.github.com/repos/samhstn/samhstn/hooks'
auth = ('samhstn', SAMHSTN_PA_TOKEN)

r = requests.get(hookUrl, auth = auth)
r.raise_for_status()

webhooks = r.json()

def isValid(webhook):
  return all([
    w['active'],
    w['events'] == ['delete', 'push'],
    w['config']['url'] == WEBHOOK_URL,
    w['config']['content_type'] == 'json'
  ])

for w in webhooks:
  if not isValid(w):
    print('deleting webhook: %d' % w['id'])
    resp = requests.delete('%s/%d' % (hookUrl, w['id']), auth = auth)
    resp.raise_for_status()

if not any(map(isValid, webhooks)):
  print('creating new webhook')
  data = json.dumps({
    'active': True,
    'events': ['push', 'delete'],
    'config': {'url': WEBHOOK_URL, 'secret': GITHUB_SECRET, 'content_type': 'json'}
  })
  resp = requests.post(hookUrl, data = data, auth = auth)
  resp.raise_for_status()
