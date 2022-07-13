#!/bin/bash
PREFIX="$1"

cd InMemoryDriver
rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j
cp InMemoryParhip "$PREFIX/bin"
cp InMemoryParmetis "$PREFIX/bin"
