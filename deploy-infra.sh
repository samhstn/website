#!/bin/bash

set -e

ENV_FILE=".env"

touch $ENV_FILE
source $ENV_FILE

if [[ -z "$SAMHSTN_PA_TOKEN" ]]; then
  echo "Required environment variable SAMHSTN_PA_TOKEN is not defined"
  exit 1
fi

if [[ -z "$SAMHSTN_FROM_EMAIL" ]]; then
  echo "Required environment variable SAMHSTN_FROM_EMAIL is not defined"
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

aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn \
  --template-file ./infra/root/iam.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    Project=Samhstn \
    AccountId=$AWS_ADMIN_ACCOUNT_ID

aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn-setup \
  --template-file ./infra/root/setup.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EmailBucket=samhstn-mail-$AWS_ROOT_ACCOUNT_ID \
    CloudformationBucket=samhstn-cfn-$AWS_ROOT_ACCOUNT_ID

(cd infra/root/receive_email && zip -r receive_email.zip .)
aws s3 sync --profile samhstn-root infra/root/receive_email s3://samhstn-cfn-$AWS_ROOT_ACCOUNT_ID --exclude '*' --include '*.zip'

aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn-main \
  --template-file ./infra/root/main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail=hello@samhstn.com \
    NotificationEmail=contact.samhstn@gmail.com

if [[ -z $(aws ses --profile samhstn-root describe-active-receipt-rule-set) ]]; then
  echo setting rule set
  aws ses --profile samhstn-root set-active-receipt-rule-set --rule-set-name SamhstnRuleSet
fi
