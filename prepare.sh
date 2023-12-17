#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

gleam clean
rm -rf ./build

gleam add gleam_stdlib
#gleam add gleam_javascript

# -------------------------
gleam add qdate
gleam add jsone


