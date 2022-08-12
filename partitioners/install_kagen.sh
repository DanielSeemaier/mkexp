#!/bin/bash
PREFIX="$1"

cd KaGen
cp library/kagen.h "$PREFIX/include"

rm -rf build && mkdir build && cd build 
cmake .. -DCMAKE_BUILD_TYPE=Release $ADDITIONAL_KAGEN_ARGS
make kagen -j 

cp library/libkagen.a "$PREFIX/lib"
cp extlib/sampling/sampling/libsampling* "$PREFIX/lib"
cp extlib/sampling/extlib/tlx/tlx/libtlx* "$PREFIX/lib"
cp extlib/sampling/extlib/spooky/libspooky* "$PREFIX/lib"

