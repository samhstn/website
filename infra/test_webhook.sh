#!/bin/bash

set -e

GITHUB_SECRET=$(aws secretsmanager get-secret-value --secret-id /GithubSecret | jp -u SecretString)
PING_PAYLOAD=$(node -e "console.log(JSON.stringify(require('./genEvent.js')('$GITHUB_SECRET')(require('./test/sampleEvent.js').ping)))")
PUSH_PAYLOAD=$(node -e "console.log(JSON.stringify(require('./genEvent.js')('$GITHUB_SECRET')(require('./test/sampleEvent.js').push)))")

echo "==== ping ===="
aws lambda invoke --function-name Webhook \
  --invocation-type RequestResponse \
  --payload $(echo $PING_PAYLOAD | base64) \
  --log-type Tail /tmp/lambdaResult.json \
  | jp -u LogResult \
  | base64 --decode
cat /tmp/lambdaResult.json
echo -e "\n"

echo "==== push ===="
aws lambda invoke --function-name Webhook \
  --invocation-type RequestResponse \
  --payload $(echo $PUSH_PAYLOAD | base64) \
  --log-type Tail /tmp/lambdaResult.json \
  | jp -u LogResult \
  | base64 --decode
cat /tmp/lambdaResult.json

rm /tmp/lambdaResult.json
