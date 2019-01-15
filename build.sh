#!/bin/bash

set -e

SAMHSTN_ROOT="$(pwd)"

PATH="$PATH:$SAMHSTN_ROOT/node_modules/.bin"

npm run build:css

npm run build:elm -- --optimize

# adapted from https://guide.elm-lang.org/optimization/asset_size.html
browserify src/js/app.js |
uglifyjs --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' |
uglifyjs --mangle --output=static/script.js

SAMHSTN_CSS="style-$(md5 -q static/style.css).min.css"
SAMHSTN_JS="script-$(md5 -q static/script.js).min.js"

mv static/style.css "static/$SAMHSTN_CSS"
mv static/script.js "static/$SAMHSTN_JS"

echo ""
echo "$(echo static/style-*.min.css) size: $(cat static/style-*.css | wc -c) bytes"
echo "$(echo static/script-*.min.js) size: $(cat static/script-*.js | wc -c) bytes"

echo ""
echo "building new index.html"

cat src/index.html | sed "s/style\.css/$SAMHSTN_CSS/" | sed "s/script\.js/$SAMHSTN_JS/" > static/index.html
