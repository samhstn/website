const crypto = require('crypto');

const genEvent = (secret) => (event) => {
  const bodyEncoded = encodeURIComponent(`payload=${JSON.stringify(event.body)}`);

  const body = Buffer.from(bodyEncoded, 'utf-8').toString('base64')

  const hmac = crypto.createHmac('sha1', secret);
  hmac.update(bodyEncoded, 'utf-8');
  const sha1 = hmac.digest('hex');

  const headers = Object.assign(event.headers, {'x-hub-signature': `sha1=${sha1}`});

  return Object.assign(event, {body, headers});
}

module.exports = genEvent;
