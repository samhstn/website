# Teardown

### Samhstn project

##### Clear setup as admin user

Empty all buckets.
Delete all cloudformation templates.

##### Clear admin user

We will only be able to log in as aws+samhstn@samhstn.com after this!

Visit [S3](https://console.aws.amazon.com/s3/home?region=us-east-1#) and remove the samhstn-cfn-templates bucket

### Samhstn root

##### Email

This will delete 

1. Empty the samhstn-email s3 bucket.
2. Disable the ses active rule set (by visiting https://console.aws.amazon.com/ses/home?region=us-east-1#receipt-rules:).
3. Delete the `email` cloudformation template

##### IAM

Delete project specific cloudformation stack.
