'use strict';

const {AWS_SDK_LOAD_CONFIG, NODE_ENV} = process.env;
const mockSecret = 'S8UVDlEXAMPLE';

class SecretsManagerMock {
  getSecretValue({SecretId: _SecretId}) {
    return {
      promise: () => Promise.resolve({SecretString: mockSecret})
    }
  }
}

function genEvent(secret, payload) {
  const crypto = require('crypto');
  const bodyEncoded = encodeURIComponent(`payload=${JSON.stringify(payload.body)}`);

  const body = Buffer.from(bodyEncoded, 'utf-8').toString('base64')

  const hmac = crypto.createHmac('sha1', secret);
  hmac.update(bodyEncoded, 'utf-8');
  const sha1 = hmac.digest('hex');

  const headers = Object.assign(payload.headers, {'x-hub-signature': `sha1=${sha1}`});

  return Object.assign(payload, {body, headers});
}

if (NODE_ENV === 'test') {
  exports.genEvent = genEvent;
  if (AWS_SDK_LOAD_CONFIG === 'true') {
    exports.AWS = require('aws-sdk');
    exports.payload = require('./test/push_payload.json');
  } else {
    exports.AWS = { SecretsManager: SecretsManagerMock }
    exports.payload = {
      headers: {},
      body: {
        ref: 'refs/heads/dci#84',
        head_commit: {
          id: 'eb0b441a0d72c6ce213c481e640e97f00b62a048'
        }
      }
    }
  }
} else {
  // we don't need the payload here as in production,
  // the lambda will be provided an event.
  exports.AWS = require('aws-sdk');
}

exports.AWS_REGION = process.env.AWS_REGION || 'eu-west-1'; 
exports.API_VERSION = '2017-10-17';
exports.SecretsManagerMock = SecretsManagerMock;
