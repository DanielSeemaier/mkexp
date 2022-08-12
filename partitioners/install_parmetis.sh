#!/bin/bash
PREFIX="$1"

cd GKlib
make config prefix="$PREFIX"
make -j 
make install 
cd ..

cd METIS
make config prefix="$PREFIX"
make -j 
make install
cd ..

cd ParMETIS
make config prefix="$PREFIX"
make -j 
make install
cd ..
