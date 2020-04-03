'use strict';

const crypto = require('crypto');
const AWS = require('./aws.js');
const AWS_REGION = process.env.AWS_REGION || 'eu-west-1';

const secretsManager = new AWS.SecretsManager({region: AWS_REGION, apiVersion: '2017-10-17'});

exports.handler = async (event) => {
  console.log('event', event);

  let response;

  try {
    const secretValueReq = secretsManager.getSecretValue({SecretId: '/GithubSecret'});
    const {SecretString: githubSecret} = await secretValueReq.promise();
    const hmac = crypto.createHmac('sha1', githubSecret);
    const body = Buffer.from(event.body, 'base64').toString();
    hmac.update(body, 'utf-8');
    const digest = hmac.digest('hex');

    if (`sha1=${digest}` === event.headers['x-hub-signature']) {
      const payload = JSON.parse(decodeURIComponent(body).replace(/^payload=/, ''));

      console.log('payload', payload);

      // TODO handle process.env.GITHUB_MASTER_BRANCH

      response = {
        statusCode: 200,
        body: `Push from branch: ${event.ref}, commit: ${event.head_commit.id}`
      }
    } else {
      response = {
        statusCode: 500,
        body: 'Err: x-hub-signature mismatch'
      }
    }
  } catch (err) {
    response = {
      statusCode: 500,
      body: `Err: ${err}`
    }
  }

  return response;
}
