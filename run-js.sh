#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

RLWRAP=rlwrap

gleam build --target javascript
$RLWRAP gleam run --target javascript
