#!/bin/bash
source env.sh 
if [[ -f system.sh ]]; then 
    source system.sh 
fi

git submodule update --init --recursive

mkdir -p "$DGP_LOGS"
mkdir -p "$DGP_PREFIX"
mkdir -p "$DGP_PREFIX/bin"
mkdir -p "$DGP_PREFIX/lib"
mkdir -p "$DGP_PREFIX/include"

cd partitioner/

echo "Installing ParHIP ..."
#./install_parhip.sh "$DGP_PREFIX" 1>"$DGP_LOGS/install_parhip.out" 2>"$DGP_LOGS/install_parhip.err"
if [[ ! -x "$DGP_PREFIX/bin/parhip" ]]; then 
    echo "Installation failed, see $DGP_LOGS/install_parhip.err for more details"
fi

echo "Installing ParMETIS ..."
#./install_parmetis.sh "$DGP_PREFIX" 1>"$DGP_LOGS/install_parmetis.out" 2>"$DGP_LOGS/install_parmetis.err"
if [[ ! -x "$DGP_PREFIX/bin/pm_parmetis" ]]; then 
    echo "Installation failed, see $DGP_LOGS/install_parmetis.err for more details"
fi

echo "Installing KaGen ..."
#./install_kagen.sh "$DGP_PREFIX" 1>"$DGP_LOGS/install_kagen.out" 2>"$DGP_LOGS/install_kagen.err"
if [[ ! -f "$DGP_PREFIX/lib/libkagen.a" ]]; then 
    echo "Installation failed, see $DGP_LOGS/install_kagen.err for more details"
fi 

echo "Installing in-memory driver ..."
./install_inmemory_driver.sh "$DGP_PREFIX" 1>"$DGP_LOGS/install_inmemory_driver.out" 2>"$DGP_LOGS/install_inmemory_driver.err"
if [[ ! -x "$DGP_PREFIX/bin/InMemoryParhip" || ! -x "$DGP_PREFIX/bin/InMemoryParmetis" ]]; then
    echo "Installation failed, see $DGP_LOGS/install_inmemory_driver.err for more details"
fi
