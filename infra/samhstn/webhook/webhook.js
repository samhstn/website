'use strict';

const crypto = require('crypto');
const {AWS, AWS_REGION, API_VERSION} = require('./config.js');

const secretsManager = new AWS.SecretsManager({region: AWS_REGION, apiVersion: API_VERSION});

exports.handler = async (event) => {
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

      // TODO: handle process.env.GITHUB_MASTER_BRANCH

      response = {
        statusCode: 200,
        body: `Push from branch: ${payload.ref}, commit: ${payload.head_commit.id}`
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
