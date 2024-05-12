#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install make git zlib1g-dev libssl-dev gperf cmake clang libc++-dev libc++abi-dev -y

cd /app
git clone --recursive https://github.com/tdlib/telegram-bot-api.git

cd /app/telegram-bot-api
mkdir build
cd build

CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang CXX=/usr/bin/clang++ cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. ..
cmake --build . --target install
