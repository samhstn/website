exports.handler = (event, context, cb) => {
  console.log('event', event);
  console.log('context', context);

  cb(null, 'Hello world');
}
