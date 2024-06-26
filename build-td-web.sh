#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install tree make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev sed tar wget python3 python-is-python3 curl -y

cd /app
git clone https://github.com/tdlib/td.git && git clone https://github.com/emscripten-core/emsdk.git && cd /app/emsdk

cd /app/emsdk
./emsdk install latest && ./emsdk activate latest && source ./emsdk_env.sh

cd /app/td/example/web

sed -i 's/emmake make depend || exit 1/emmake make -j $(nproc) depend || exit 1/g' build-openssl.sh
sed -i 's/emmake make -j 4 || exit 1/emmake make -j $(nproc) || exit 1/g' build-openssl.sh

sed -i 's/cmake --build build\/generate --target prepare_cross_compiling || exit 1/cmake --build build\/generate --target prepare_cross_compiling -- -j $(nproc) || exit 1/g' build-tdlib.sh
sed -i 's/cmake --build build\/wasm --target td_wasm || exit 1/cmake --build build\/wasm --target td_wasm -- -j $(nproc) || exit 1/g' build-tdlib.sh
# sed -i 's/cmake --build build\/asmjs --target td_asmjs || exit 1/cmake --build build\/asmjs --target td_asmjs -- -j $(nproc) || exit 1/g' build-tdlib.sh

# Removing asmjs building
sed -i '/console\.log('\''loadTdlibAsmjs'\'');/,/return module;/d' tdweb/src/worker.js
sed -i '/import td_asmjs_mem_release from '\''\.\/prebuilt\/release\/td_asmjs\.js\.mem'\'';/d' tdweb/src/worker.js

sed -i '/cmake --build build\/asmjs --target td_asmjs || exit 1/d' build-tdlib.sh 
sed -i 's/cp build\/asmjs\/td_asmjs.js build\/asmjs\/td_asmjs.js.mem $DEST || exit 1/cp build\/asmjs\/td_asmjs.js $DEST || exit 1/' copy-tdlib.sh 

# sed -i '/npm run build || exit 1/a npm pack' build-tdweb.sh

chmod +x build-openssl.sh build-tdlib.sh build-tdweb.sh

./build-openssl.sh
./build-tdlib.sh
tree /app/td/example/web/build -h 
./copy-tdlib.sh
./build-tdweb.sh
