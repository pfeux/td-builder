#!/bin/bash
TZ=America/New_York
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
DEBIAN_FRONTEND=noninteractive

apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install make git zlib1g-dev libssl-dev gperf php-cli cmake clang libc++-dev libc++abi-dev -y

clangVersion=$(clang --version | awk 'NR==1 {split($4, a, "."); print a[1]}')

cd /app
git clone https://github.com/tdlib/td.git

cd /app/td
rm -rf build && mkdir build && cd build
CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang CXX=/usr/bin/clang++ cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=../tdlib/Release -DTD_ENABLE_LTO=ON -DCMAKE_AR=/usr/bin/llvm-ar-$clangVersion -DCMAKE_NM=/usr/bin/llvm-nm-$clangVersion -DCMAKE_OBJDUMP=/usr/bin/llvm-objdump-$clangVersion -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-$clangVersion ..
cmake --build . --target install

cd /app/td
rm -rf build && mkdir build && cd build
CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang CXX=/usr/bin/clang++ cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX:PATH=../tdlib/Debug -DTD_ENABLE_LTO=ON -DCMAKE_AR=/usr/bin/llvm-ar-$clangVersion -DCMAKE_NM=/usr/bin/llvm-nm-$clangVersion -DCMAKE_OBJDUMP=/usr/bin/llvm-objdump-$clangVersion -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-$clangVersion ..
cmake --build . --target install

ls -alh /app/td/tdlib
