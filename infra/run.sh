#!/bin/bash

if ! [[ -d ./infra ]]; then
  echo "ERR: ./infra/run.sh needs to be run from root directory"
  exit 1
fi

if [[ $1 == "setup" ]]; then
  ./infra/scripts/setup.sh
elif [[ $1 == "deploy" ]]; then
  ./infra/scripts/deploy.sh
elif [[ $1 == "deploy-root" ]]; then
  ./infra/scripts/deploy_root.sh
elif [[ $1 == "deploy-samhstn" ]]; then
  ./infra/scripts/deploy_samhstn.sh
elif [[ $1 == "teardown" ]]; then
  ./infra/scripts/teardown.sh
elif [[ $1 == "configure-github-webhook" ]]; then
  ./infra/venv/bin/python infra/scripts/configure_github_webhook.py
elif [[ $1 == "get-webhook-logs" ]]; then
  ./infra/venv/bin/python infra/scripts/get_webhook_logs.py
elif [[ $1 == "test-webhook" ]]; then
  ./infra/scripts/test_webhook.sh
else
  echo "ERR: unknown option $1"
  exit 1
fi
