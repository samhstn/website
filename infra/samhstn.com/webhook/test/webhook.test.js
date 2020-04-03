const {handler} = require('../webhook.js');
const event = require('./event.json');
const test = require('tape');

test('valid event', async (t) => {
  const response = await handler(event);
  const expected = {
    statusCode: 200,
    body: `Push from branch: ${event.ref}, commit: ${event.head_commit.id}`
  };

  t.deepEqual(response, expected);
  t.end()
});
