'use strict';

class SecretsManager {
  getSecretValue({SecretId}) {
    return {
      promise: () => Promise.resolve({SecretString: 'S8UVDlEx6EXAMPLE'})
    }
  }
}

if (process.env.AWS_SDK_LOAD_CONFIG === 'true') {
  module.exports = require('aws-sdk');
} else {
  module.exports = { SecretsManager }
}
