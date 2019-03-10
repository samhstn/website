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

### Authorize github

We will need to create a GitHub personal access token for `aws` to use.

+ Go to your [GitHub personal access tokens](https://github.com/settings/tokens).
+ Click `Generate new token`.
+ Give the `token` a description of `Full repo access`.
+ Tick the `repo` scope.
+ Click Generate token.

Now set this token as an environment variable called `GITHUB_PA_TOKEN`.

### Deploy the Cloudformation templates

```bash
aws cloudformation create-stack \
--stack-name samhstn-base \
--template-body file://infra/base.yml \
--capabilities CAPABILITY_NAMED_IAM \
--parameters "ParameterKey=GithubRepoPaKey,ParameterValue=$GITHUB_REPO_PA_KEY"
```

