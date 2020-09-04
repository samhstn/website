#!/bin/bash -x

STACK=$(aws cloudformation describe-stacks --stack-name "samhstn-${ISSUE_NUMBER}")

if [ $? ]; then
  echo "stack exists"
else
  echo "stack doesn't exist"
fi
