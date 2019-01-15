const path = require('path');
const express = require('express');
const app = express();
const port = 3000;

app.use('/static', express.static('static'));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'static', 'index.html'));
});

app.listen(port, () => {
  console.log(`Example app running on http://localhost:${port}`); // eslint-disable-line no-console
});
