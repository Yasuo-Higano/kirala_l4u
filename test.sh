#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

#./prepare.sh
clear

#COLORIZE="| python3 colorize.py"
COLORIZE="" 

while :
do
    case $1 in
        0)   
            STEP=step0_repl python3 runtest.py --deferrable --optional ./scripts/tests/step0_repl.mal -- ./run
            ;;
        1)
            STEP=step1_read_print python3 runtest.py --deferrable --optional ./scripts/tests/step1_read_print.mal -- ./run
            ;;
        2)
            python3 runtest.py --deferrable --optional ./scripts/tests/step2_eval.mal -- ./run $COLORIZE
            ;;
        3)
            python3 runtest.py --deferrable --optional ./scripts/tests/step3_env.mal -- ./run $COLORIZE
            ;;
        4)
            python3 runtest.py --deferrable --optional ./scripts/tests/step4_if_fn_do.mal -- ./run $COLORIZE
            ;;
        5)
            python3 runtest.py --deferrable --optional ./scripts/tests/step5_tco.mal -- ./run $COLORIZE
            ;;
        6)
            python3 runtest.py --deferrable --optional ./scripts/tests/step6_file.mal -- ./run $COLORIZE
            ;;
        7)
            python3 runtest.py --deferrable --optional ./scripts/tests/step7_quote.mal -- ./run $COLORIZE
            ;;
        8)
            python3 runtest.py --deferrable --optional ./scripts/tests/step8_macros.mal -- ./run $COLORIZE
            ;;
        9)
            python3 runtest.py --deferrable --optional ./scripts/tests/step9_try.mal -- ./run $COLORIZE
            ;;
        a | A)
            python3 runtest.py --deferrable --optional ./scripts/tests/stepA_mal.mal -- ./run $COLORIZE
            ;;
        *)
            break
            ;;
    esac
    shift
done

# ['../../runtest.py', '--deferrable', '--optional', '../tests/step6_file.l4u', '--', '../elixir/run']



