#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

unlink run


while :
do
	case $1 in
		--js | --javascript)
			gleam add gleam_javascript
			ln -s run-js.sh run
			;;
		
		--erl | --erlang)
			gleam remove gleam_javascript
			ln -s run-erl.sh run
			;;
		*)
			break
			;;
	esac
	shift
done

gleam clean
./build.sh
./run

