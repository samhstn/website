# AWS Setup from scratch

### Configure your AWS CLI

In the [`IAM` web view](https://console.aws.amazon.com/iam):

+ Create a user called `admin` with programmatic access.
+ Add it to a group called `Admin` with `AdministratorAccess`.

In your command line, run: `aws configure` and fill in the credentials which will have been given to you through Iam.

Create a personal access token for aws to use.

### Domain

Ensure you have purchased a domain in AWS using: https://console.aws.amazon.com/route53

To check if you have purchased your domain, run:

```bash
aws route53 list-hosted-zones --query 'HostedZones[*].Name' --output text
```

and check if your domain is in the list.

### Authorize github

You will need to grant repo access and generate a personal access token with the scope of `repo`.

(I have set this as the environment variable `GITHUB_REPO_PA_KEY` for the next step).

### Deploy the Cloudformation templates

```bash
aws cloudformation create-stack \
--stack-name samhstn-base \
--template-body file://infra/base.yml \
--capabilities CAPABILITY_NAMED_IAM \
--parameters "ParameterKey=GithubRepoPaKey,ParameterValue=$GITHUB_REPO_PA_KEY"
```

