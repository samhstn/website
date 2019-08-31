# AWS Setup from scratch

Before deploying any of the following, ensure we have first followed the instructions from our [AWS root setup](./root/README.md)

Once these steps have been followed. As our admin user (or new developer) we can sign in by visiting: http://samhstn.signin.aws.amazon.com

Account ID: samhstn
IAM user name: admin

The password will be given to you by whoever ran the steps described in [AWS root setup](./root/README.md).

This must be updated after the first login.

To access our Route53 domain configuraion, we will need to switch roles. This can be done in the top right dropdown.

Account: samhstn-root
Role: SamhstnRoot
Display Name: samhstn-root

For admin access to the `aws+samhstn@samhstn.com` account, we need to switch roles to:

Account: samhstn
Role: Admin
Display Name: samhstn-admin

### Configure our AWS CLI

We can set up credentials for the above 2 roles by editing our `~/.aws/credentials` to include the following:

```bash
[samhstn]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
```

We can configure role cli access by editing our `~/.aws/config` to look like the following:

```bash
[profile samhstn-root]
region = us-east-1
output = json
role_arn = arn:aws:iam::<ACCOUNT_ID>:role/SamhstnRoot
source_profile = samhstn

[profile samhstn-admin]
region = us-east-1
output = json
role_arn = arn:aws:iam::<ACCOUNT_ID>:role/Admin
source_profile = samhstn
```

For the next steps we will assume that this environment variable will have been set as:

```bash
export AWS_DEFAULT_PROFILE=samhstn-admin
```

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

We will upload our cloudformation templates to an s3 bucket with the commands:

```bash
aws s3api create-bucket \
  --bucket samhstn-cfn-templates \
  --acl private

aws s3 sync infra s3://samhstn-cfn-templates --exclude "*" --include "*.yaml"

aws cloudformation create-stack \
  --stack-name base \
  --template-url https://samhstn-cfn-templates.s3.amazonaws.com/base.yaml \
  --parameters ParameterKey=GithubPAToken,ParameterValue=$SAMHSTN_PA_TOKEN \
  --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name base
```

### Deploy our base stack

Assuming the `samhstn-admin` profile, run the following commands:

```bash
aws cloudformation create-stack \
  --stack-name base \
  --template-body file://infra/acm.yaml
aws cloudformation wait stack-create-complete --stack-name acm
```

We will now need to add a `CNAME` record set as described in the acm console.

This can be done by visiting the `Route53` console as the `samhstn-base` profile and add a `CNAME` record set as described in the acm console for the samhstn `admin` role.

This takes over 30 minutes to complete.

### Triggering build

### Github Webhook configuration

To see all our current webhooks run:

```bash
curl --user "samhstn:$SAMHSTN_PA_TOKEN" https://api.github.com/repos/samhstn/samhstn/hooks
```

To add our webhook to trigger our CodePipeline build run:

```bash
WEBHOOK_URL=$(aws codepipeline list-webhooks --query "webhooks[*].url | [0]" --output text)
GITHUB_SECRET=$(aws secretsmanager get-secret-value --secret-id /GithubSecret --query SecretString --output text)
curl --user "samhstn:$SAMHSTN_PA_TOKEN" \
  --request POST \
  --data "{\"name\": \"web\", \"active\": true, \"events\": [\"push\"], \"config\": {\"url\": \"$WEBHOOK_URL\", \"secret\": \"$GITHUB_SECRET\"}}" \
  https://api.github.com/repos/samhstn/samhstn/hooks
```

Our repository webhooks (found at: https://github.com/samhstn/samhstn/settings/hooks) should show:

TODO: check this is correct
```
https://us-east-1.webhooks.aws/trigger  (push)
```
