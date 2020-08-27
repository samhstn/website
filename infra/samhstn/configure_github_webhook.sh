#!/bin/bash

source .env

WEBHOOK_URL=$(aws cloudformation list-exports --profile samhstn-admin | jp -u "Exports[?Name=='WebhookEndpoint'].Value|[0]")
GITHUB_SECRET=$(aws secretsmanager get-secret-value --secret-id /GithubSecret --query SecretString --output text)

if ! [ -d venv ]; then
  echo "creating new venv"
  python3 -m venv venv
  venv/bin/python3 -m pip install --upgrade pip
fi

if ! [[ $(venv/bin/pip list) =~ "requests" ]]; then
  venv/bin/pip install requests
fi

venv/bin/python << EOF
import requests
import json

hookUrl = 'https://api.github.com/repos/samhstn/samhstn/hooks'
auth = ('samhstn', '$SAMHSTN_PA_TOKEN')

r = requests.get(hookUrl, auth = auth)
r.raise_for_status()

webhooks = r.json()

def isValid(webhook):
  return all([
    w['active'],
    w['events'] == ['create', 'delete', 'push'],
    w['config']['url'] == '$WEBHOOK_URL'
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
    'events': ['push', 'create', 'delete'],
    'config': {'url': '$WEBHOOK_URL', 'secret': '$GITHUB_SECRET'}
  })
  resp = requests.post(hookUrl, data = data, auth = auth)
  resp.raise_for_status()
EOF
