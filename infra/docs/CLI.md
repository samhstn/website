# AWS CLI

We always use the cli with a user with all permissions granted through a role with mfa enforced.

This will ensure that we will always need to log in with mfa after a certain number of hours for our keys to work.

First, ensure we deployed both of the iam templates from [root setup](../samhstn/README.md).

To get a new set of keys, as the project user, create a new set of security credentials for the `admin` user, these can be used below.

### Configure our AWS CLI

In our `~/.aws/credentials`, we should add the following:

```bash
[samhstn]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
```

We can configure role cli access by editing our `~/.aws/config` to look like the following:

```bash
[profile samhstn-root]
role_arn = arn:aws:iam::<ROOT_ACCOUNT_ID>:role/SamhstnRoot
source_profile = samhstn
region = eu-west-1
output = json

[profile samhstn-admin]
role_arn = arn:aws:iam::<PROJECT_ACCOUNT_ID>:role/Admin
source_profile = samhstn
region = eu-west-1
output = json
```

We will mostly want to run commands with the admin role, so we should configure this:

```bash
export AWS_PROFILE=samhstn-admin
```

To change profile, simply change this before the `aws` command:

```bash
AWS_PROFILE=samhstn-root aws ...
```
