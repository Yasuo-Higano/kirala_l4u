#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

PROJECT=$(basename $PWD)

#chown -R 1000:1000 ./*

#DRYRUN=--dry-run

cd ..
rsync $DRYRUN -uavz --copy-links --delete ./$PROJECT ~/MyGitHub/ \
--exclude='_archive' \
--exclude='.asdf' \
--exclude='.clj-kondo' \
--exclude='.git' \
--exclude='.github' \
--exclude='.lsp' \
--exclude='.vscode' \
--exclude='.bash_history' \
--exclude='.bashrc' \
--exclude='.l4u-history' \
--exclude='.local_bash_history' \
--exclude='.run-erl.sh_history' \
--exclude='.tarignore' \
--exclude='.viminfo' \
--exclude='.wget-hsts' \
--exclude='install_elixir.sh' \
--exclude='build' \
--exclude='node_modules' \
--exclude='dist' \
--exclude='ldb.zip' \
--exclude='aws' \
--exclude='data' \
--exclude='myldb' \
--exclude='myldb_old' \
--exclude='hd2-*' \
--exclude='company_men' \
--exclude='health-*' \
--exclude='output/*' \
--exclude='__pycache__' \
--exclude='pyenv' \
--exclude='pyvenv' \
--exclude='*.o' \
--exclude='*.so' \
--exclude='*.dump' \
--exclude='*.tar.gz'
