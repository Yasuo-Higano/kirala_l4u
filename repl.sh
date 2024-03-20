#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

RLWRAP="rlwrap --history-filename=.l4u-history --file=lisp.completion --always-readline --no-children"

#while :
#do
#  case "$1" in
#    "--js" | "--javascript")
#        echo "# build for javascript"
#        gleam build --target javascript
#        $RLWRAP gleam run --target javascript
#        exit 0
#      ;;
#    *)
#      break
#      ;;
#  esac
#  shift
#done
#
#
#gleam build --target erlang
#$RLWRAP gleam run --target erlang


while :
do
  case "$1" in
    "--js" | "--javascript")
        gleam build --target javascript
        $RLWRAP gleam run --target javascript
        exit 0
      ;;
    "--erl" | "--erlang")
        gleam build --target erlang
        $RLWRAP gleam run --target erlang
        exit 0
      ;;
    *)
      break
      ;;
  esac
  shift
done

# default erlang shell
$RLWRAP ./run-erl.sh