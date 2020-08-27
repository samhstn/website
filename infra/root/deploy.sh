#!/bin/bash

source .env

printf 'Deploying root iam.yml '
aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn \
  --template-file ./infra/root/iam.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    Project=Samhstn \
    AccountId=$AWS_ADMIN_ACCOUNT_ID | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'

printf 'Deploying root setup.yml '
aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn-setup \
  --template-file ./infra/root/setup.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EmailBucket=samhstn-mail-$AWS_ROOT_ACCOUNT_ID \
    CloudformationBucket=samhstn-cfn-$AWS_ROOT_ACCOUNT_ID | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'

mkdir -p infra/cfn_output/root

echo 'Packaging root main.yml'
PACKAGE_ERR="$(aws cloudformation package \
  --profile samhstn-root \
  --template ./infra/root/main.yml \
  --s3-bucket samhstn-cfn-$AWS_ROOT_ACCOUNT_ID \
  --output-template-file infra/cfn_output/root/main.yml 2>&1)"

if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
  echo "ERROR while running 'aws cloudformation package' command:"
  echo $PACKAGE_ERR
  exit 1
fi

printf 'Deploying root main.yml '
aws cloudformation deploy \
  --profile samhstn-root \
  --stack-name samhstn-main \
  --template-file ./infra/cfn_output/root/main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    FromEmail=hello@samhstn.com \
    NotificationEmail=$SAMHSTN_NOTIFICATION_EMAIL | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'

if [[ -z $(aws ses --profile samhstn-root describe-active-receipt-rule-set) ]]; then
  echo "setting rule set"
  aws ses --profile samhstn-root set-active-receipt-rule-set --rule-set-name SamhstnRuleSet
fi
