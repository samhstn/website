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

exports.logger =
  NODE_ENV === 'test'
    ? { write: function () {} }
    : { write: console.log }

exports.AWS =
  NODE_ENV === 'test' && AWS_SDK_LOAD_CONFIG !== 'true'
    ? { SecretsManager: SecretsManagerMock }
    : require('aws-sdk');

exports.AWS_REGION = process.env.AWS_REGION || 'eu-west-1'; 
exports.API_VERSION = '2017-10-17';
