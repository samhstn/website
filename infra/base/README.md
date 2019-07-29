# Base

We have one base root user who delegates permissions to all other project root users and is in charge of the billing for all projects.

This base root user will deploy 2 cloudformation templates:

1. To configure `@samhstn.com` email addresses which will be used as the root user for each project.
2. Configure the different iam permissions for each project root user.

### Email

We will set up receiving emails for the `@samhstn.com` domain.

In the aws base root account, deploy the `infra/base/email.yaml` cloudformation template.

Provide an email to receive email notifications on as a template parameter.

Next go to the ses console and in the domains identity management tab, click on the samhstn.com domain, then click to add the TXT record set in route53.

(It may take up to 5 minutes for the route53 MX record set changes to propegate after the stack is deployed and 30 mins for the route53 TXT record set changes to propegate).

Next, we need to set the SES ruleset to active, to do this, go to:

https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules:

and set `SamhstnRuleSet` as the `Active Rule Set`.

Next, in the aws console, visit: https://console.aws.amazon.com/ses/home?region=us-east-1#verified-senders-email:

Click `Verify a New Email Address`, then enter `hello@samhstn.com` and the email address we specified as our template parameter.

Now in the `samhstn-emails` s3 bucket, there will be a new email, download the object and follow the instructions in the email to set up email verification.

### Organisation

We want to create an AWS Organisation to allow all projects to be billed under our one base root account and for ease of delegating users to different projects.

### IAM

We will configure an IAM Role and an IAM Policy which will allow cross account access to our Route53 Hosted Zones and to access emails.

In the aws root account, we will deploy the `infra/base/iam.yaml` cloudformation template specifying parameters depending on the projects needs.

We will need to provide the `HostedZoneId` and `AccountId` for each of our different projects.

These can be gotten from the Organisation and Route53 interfaces.

#### Deleting our cloudformation base stacks

Before deleting the email cloudformation stack, you will need to:
+ empty the samhstn-email s3 bucket.
+ Disable the ses active rule set (visit https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules: to do so).

Now you should be able to delete the cloudformation templates without errors.

### New project

In the following steps we will create 2 new AWS users from our base root account:

+ the project root account, which can create project users
+ the admin account for that project which can assume roles accross accounts.

this will need to be done for each new project.

Say we would like to create a new project called `project_name`, we should do the following:

1. Create an aws account under the email address: `aws+project_name@samhstn.com`, this will be our project root account.
2. Look in the root account S3 bucket for email address valiation when signing up.
3. Add an `Organisational unit` for the project and add our newly created `aws+project_name@samhstn.com` user.
4. Create our admin user under `aws+project_name@samhstn.com` by deploying the stack `infra/base/project_iam.yaml`, name this stack `iam`
5. As our root account, we deploy our `infra/base/root_iam.yaml` cloudformation template which creates a role for our project admin users to assume, name this stack `project_name`
  Name this template as the name of the associated project.
6. For each infrastructure change to our project, we should operate under this `admin` user and assume either of the roles `Base` (for DNS configuration changes) or `Admin` (for project specific changes).

For the next steps, follow the instructions [here](../README.md)
