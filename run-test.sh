#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

NN=$1

if [ $# -ne 1 ]; then
    echo "Usage: $0 <test-id>"
    echo "test-id: 2, 3, 4, 5, 6, 7, 8, 9, a"
    exit 1
fi

#COLORIZE="| python3 colorize.py"
COLORIZE=""

# # script -c "your_command" -q /dev/null >> output.txt
# ./test.sh $NN > result-$NN.txt
# #script -c "./test.sh $1" -q /dev/null >> result-$1.txt
# 
# #./test.sh $1 >> result-$1.txt
# cat result-$NN.txt $COLORIZE
# #cat result-$1.txt

./test.sh $NN