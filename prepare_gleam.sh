#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
cd $SCRIPT_DIR

WORK_DIR=/usr/local/src
cd $WORK_DIR

#VER='v0.32.4'
VER='v0.33.0-rc1'
ARCH=$(uname -m)

apt update
apt install -y wget
apt install -y python3-pip
apt install -y postgresql-client
apt install -y vim tmux ranger
apt install -y nkf
apt install -y expect # for unbuffer
apt install -y cpulimit
apt install -y apt install curl git
apt install -y apt install rlwrap

# asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1

apt-get install -y locales
localedef -f UTF-8 -i ja_JP ja_JP.UTF-8
localedef -f UTF-8 -i en_US en_US.UTF-8

# rebar3
wget https://s3.amazonaws.com/rebar3/rebar3 && chmod +x rebar3
mv rebar3 /usr/local/bin/

OS=unknown-linux-musl
if [ "$(uname)" == 'Darwin' ]; then
  OS=apple-darwin
fi


# gleam
case "$ARCH" in
  "arm64" | "aarch64")
        wget https://github.com/gleam-lang/gleam/releases/download/${VER}/gleam-${VER}-aarch64-$OS.tar.gz
        tar xvf gleam-${VER}-aarch64-$OS.tar.gz
        ;;

    x86_64)
        wget https://github.com/gleam-lang/gleam/releases/download/${VER}/gleam-${VER}-x86_64-$OS.tar.gz
        tar xvf gleam-${VER}-x86_64-$OS.tar.gz
        ;;

    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

#mv gleam /usr/local/bin/
GLEAM="`which gleam`"
if [ -z "$GLEAM" ]; then
  mv gleam /usr/local/bin/
else
  mv gleam $GLEAM
fi


$SCRIPT_DIR/install_elixir.sh
