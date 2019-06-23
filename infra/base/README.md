# Base

We have one master user who delegates permissions to all other users and is in charge of the billing for all projects.

This user will deploy 2 cloudformation templates.

The first is the set up of `@samhstn.com` email addresses which will be used for each project.

The second is to configure the different base iam permissions for each project admin user.

### Email

We will set up receiving emails for the `@samhstn.com` domain.

In the aws root account, we will configure a lambda function to log incoming emails by deploying the `infra/base/email.yaml` cloudformation template.

It may take up to 5 minutes for the route53 MX changes to propegate after the stack is deployed.

Next, you will now need to set the SES ruleset to active.

To do this, go to: https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules:

and set `SamhstnRuleSet` as the `Active Rule Set`.

You will need to provide a notification email as a template parameter.

Next we will set up email notifications whenever we receive an email.

In the aws console, visit: https://console.aws.amazon.com/ses/home?region=us-east-1#verified-senders-email:

Click `Verify a New Email Address`, then enter `noreply@samhstn.com` and the email address we would like to be notified on.

Now in the `samhstn-emails` s3 bucket, there will be a new email, download the object and follow the instructions in the email.

We will also need to follow the email verification instructions in our notification email address.

#### Deleting the email stack

Before deleting the email cloudformation stack, you will need to:
+ empty the samhstn-email s3 bucket.
+ Disable the ses active rule set (visit https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules: to do so).

Now you should be able to delete the cloudformation template without errors.

### Organisation

With our Email stack deployed, we now want to create an AWS Organisation - this will allow billing from under one account and the easy delegating of users to different projects.

We will create one `Organisational unit` per project and a separate `aws+project_name@samhstn.com` admin user for each project.

### IAM

We are going to configure an IAM Role and an IAM Policy which will allow cross account access to our Route53 Hosted Zones.

In the aws root account, we will deploy the `infra/base/iam.yaml` cloudformation template.

We will need to provide the `HostedZoneId`s and `UserId`s for each of our different projects.

These can be gotten from the Organisation and Route53 interfaces.
