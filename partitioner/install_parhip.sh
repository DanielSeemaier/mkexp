#!/bin/bash
PREFIX="$1"

cd KaHIP
./compile_withcmake.sh
cp deploy/libparhip* "$PREFIX/lib/"
cp deploy/parhip_interface.h "$PREFIX/include/"
cp deploy/parhip "$PREFIX/bin/"

