# Infrastructure

### Accounts

We are using 2 root accounts to keep resources completely isolated (see #3 from [this article](https://serverlessfirst.com/managing-separate-projects-in-aws/#approach-3--separation-by-aws-account)).

#### Root account

Where our domain and emails are managed - all billing is under this account.

```
email: ****@gmail.com
```

#### Samhstn specific root account

Where all our logic specific to this project is handled.

```
email: aws+samhstn@samhstn.com
```

#### IAM user

IAM user who can switch roles and access certain parts of the two above root accounts.

```
account alias: samhstn
IAM user name: admin
Role1:
  Account: samhstnroot
  Role: SamhstnRoot
Role2:
  Account: samhstn
  Role: Admin
```

When set up, it should look something like this:

![](https://user-images.githubusercontent.com/15983736/90923091-f7f07100-e3e4-11ea-89cc-8f2cf86f0743.png)

### Templates

To set this up, we need to deploy the following templates:

```bash
# with our samhstn-root aws profile (or initially our root user).
infra/root/iam.yml

# with our samhstn-admin aws profile (or initially our Samhstn specific root user).
infra/root/samhstn-iam.yml
```

## CLI

Our IAM user should be configured as follows:

`~/.aws/credentials`
```
[samhstn]
aws_access_key_id = <aws_access_key_id>
aws_secret_access_key = <aws_secret_access_key>
```

`~/.aws/config`
```
[profile samhstn-root]
role_arn = arn:aws:iam::<root_account_id>:role/SamhstnRoot
source_profile = samhstn
region = eu-west-1
output = json

[profile samhstn-admin]
role_arn = arn:aws:iam::<admin_account_id>:role/Admin
source_profile = samhstn
region = eu-west-1
output = json
```

### Environment variables

We will need a Github personal access token `SAMHSTN_PA_TOKEN` for aws to access our Github repository.

+ Go to your [Github personal access tokens](https://github.com/settings/tokens).
+ Click Generate new token.
+ Give the token a description of Full repo access.
+ Tick the repo scope.
+ Tick the `admin:repo_hook` scope.
+ Click Generate token.

Now set this token locally as an environment variable called `SAMHSTN_PA_TOKEN`.

We also need to set a `SAMHSTN_FROM_EMAIL` environment variable for the email address to notify

when we receive an email to `@samhstn.com`.

### Deploying

We can now look to deploy our entire stack by running:

```bash
# set up python environment, check or add environment variables
./infra/scripts/setup.sh

# deploy stack
./infra/scripts/deploy.sh

# tears down, leaving any setup.yml stacks (mainly s3 buckets)
./infra/scripts/teardown.sh

# see infra/run.sh for all scripts

# .py scripts should be run with:
infra/venv/bin/python ./infra/scripts/get_webhook_logs.py
```
