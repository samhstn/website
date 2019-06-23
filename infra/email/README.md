# Email

### Set up Email receiving

We will set up receiving emails for the `@samhstn.com` domain.

In the aws root account, we will configure a lambda function to log incoming emails by deploying the `infra/email/email.yaml` cloudformation template.

It will take 5 minutes for the route53 MX changes to propegate after the stack is deployed.

You will now need to set the SES ruleset to active.

To do this, go to: https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules:

and set `SamhstnRuleSet` as the `Active Rule Set`.

You will need to provide a notification email as a template parameter.

### Set up Email sending

In the aws console, visit: https://console.aws.amazon.com/ses/home?region=us-east-1#verified-senders-email:

Click `Verify a New Email Address`, then enter `noreply@samhstn.com` and the email address we would like to be notified on.

Now in the `samhstn-emails` s3 bucket, there will be a new email, download the object and follow the instructions in the email.

We will also need to follow the email verification instructions in our notification email address.

### Deleting email receiving stack

Before deleting the email cloudformation stack, you will need to:
+ empty the samhstn-email s3 bucket.
+ Disable the ses active rule set (visit https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules: to do so).

Then you can delete the cloudformation template without errors.
