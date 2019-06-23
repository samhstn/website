# AWS Setup from scratch

Before deploying any of the following, ensure we have first followed the instructions from our [AWS base setup](./base/README.md)

Once these steps have been followed. A new developer can sign up by visiting: http://samhstn.signin.aws.amazon.com

Account ID: samhstn
IAM user name: admin

The password will be given to you by whoever ran the steps described in [AWS base setup](./base/README.md).

This must be updated after the first login.

To access our Route53 domain configuraion, we will need to switch roles. This can be done in the top right dropdown.

Account: samhstn-base
Role: Route53Role
Display Name: route53 base

For admin access to the `aws+samhstn@samhstn.com` account, we need to switch roles to:

Account: samhstn
Role: Admin
Display Name: admin

### Configure our AWS CLI

We will create an `admin` user which we will use for programmatic access.

In the [`IAM` web view](https://console.aws.amazon.com/iam):

+ Create a group called `Admin` with `AdministratorAccess`
+ Create a user called `admin` with our `Admin` group permissions
+ Download the `credentials.csv` file.

Now we will configure our `aws` `cli` to use our `admin` user.

+ Run `aws configure`.
+ Set our `Access Key ID` and `Secret access key` from our downloaded `credentials.csv`.
+ Set our region to `us-east-1`.
+ Set output format to `json`.

### Domain

Ensure you have purchased your domain from [`Route53`](https://console.aws.amazon.com/route53)

To see your purchased domains, run:

```bash
aws route53 list-hosted-zones --query 'HostedZones[*].Name' --output text
```

(if your domain isn't in the list you'll have to purchase it from the [Route53 `Domain Registration` page](https://console.aws.amazon.com/route53/home#DomainRegistration:))

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

```bash
aws cloudformation create-stack \
  --stack-name samhstn-acm \
  --template-body file://infra/acm.yaml
aws cloudformation wait stack-create-complete --stack-name samhstn-acm
```

Then visit https://console.aws.amazon.com/acm and click 'Create record in Route 53' and 'Create'.
(You may have to wait one minute for this to show).

You should now see the message:

'The status of this certificate request is "Pending validation". Further action is needed to validate and approve the certificate.'

This takes around 30 minutes to complete.

### Create our S3 buckets for our static files

This will create two buckets:
+ `www.samhstn.com` (which will redirect to `samhstn.com`)
+ `samhstn.com` (which will be used for storing our static files)

Create these with the command:

```bash
aws cloudformation create-stack \
  --stack-name samhstn-s3 \
  --template-body file://infra/s3.yaml
aws cloudformation wait stack-create-complete --stack-name samhst-s3
```

### Create CloudFront distribution

This will be used as our cdn and we will also attach our ssl certificate here.

Set this up with the following commands:

```bash
aws cloudformation create-stack \
  --stack-name samhstn-cloudfront \
  --template-body file://infra/cloudfront.yaml
aws cloudformation wait stack-create-complete --stack-name samhstn-cloudfront
```

The distribution will take up to half an hour to be created.

### Configure Route53 to point to CloudFront

Now we will look to point our route53 domain at our CloudFront Domain name using an `alias`.

Do so by running the following command:

```bash
aws cloudformation create-stack \
  --stack-name samhstn-route53 \
  --template-body file://infra/route53.yaml
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
 --stack-name samhstn-codebuild \
 --template-body file://infra/codebuild.yaml \
 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete --stack-name samhstn-codebuild
```

### Configure our Codepipeline pipeline

This will listen to chnages on our Github `master` branch and build our site.

Run the following command to build our pipeline stack:

```bash
aws cloudformation create-stack \
 --stack-name samhstn-master-pipeline \
 --template-body file://infra/master_pipeline.yaml \
 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete
```

Now we will configure our Github webhook.

To see all our current webhooks run:

```bash
curl --user "samhstn:$SAMHSTN_PA_TOKEN" https://api.github.com/repos/samhstn/samhstn/hooks
```

To add our webhook to trigger our CodePipeline build run:

```bash
WEBHOOK_URL=$(aws codepipeline list-webhooks --query "webhooks[*].url | [0]" --output text)
GITHUB_SECRET=$(aws secretsmanager get-secret-value --secret-id /Samhstn/GithubSecret --query SecretString --output text)
curl --user "samhstn:$SAMHSTN_PA_TOKEN" \
  --request POST \
  --data "{\"name\": \"web\", \"active\": true, \"events\": [\"push\"], \"config\": {\"url\": \"$WEBHOOK_URL\", \"secret\": \"$GITHUB_SECRET\"}}" \
  https://api.github.com/repos/samhstn/samhstn/hooks
```
