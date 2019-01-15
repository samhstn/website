const tape = require('tape');
const githubWebhook = require('./github_webhook.js').handler;
const { payload, headers } = require('./mock_data/index.js');
const fs = require('fs');
const path = require('path');

if (!process.env.SECRET) {
  process.env.SECRET = fs.readFileSync(
    path.join(__dirname, '..', '.secret'),
    'utf8'
  ).trim();
}

tape('handler with correct event responds with "ok"', (t) => {
  githubWebhook({ body: payload, headers }, {}, (err, res) => {
    t.notOk(err);
    t.equal(res, 'ok');

    t.end();
  });
});

tape('handler with incorrect event responds with err', (t) => {
  githubWebhook({ body: {payload, a: 1}, headers }, {}, (err, res) => {
    t.ok(err);
    t.equal(res, 'signature does not match digest');

    t.end();
  });
});
