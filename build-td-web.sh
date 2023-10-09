#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev sed tar wget python3 python-is-python3 curl -y

cd /app
git clone https://github.com/tdlib/td.git && git clone https://github.com/emscripten-core/emsdk.git && cd /app/emsdk && git checkout tags/3.1.1

./emsdk install 3.1.1 && ./emsdk activate 3.1.1 && source ./emsdk_env.sh

cd /app/td/example/web
./build-openssl.sh
./build-tdlib.sh
./copy-tdlib.sh
./build-tdweb.sh
