const {handler} = require('../webhook.js');
const {event} = require('../config.js');
const test = require('tape');

test('valid event', async (t) => {
  const response = await handler(event);
  const expected = {
    statusCode: 200,
    body: `Push from branch: refs/heads/dci#84, commit: eb0b441a0d72c6ce213c481e640e97f00b62a048`
  };

  t.deepEqual(response, expected);
  t.end()
});
