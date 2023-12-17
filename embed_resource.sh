#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

cat scripts/init0.lisp scripts/init.lisp > temp.lisp

python3 embed_resource_to_erl.py \
    --output-erl src/l4u@resources.erl \
    --output-js  src/l4u_resources.mjs \
    --resource default0.lisp,temp.lisp \
    --resource default1.lisp,scripts/init1.lisp

rm temp.lisp
