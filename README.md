# samhstn.com

[samhstn.com](http://samhstn.com)

### What

My personal website

### Quick start

```bash
# clone the repo
git clone https://github.com/samhstn/samhstn.git && cd samhstn
# install the dependencies
npm install
# start the development server and watch for changes to static assets
npm run watch
# your development server should be running on `http://localhost:3000`
```

### Building locally for production

```bash
# clone the repo
git clone https://github.com/samhstn/samhstn.git && cd samhstn
# install the dependencies
npm install --production
# compile the static assets
npm run build
# you should have the following assets in your `static` directory
# index.html
# script-*.min.js
# style-*.min.css
# (these can be served locally with `npm start`)
```

### AWS

Services used:

+ Cloudformation
+ Route53
+ Lambda
+ Apigateway
+ S3
+ IAM
+ ACM

##### Setup

###### Domain

Ensure you have purchased a domain in AWS using: https://console.aws.amazon.com/route53

###### Configure AWS CLI

In the `IAM` web view:

+ Create a user called `admin` with programmatic access.
+ Add it to a group called `Admin` with `AdministratorAccess`.

In your command line, run: `aws configure` and fill in the credentials.

###### Running setup script

Ensure you have uploaded the `infra/github_webhook.js` file to s3.

This can be achieved with:

```bash
(cd infra && zip github_webhook.zip github_webhook.js)
aws s3 mb s3://samhstn
aws s3 cp infra/github_webhook.zip s3://samhstn
```

Create a secret to configure github and aws and place it in a file called `.secret` by running the following command:

```bash
node -e "console.log(require('crypto').randomBytes(20).toString('base64'));" > .secret
```

Deploy the cloudformation template:

```bash
aws cloudformation create-stack --stack-name samhstn-base --template-body file://infra/base.yml --capabilities CAPABILITY_NAMED_IAM --parameters "ParameterKey=Secret,ParameterValue=$(cat .secret)"
```

Once completed, we will need to configure a webhook in our github repository.

The `Payload URL` can be obtained by running:

```bash
echo "https://$(aws apigateway get-rest-apis --query 'items[?name==`github_webhook`] | [0].id' --output text).execute-api.eu-west-1.amazonaws.com/prod/github_webhook"
```

The `Content type` is `application/json`

The Secret will be the output of:

```bash
cat .secret
```
