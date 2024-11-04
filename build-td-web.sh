#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install tree make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev sed tar wget python3 python-is-python3 bzip2 xz-utils curl -y

cd /app
git clone https://github.com/tdlib/td.git && git clone https://github.com/emscripten-core/emsdk.git && cd /app/emsdk

cd /app/emsdk
./emsdk install latest && ./emsdk activate latest && source /app/emsdk/emsdk_env.sh

cd /app/td/example/web
sed -i '1isource /app/emsdk/emsdk_env.sh' build-openssl.sh
sed -i 's/emmake make depend || exit 1/emmake make -j $(nproc) depend || exit 1/g' build-openssl.sh
sed -i 's/emmake make -j 4 || exit 1/emmake make -j $(nproc) || exit 1/g' build-openssl.sh

sed -i '1isource /app/emsdk/emsdk_env.sh' build-tdlib.sh
sed -i 's/cmake --build build\/generate --target prepare_cross_compiling || exit 1/cmake --build build\/generate --target prepare_cross_compiling -- -j $(nproc) || exit 1/g' build-tdlib.sh
sed -i 's/cmake --build build\/wasm --target td_wasm || exit 1/cmake --build build\/wasm --target td_wasm -- -j $(nproc) || exit 1/g' build-tdlib.sh
sed -i 's/cmake --build build\/asmjs --target td_asmjs || exit 1/cmake --build build\/asmjs --target td_asmjs -- -j $(nproc) || exit 1/g' build-tdlib.sh

# Removing td_asmjs.mem related contents from worker.js
sed -i '/console\.log('\''loadTdlibAsmjs'\'');/,/return module;/d' tdweb/src/worker.js
sed -i '/import td_asmjs_mem_release from '\''\.\/prebuilt\/release\/td_asmjs\.js\.mem'\'';/d' tdweb/src/worker.js

# Don't build asmjs target
sed -i '/cmake --build build\/asmjs --target td_asmjs -- -j $(nproc) || exit 1/d' build-tdlib.sh 
sed -i '/cp build\/asmjs\/td_asmjs.js build\/asmjs\/td_asmjs.js.mem $DEST || exit 1/d' copy-tdlib.sh 

# add babel plugins 
sed -i '/cd tdweb || exit 1/a \
npm i @babel/plugin-proposal-optional-chaining@7.8.3 --save-dev\
npm i @babel/plugin-proposal-logical-assignment-operators@7.8.3 --save-dev\
npm i @babel/plugin-proposal-nullish-coalescing-operator@7.8.3 --save-dev' build-tdweb.sh

cd /app/td/example/web/tdweb
# removes exclude: /prebuilt/ from babel-loader rule and add presets and plugins parameters in options
sed -z 's/\(\s*exclude: \/prebuilt\/,\n\s*include: \[path\.resolve(__dirname, '\''src'\'')\],\)/include: [path.resolve(__dirname, '\''src'\'')],/' webpack.config.js >> webpack.config.js1 && rm -r webpack.config.js && mv webpack.config.js1 webpack.config.js
sed -z 's/\(loader: require\.resolve(\x27babel-loader\x27)\)/\1,options: {presets: [\x27@babel\/preset-env\x27], plugins:[\x22@babel\/plugin-proposal-optional-chaining\x22, \x22@babel\/plugin-proposal-logical-assignment-operators\x22, \x22@babel\/plugin-proposal-nullish-coalescing-operator\x22]}/' webpack.config.js >> webpack.config.js1 && rm -r webpack.config.js && mv webpack.config.js1 webpack.config.js

cd /app/td/example/web
# sed -i '/npm run build || exit 1/a npm pack' build-tdweb.sh
chmod +x build-openssl.sh build-tdlib.sh build-tdweb.sh copy-tdlib.sh

export NODE_OPTIONS=--openssl-legacy-provider

./build-openssl.sh
./build-tdlib.sh
./copy-tdlib.sh
./build-tdweb.sh
