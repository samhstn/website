'use strict';

require('./style.css');

var Elm = require('./Main.elm').Elm;

Elm.Main.init({
  node: document.getElementById('main')
});
