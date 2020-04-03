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

function mockEvent() {
  const crypto = require('crypto');

  const mockBody = {
    ref: 'refs/heads/dci#84',
    head_commit: {
      id: 'eb0b441a0d72c6ce213c481e640e97f00b62a048'
    }
  }

  const body = encodeURIComponent(`payload=${JSON.stringify(mockBody)}`);

  const hmac = crypto.createHmac('sha1', mockSecret);
  hmac.update(body, 'utf-8');
  const sha1 = hmac.digest('hex');

  return {
    headers: {
      'x-hub-signature': `sha1=${sha1}`
    },
    body: Buffer.from(body, 'utf-8').toString('base64')
  }
}

if (NODE_ENV === 'test') {
  if (AWS_SDK_LOAD_CONFIG === 'true') {
    exports.AWS = require('aws-sdk');
    exports.event = require('./test/production_event.json');
  } else {
    exports.AWS = { SecretsManager: SecretsManagerMock }
    exports.event = mockEvent();
  }
} else {
  // we don't need the event here as in production,
  // the lambda will be provided an event.
  exports.AWS = require('aws-sdk');
}
