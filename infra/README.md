# AWS Setup from scratch

Before deploying any of the following, ensure we have first followed the instructions from our [AWS base setup](./base/README.md)

Once these steps have been followed. As our admin user (or new developer) we can sign in by visiting: http://samhstn.signin.aws.amazon.com

Account ID: samhstn
IAM user name: admin

The password will be given to you by whoever ran the steps described in [AWS base setup](./base/README.md).

This must be updated after the first login.

To access our Route53 domain configuraion, we will need to switch roles. This can be done in the top right dropdown.

Account: samhstn-base
Role: SamhstnBase
Display Name: base

For admin access to the `aws+samhstn@samhstn.com` account, we need to switch roles to:

Account: samhstn
Role: Admin
Display Name: admin

### Configure our AWS CLI

We can set up credentials for the above 2 roles by editing our `~/.aws/credentials` to include the following:

```bash
[samhstn]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
```

We can configure role cli access by editing our `~/.aws/config` to look like the following:

```bash
[default]
region = us-east-1
output = json

[profile samhstn-base]
role_arn = arn:aws:iam::<ACCOUNT_ID>:role/Admin
source_profile = samhstn

[profile samhstn-admin]
role_arn = arn:aws:iam::<ACCOUNT_ID>:role/SamhstnBase
source_profile = samhstn
```

We can choose which profile to use by setting the `AWS_DEFAULT_PROFILE` environment variable.

For example, we could set in our `~/.bashrc` as the following:

```bash
export AWS_DEFAULT_PROFILE=samhstn-admin
```

### Domain

Ensure we have purchased your domain from [`Route53`](https://console.aws.amazon.com/route53) with the route account.

To see your purchased domains, with the `samhstn-base` profile, run:

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

### Configure our Ssl certificate

Assuming the `samhstn-admin` role, run the following commands:

```bash
aws cloudformation create-stack \
  --stack-name acm \
  --template-body file://infra/acm.yaml
aws cloudformation wait stack-create-complete --stack-name acm
```

You will need to visit the `Route53` console as the samhstn-base `base` role and add a `CNAME` record set as described in the acm console for the samhstn `admin` role.

This takes around 30 minutes to complete.

### Create our S3 buckets for our static files

This will create two buckets:
+ `www.samhstn.com` (which will redirect to `samhstn.com`)
+ `samhstn.com` (which will be used for storing our static files)

Create these assuming the `samhstn-admin` role with the following commands:

```bash
aws cloudformation create-stack \
  --stack-name s3 \
  --template-body file://infra/s3.yaml
aws cloudformation wait stack-create-complete --stack-name s3
```

### Create CloudFront distribution

This will be used as our cdn and we will also attach our ssl certificate here.

Set this up assuming the `samhstn-admin` role with the following commands:

```bash
aws cloudformation create-stack \
  --stack-name cloudfront \
  --template-body file://infra/cloudfront.yaml
aws cloudformation wait stack-create-complete --stack-name cloudfront
```

The distribution will take up to half an hour to be created.

### Configure Route53 to point to CloudFront

Now we will look to point our route53 domain at our CloudFront Domain name using an `alias`.

Do so assuming the `samhstn-base` role, running the following commands:

```bash
aws cloudformation create-stack \
  --stack-name samhstn-route53 \
  --template-body file://infra/route53.yaml
  --parameters ParameterKey=CloudFrontDomainName,ParameterValue=<cloudfront-domain-name>
aws cloudformation wait stack-create-complete --stack-name samhstn-route53
```

### Configure builds to run on every Github push event

We will run a `CodeBuild` job which will run our tests on every push to Github.
To do this we need to authorize Github:

+ Visit https://console.aws.amazon.com/codesuite/codebuild/projects
+ If you see the message: 'You are connected to GitHub using OAuth` you can skip the next steps here.
+ Otherwise, click `Create build project`
+ In the `Source` section, select `GitHub` as the `Source provider`
+ Ensure `Connect using OAuth` is selected
+ Click Connect to `GitHub`
+ In the popup window, click `Authorize aws-codesuite`

Now run deploy the cloudformation template:

```bash
aws cloudformation create-stack \
 --stack-name codebuild \
 --template-body file://infra/codebuild.yaml \
 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name codebuild
```

### Configure our Codepipeline pipeline

This will listen to chnages on our Github `master` branch and build our site.

Run the following command to build our pipeline stack:

```bash
aws cloudformation create-stack \
 --stack-name master-pipeline \
 --template-body file://infra/master_pipeline.yaml \
 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name master-pipeline
```

Now we will configure our Github webhook.

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
