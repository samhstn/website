#!/bin/bash

EC2_INSTANCE_TYPE=t2.micro

echo -e "\n\n=========== Deploying main.yml ==========="

aws cloudformation deploy \
  --region eu-west-1 \
  --stack-name website \
  --template-file main.yml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EC2InstanceType=$EC2_INSTANCE_TYPE
