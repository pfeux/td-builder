#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake clang-14 libc++-dev libc++abi-dev -y

cd /app
git clone https://github.com/tdlib/td.git

cd /app/td
rm -rf build && mkdir build && cd build

CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang-14 CXX=/usr/bin/clang++-14 cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=../tdlib -DTD_ENABLE_LTO=ON -DCMAKE_AR=/usr/bin/llvm-ar-14 -DCMAKE_NM=/usr/bin/llvm-nm-14 -DCMAKE_OBJDUMP=/usr/bin/llvm-objdump-14 -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-14 ..
cmake --build . --target install

ls -alh /app/td/tdlib