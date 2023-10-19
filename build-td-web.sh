#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev sed tar wget python3 python-is-python3 curl -y

cd /app
git clone https://github.com/tdlib/td.git && git clone https://github.com/emscripten-core/emsdk.git && cd /app/emsdk && git checkout tags/3.1.1

cd /app/emsdk
./emsdk install 3.1.1 && ./emsdk activate 3.1.1 && source ./emsdk_env.sh

cd /app/td/example/web
sed -i 's/emmake make depend || exit 1/emmake make -j $(nproc) depend || exit 1/g' build-openssl.sh
sed -i 's/emmake make -j 4 || exit 1/emmake make -j $(nproc) || exit 1/g' build-openssl.sh

sed -i 's/cmake --build build\/generate --target prepare_cross_compiling || exit 1/cmake --build build\/generate --target prepare_cross_compiling -- -j $(nproc) || exit 1/g' build-tdlib.sh
sed -i 's/cmake --build build\/wasm --target td_wasm || exit 1/cmake --build build\/wasm --target td_wasm -- -j $(nproc) || exit 1/g' build-tdlib.sh
sed -i 's/cmake --build build\/asmjs --target td_asmjs || exit 1/cmake --build build\/asmjs --target td_asmjs -- -j $(nproc) || exit 1/g' build-tdlib.sh

chmod +x build-openssl.sh build-tdlib.sh

./build-openssl.sh
./build-tdlib.sh
./copy-tdlib.sh
./build-tdweb.sh
