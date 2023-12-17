#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

MOD_PROMPT=""

#gleam build --target erlang

#    -pa build/dev/erlang/*/ebin $@
#    -pa build/dev/erlang/$APPNAME/ebin $@
#    -eval 'shell:prompt_func({rl_erl_prompt, prompt_func}).' \
#LANG=ja_JP.UTF-8 LC_CTYPE=ja_JP.UTF-8 erl \
erl \
    +pc unicode \
    -Application kernel stdlib crypto public_key asn1 ssl \
    -kernel shell_history enabled \
    -pa build/dev/erlang/*/ebin \
    -noshell \
    -s kirala_l4u main \
    $@