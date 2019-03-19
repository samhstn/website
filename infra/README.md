# AWS Setup from scratch

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

Now set this token as an environment variable called `GITHUB_PA_TOKEN`.

### Configure our Ssl certificate

(For the most up-to-date instructions see here: https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html)

You can request a ssl certificate for our domain with the following command:

```bash
aws acm request-certificate --domain-name samhstn.com --validation-method DNS
```

Then in the [`acm` view](https://console.aws.amazon.com/acm):
+ Click our `samhstn.com` domain name.
+ Click `samhstn.com` in the `Domain` section.
+ Click `Create record in Route 53`.
+ Confirm by clicking `Create`.

Now we're going to wait for it to be validated (this takes around 30 minutes).

You can wait for this to be validated in the command line with the following command:

```bash
ACM_CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='samhstn.com'].CertificateArn | [0]" --output text)
aws acm wait certificate-validated --certificate-arn "$ACM_CERT_ARN"
```

### Create our S3 buckets for our static files

This will create two buckets:
+ `www.samhstn.com` (which will redirect to `samhstn.com`)
+ `samhstn.com` (which will be used for storing our static files)

Create these with the command:

```bash
aws cloudformation create-stack --stack-name samhstn-s3 --template-body file://infra/s3.yaml
aws cloudformation wait stack-create-complete
```

### Create CloudFront distribution

This will be used as our cdn and we will also attach our ssl certificate here.

Set this up with the following commands:

```bash
ACM_CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='samhstn.com'].CertificateArn | [0]" --output text)
aws cloudformation create-stack \
  --stack-name samhstn-cloudfront \
  --template-body file://infra/cloudfront.yaml \
  --parameters "ParameterKey=AcmCertArn,ParameterValue=$ACM_CERT_ARN"
aws cloudformation wait stack-create-complete
```

The distribution will take up to half an hour to be created.

### Configure Route53 to point to CloudFront

Now we will look to point our route53 domain at our CloudFront Domain name using an `alias`.

Do so by running the following command:

```bash
CLOUD_FRONT_DOMAIN_NAME=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='samhstn.com'] | [0].DomainName" --output text)
aws cloudformation create-stack \
  --stack-name samhstn-route53 \
  --template-body file://infra/route53.yaml \
  --parameters "ParameterKey=CloudFrontDomainName,ParameterValue=$CLOUD_FRONT_DOMAIN_NAME"
aws cloudformation wait stack-create-complete
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
aws cloudformation wait stack-create-complete
```

### Configure our Codepipeline pipeline

This will listen to chnages on our Github `master` branch and build our site.

We will need a secret to pass to our CodePipeline and our Github webhook.

```bash
GITHUB_SECRET=$(node -e "console.log(require('crypto').randomBytes(64).toString('base64'));")
```

Run the following command to build our pipeline stack:

```bash
aws cloudformation create-stack \
 --stack-name samhstn-codepipeline \
 --template-body file://infra/codepipeline.yaml \
 --parameters "ParameterKey=GithubPAToken,ParameterValue=$GITHUB_PA_TOKEN" \
              "ParameterKey=GithubSecret,ParameterValue=$GITHUB_SECRET" \
 --capabilities CAPABILITY_NAMED_IAM
aws cloudformation wait stack-create-complete
```

Now we will configure our Github webhook.

To see all our current webhooks run:

```bash
curl --user "samhstn:$GITHUB_PA_TOKEN" https://api.github.com/repos/samhstn/samhstn/hooks
```

To add our webhook to trigger our CodePipeline build run:

```bash
WEBHOOK_URL=$(aws codepipeline list-webhooks --query "webhooks[*].url | [0]" --output text)
curl --user "samhstn:$GITHUB_PA_TOKEN" -X POST \
  --data "{\"name\": \"web\", \"active\": true, \"events\": [\"push\"], \"config\": {\"url\": \"$WEBHOOK_URL\", \"secret\": \"$GITHUB_SECRET\"}}" \
  https://api.github.com/repos/samhstn/samhstn/hooks
```

