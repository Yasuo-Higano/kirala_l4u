#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

clear
./embed_resource.sh

gleam build --target erlang

