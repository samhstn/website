#!/bin/bash

ENV_FILE=".env"
GITHUB_MASTER_BRANCH=master

touch $ENV_FILE
source $ENV_FILE

if [[ -z "$SAMHSTN_PA_TOKEN" ]]; then
  echo "Required environment variable SAMHSTN_PA_TOKEN is not defined"
  exit 1
fi

if [[ -z "$SAMHSTN_NOTIFICATION_EMAIL" ]]; then
  echo "Required environment variable SAMHSTN_NOTIFICATION_EMAIL is not defined"
  exit 1
fi

if [[ -z "$AWS_ADMIN_ACCOUNT_ID" ]]; then
  AWS_ADMIN_ACCOUNT_ID=$(aws sts get-caller-identity --profile samhstn-admin --query Account --output text)
  echo "AWS_ADMIN_ACCOUNT_ID=$AWS_ADMIN_ACCOUNT_ID" >> $ENV_FILE
fi

if [[ -z "$AWS_ROOT_ACCOUNT_ID" ]]; then
  AWS_ROOT_ACCOUNT_ID=$(aws sts get-caller-identity --profile samhstn-root --query Account --output text)
  echo "AWS_ROOT_ACCOUNT_ID=$AWS_ROOT_ACCOUNT_ID" >> $ENV_FILE
fi

./infra/root/deploy.sh

if [[ -z $TEMP_PASSWORD ]]; then
  TEMP_PASSWORD=$(node -e "console.log(Math.random().toString(36).slice(2))")
  echo "TEMP_PASSWORD=$TEMP_PASSWORD" >> $ENV_FILE
fi

./infra/samhstn/deploy.sh

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
