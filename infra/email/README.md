# Email

We will set up receiving emails for the `@samhstn.com` domain.

In the aws root account, we will configure a lambda function to log incoming emails by deploying the `infra/email/email.yaml` cloudformation template.

It will take 5 minutes for the route53 MX changes to propegate after the stack is deployed.

You may need to set the SES ruleset to active.
