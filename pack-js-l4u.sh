#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

cp pack-js-package.json build/dev/javascript/package.json

cd build/dev/javascript
rmdir -rf ./dist

npm install mustache
##npm install readline
##npm install path
##npm install fs
##npm install child_process


while :
do
  case "$1" in
    "--parcel")
        npm install --save-dev parcel
        npx parcel build
      ;;
    "--esbuild-web")
        npm install --save-exact --save-dev esbuild
        ./node_modules/.bin/esbuild kirala_l4u/kirala_l4u.mjs --bundle --outfile=_dist/esl4u-web.js
        exit 0
      ;;
    "--esbuild-node")
        npm install --save-exact --save-dev esbuild
        ./node_modules/.bin/esbuild kirala_l4u/kirala_l4u.mjs --bundle --outfile=_dist/esl4u-node.js --platform=node
        exit 0
      ;;
    *)
    echo "Usage: $0 [--parcel] [--esbuild-web] [--esbuild-node]"
      break
      ;;
  esac
  shift
done




#cat prelude.mjs _dist/_l4u.mjs > _dist/l4u.mjs
