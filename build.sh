#!/bin/bash

set -e

echo "Building for production..."

PATH="$PATH:$(pwd)/node_modules/.bin"

# taken from https://guide.elm-lang.org/optimization/asset_size.html
uglifyjs script.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' |
uglifyjs --mangle --output=static/_script.js

SAMHSTN_CSS="style-$(md5 -q static/style.css).min.css"
SAMHSTN_JS="script-$(md5 -q static/_script.js).min.js"

cp static/style.css "static/$SAMHSTN_CSS"
mv static/_script.js "static/$SAMHSTN_JS"

echo ""
echo "$(echo static/style-*.min.css) size: $(cat static/style-*.css | wc -c) bytes"
echo "$(echo static/script-*.min.js) size: $(cat static/script-*.js | wc -c) bytes"

echo ""
echo "building new index.html"

cat src/index.html | sed "s/style\.css/$SAMHSTN_CSS/" | sed "s/script\.js/$SAMHSTN_JS/" > static/index.html
