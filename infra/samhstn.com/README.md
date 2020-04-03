# AWS Setup from scratch

Before deploying any of the following, ensure we have first followed the instructions from our [AWS root setup](../samhstn/README.md)

We can sign in by visiting: https://samhstn.signin.aws.amazon.com/console

Account ID: samhstn
IAM user name: admin

The password will be generated from the steps described in [AWS root setup](../samhstn/README.md).

This must be updated after the first login.

To access our root account services (e.g. Route53), we will need to switch roles.

This can be done with this link:

https://signin.aws.amazon.com/switchrole?roleName=SamhstnRoot&account=samhstnroot

For admin access to the project specific account (`aws+samhstn@samhstn.com`), we need to switch roles.

This can be done with this link:

https://signin.aws.amazon.com/switchrole?roleName=Admin&account=samhstn

Check out how to configure our CLI here: [CLI.md](../docs/CLI.md)

### Domain

Ensure we have purchased your domain from [`Route53`](https://console.aws.amazon.com/route53) with the route account.

To see your purchased domains, with the `samhstn-root` profile, run:

```bash
aws route53 list-hosted-zones --query 'HostedZones[*].Name' --output text
```

(if your domain isn't in the list you'll have to purchase it from the [Route53 `Domain Registration` page](https://console.aws.amazon.com/route53/home#DomainRegistration:) as the root user)

### Authorize Github

We will need to create a Github personal access token for `aws` to use.

+ Go to your [Github personal access tokens](https://github.com/settings/tokens).
+ Click `Generate new token`.
+ Give the `token` a description of `Full repo access`.
+ Tick the `repo` scope.
+ Tick the `admin:repo_hook` scope.
+ Click Generate token.

Now set this token as an environment variable called `SAMHSTN_PA_TOKEN`.

### Upload our cloudformation templates to our s3 bucket

We will upload our cloudformation templates to a secure s3 bucket with the commands:

```bash
(cd infra/samhstn.com/webhook && zip -r webhook.zip .)

aws s3 mb s3://samhstn-cfn-templates

aws s3 sync infra/samhstn.com s3://samhstn-cfn-templates \
  --exclude "*" \
  --include "*.yaml" \
  --include "*.zip" \
  --delete

ROOT_CANONICAL_ID=$(
  AWS_PROFILE=samhstn-root aws s3api list-buckets \
    --query Owner.ID \
    --output text
)

ADMIN_CANONICAL_ID=$(
  AWS_PROFILE=samhstn-admin aws s3api list-buckets \
    --query Owner.ID \
    --output text
)

aws s3api put-bucket-acl \
  --bucket samhstn-cfn-templates \
  --acl private \
  --grant-full-control id=$ADMIN_CANONICAL_ID \
  --grant-read id=$ROOT_CANONICAL_ID

# update the `cfn-bucket-policy.json` file to be the values of:
# ROOT_ACCOUNT_ID=$(AWS_PROFILE=samhstn-root aws sts get-caller-identity --query Account --output text)
# ADMIN_ACCOUNT_ID=$(AWS_PROFILE=samhstn-admin aws sts get-caller-identity --query Account --output text)
aws s3api put-bucket-policy \
  --bucket samhstn-cfn-templates \
  --policy file://infra/samhstn.com/cfn-bucket-policy.json

aws s3api put-public-access-block \
  --bucket samhstn-cfn-templates \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### Deploy our base stack

Assuming the `samhstn-admin` profile, run the following commands:

```bash
aws cloudformation create-stack \
  --stack-name base \
  --template-url https://samhstn-cfn-templates.s3.amazonaws.com/base.yaml \
  --parameters ParameterKey=GithubPAToken,ParameterValue=$SAMHSTN_PA_TOKEN \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
aws cloudformation wait stack-create-complete --stack-name base
```

We will now need to add a `CNAME` record set as described in the [acm console](http://console.aws.amazon.com/acm).

This can be done by visiting the `Route53` console as the `samhstn-root` profile and add a `CNAME` record set as described in the acm console for the samhstn `admin` role.

This takes over 30 minutes to complete.

### Triggering build

### Github Webhook configuration

To see all our current webhooks, run:

```bash
curl --user "samhstn:$SAMHSTN_PA_TOKEN" https://api.github.com/repos/samhstn/samhstn/hooks
```

To delete any old webhooks, run:

```bash
curl -X "DELETE" --user "samhstn:$SAMHSTN_PA_TOKEN" https://api.github.com/repos/samhstn/samhstn/hooks/<hook_id>
```

To add our webhook to trigger our CodePipeline build run:

```bash
WEBHOOK_URL=$(aws cloudformation describe-stacks --stack-name base --query "Stacks[0].Outputs[?OutputKey=='WebhookEndpoint'].OutputValue" --output text)
GITHUB_SECRET=$(aws secretsmanager get-secret-value --secret-id /GithubSecret --query SecretString --output text)
curl --user "samhstn:$SAMHSTN_PA_TOKEN" \
  --request POST \
  --data "{\"name\": \"web\", \"active\": true, \"events\": [\"push\"], \"config\": {\"url\": \"$WEBHOOK_URL\", \"secret\": \"$GITHUB_SECRET\"}}" \
  https://api.github.com/repos/samhstn/samhstn/hooks
```

Our repository webhooks (found at: https://github.com/samhstn/samhstn/settings/hooks).

To update our s3 bucket code, we run:

```bash
(cd infra/samhstn.com/webhook && zip -r webhook.zip .)
aws s3 sync infra/samhstn.com s3://samhstn-cfn-templates \
  --exclude "*" \
  --include "*.yaml" \
  --include "*.zip" \
  --delete
aws lambda update-function-code --function-name Webhook --s3-bucket samhstn-cfn-templates --s3-key webhook/webhook.zip
```
