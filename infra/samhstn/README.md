# Master billing account/root configuration

Our root account user delegates permissions to all other project specific root users and is in charge of the billing for all projects.

To configure this, we will deploy 2 cloudformation templates:

1. Facilitates the creation of `@samhstn.com` email addresses which will be used as the root user for each project. (e.g. aws+<projectname>@samhstn.com or aws+samhstn@samhstn.com)
2. Configures the iam permissions for each project root user.

### 1. Email

We will set up receiving emails for the `@samhstn.com` domain.

+ Deploy the `infra/root/email.yaml` cloudformation template.
+ Provide an email to receive email notifications on as a template parameter, then create the stack.
+ Go to the ses console and in the domains identity management tab, click on the samhstn.com domain, then Verify a New Domain. Add the relevant MX and TXT records.
+ Next, we need to set `SamhstnRuleSet` as the active SES ruleset.
+ We will verify a New Email Address and enter `hello@samhstn.com` and the email address we specified as our template parameter.
+ In the `samhstn-emails` s3 bucket, there will be a new email, download the object and follow the instructions in the email to set up email verification.

(This may take up to 5 minutes for the route53 MX record set changes to propegate after the stack is deployed and 30 mins for the route53 TXT record set changes to propegate).

### 2. IAM

We will configure an IAM Role and an IAM Policy which will allow cross account access to our Route53 Hosted Zones and to access emails.

In the aws root account, we will deploy the `infra/root/iam.yaml` cloudformation template specifying parameters depending on the projects needs.

We will need to provide the `HostedZoneId` and `AccountId` for each of our different projects.

### Organisation

We want to create an AWS Organisation to allow all projects to be billed under our one root account and for ease of delegating users to different projects.

### New project

In the following steps we will create 2 new AWS users for a new project:

+ the project root account, which can create project users
+ the admin account for that project which can assume roles accross accounts.

this will need to be done for each new project.

Say we would like to create a new project called `projectname`, we should do the following:

1. Create an aws account under the email address: `aws+projectname@samhstn.com`, this will be our project root account.
2. Look in the root account S3 bucket for email address valiation when signing up.
3. Add an `Organisational unit` for the project and add our newly created `aws+projectname@samhstn.com` user.
4. Create our admin user under `aws+projectname@samhstn.com` by deploying the stack `infra/root/project-iam.yaml`, name this stack `iam`
5. As our root account, we deploy our `infra/root/root-iam.yaml` cloudformation template which creates a role for our project admin users to assume, name this stack `projectname`
  Name this template as the name of the associated project.
6. For each infrastructure change to our project, we should operate under this `admin` user and assume either of the roles `Root` (for DNS configuration changes) or `Admin` (for project specific changes).
