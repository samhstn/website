'use strict';

const ping = {
  headers: {
    'x-github-event': 'ping'
  },
  body: {
    zen: 'Practicality+beats+purity.'
  }
};

const push = {
  headers: {
    'x-github-event': 'push'
  },
  body: {
    ref: 'refs/heads/dci#84',
    head_commit: {
      id: '90aa35428f689dbeff1a59b010be25420fa6fdd4'
    }
  }
};

module.exports = { ping, push };
