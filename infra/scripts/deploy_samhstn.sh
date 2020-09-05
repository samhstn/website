#!/bin/bash

source .env

aws cloudformation deploy \
  --profile samhstn-admin \
  --stack-name project-iam \
  --template-file ./infra/samhstn/project-iam.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    TempPassword=$TEMP_PASSWORD \
    RootAccountId=$AWS_ROOT_ACCOUNT_ID | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'

aws cloudformation deploy \
  --profile samhstn-admin \
  --stack-name setup \
  --template-file ./infra/samhstn/setup.yml \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    CloudformationBucket=samhstn-cfn-$AWS_ADMIN_ACCOUNT_ID \
    CodeBuildBucket=samhstn-codebuild-$AWS_ADMIN_ACCOUNT_ID \
    CodePipelineBucket=samhstn-codepipeline-$AWS_ADMIN_ACCOUNT_ID \
    Certificate=$CERTIFICATE | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'

mkdir -p infra/cfn_output/samhstn

PACKAGE_ERR="$(aws cloudformation package \
  --profile samhstn-admin \
  --template ./infra/samhstn/main.yml \
  --s3-bucket samhstn-cfn-$AWS_ADMIN_ACCOUNT_ID \
  --output-template-file infra/cfn_output/samhstn/main.yml 2>&1)"

if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
  echo "ERROR while running 'aws cloudformation package' command:"
  echo $PACKAGE_ERR
  exit 1
fi

aws cloudformation deploy \
  --profile samhstn-admin \
  --stack-name main \
  --template-file ./infra/cfn_output/samhstn/main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GithubPAToken=$SAMHSTN_PA_TOKEN \
    GithubMasterBranch=$GITHUB_MASTER_BRANCH | tr '\n' ' ' | sed 's/^ //' | sed 's/  / /g'
