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

./infra/samhstn/configure_github_webhook.sh
