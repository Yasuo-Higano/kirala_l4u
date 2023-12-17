#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

RLWRAP=rlwrap

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
        $RLWRAP ./run-js.sh
        exit 0
      ;;
    "--erl" | "--erlang")
        $RLWRAP ./run-erl.sh
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