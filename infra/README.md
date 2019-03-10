# AWS Setup from scratch

### Configure our AWS CLI

We will create an `admin` user which we will use for programmatic access.

In the [`IAM` web view](https://console.aws.amazon.com/iam):

+ Create an `Admin` Group:
  + Click `Groups`.
  + `Create New Group`.
  + Name the group `Admin`.
  + Tick `AdministratorAccess`.
  + `Next Step`.
  + `Create Group`.
+ Create an `Admin` User:
  + Click `Users`.
  + Click `Add user`.
  + Name the user `admin`.
  + For `Access type` select `Programmatic access`.
  + Click `Next: Permission`.
  + Tick our `Admin` group.
  + Tick `Next: Tags`.
  + No need to add any `tags` for now, so click `Next: Review`.
  + Click `Create user`.
  + Then download the `credentials.csv` file.

Now we will configure our `aws` `cli` to use our `admin` user.

Find our `Access Key ID` and `Secret access key` in our downloaded `credentials.csv` file.

+ Run `aws configure`.
+ Set our `Access Key ID` and `Secret access key` from our `credentials.csv`.
+ Set our region to `us-east-1`.
+ Set output format to `json`.

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

