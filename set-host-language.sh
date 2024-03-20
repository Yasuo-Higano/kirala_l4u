#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

unlink run
unlink build-target


while :
do
	case $1 in
		--js | --javascript)
			gleam add gleam_javascript
			gleam remove gleam_bbmustache
			ln -s run-js.sh run
			ln -s build-js.sh build-target
			
			;;
		
		--erl | --erlang)
			gleam remove gleam_javascript
			gleam add gleam_bbmustache
			ln -s run-erl.sh run
			ln -s build-erl.sh build-target
			;;
		*)
			break
			;;
	esac
	shift
done

gleam clean
./build-target
./run

