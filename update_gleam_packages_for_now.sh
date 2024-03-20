#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
START_DIR=$(pwd)

for dir in $START_DIR/build/packages/*
do
    if [ -d "$dir" ] && [ -f "$dir/rebar.config" ]; then
        sed -i 's/warnings_as_errors,*//g' "$dir/rebar.config"
    fi

    if [ -d "$dir" ] && [ -f "$dir/gleam.toml" ]; then
        echo "- $dir"
        cd "$dir"
        gleam clean
        gleam fix
        gleam update
        $SCRIPT_DIR/update_gleam_packages_for_now.sh
    else
        continue
    fi
done

