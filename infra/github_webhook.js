const crypto = require('crypto');

exports.handler = (event, context, cb) => {
  const shasum = crypto.createHmac('sha1', process.env.SECRET);
  const digest = shasum.update(JSON.stringify(event.body)).digest('hex');

  if (`sha1=${digest}`.trim() === event.signature.trim()) {
    cb(false, 'ok');
  } else {
    cb(true, 'signature does not match digest');
  }

}
