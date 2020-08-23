const {handler} = require('../webhook.js');
const {AWS, AWS_REGION, API_VERSION, payload, genEvent} = require('../config.js');
const test = require('tape');

test('valid event', async (t) => {
  const secretsManager = new AWS.SecretsManager({region: AWS_REGION, apiVersion: API_VERSION});
  const secretValueReq = secretsManager.getSecretValue({SecretId: '/GithubSecret'});
  const { SecretString } = await secretValueReq.promise();

  const event = genEvent(SecretString, payload);

  const response = await handler(event);
  const expected = {
    statusCode: 200,
    body: `Push from branch: refs/heads/dci#84, commit: eb0b441a0d72c6ce213c481e640e97f00b62a048`
  };

  t.deepEqual(response, expected);
  t.end()
});

test('x-hub-signature mismatch', async (t) => {
  const event = genEvent('mismatchedSecretString', payload);

  const response = await handler(event);
  const expected = {
    statusCode: 500,
    body: 'Err: x-hub-signature mismatch'
  };

  t.deepEqual(response, expected);
  t.end()
});
