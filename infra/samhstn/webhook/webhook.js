'use strict';

const crypto = require('crypto');
const {AWS, AWS_REGION, API_VERSION, logger} = require('./config.js');

const secretsManager = new AWS.SecretsManager({region: AWS_REGION, apiVersion: API_VERSION});

exports.handler = async (event) => {
  let response;

  try {
    const secretValueReq = secretsManager.getSecretValue({SecretId: '/GithubSecret'});
    const {SecretString: githubSecret} = await secretValueReq.promise();
    const hmac = crypto.createHmac('sha1', githubSecret);
    const bodyString = Buffer.from(event.body, 'base64').toString();
    hmac.update(bodyString, 'utf-8');
    const digest = hmac.digest('hex');

    if (`sha1=${digest}` === event.headers['x-hub-signature']) {
      if (event.headers['x-github-event'] === 'push') {
        const body = JSON.parse(decodeURIComponent(bodyString).replace(/^payload=/, ''));
        const branch = body.ref.replace(/\/refs\/heads\//, '');

        // TODO: handle process.env.GITHUB_MASTER_BRANCH

        response = {
          statusCode: 200,
          body: `${sample}Push from branch: ${branch}, commit: ${body.head_commit.id}`
        }
      } else if (event.headers['x-github-event'] === 'ping') {
        response = {
          statusCode: 200,
          body: 'OK'
        }
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

  if (event.sample) {
    Object.assign(response, {sample: true});
  }

  logger.write(response);

  return response;
}
