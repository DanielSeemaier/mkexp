#!/bin/bash
source=${BASH_SOURCE[0]}
while [ -L "$source" ]; do
  script_pwd=$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)
  source=$(readlink "$source")
  [[ $source != /* ]] && source=$script_pwd/$source
done
script_pwd=$(cd -P "$(dirname "$source")" >/dev/null 2>&1 && pwd)

# Scripts contained in this project
export PATH="$script_pwd/bin:$PATH"

# Install directories for graph partitioners
export DGP_PREFIX="$script_pwd/usr/"

export PATH="$DGP_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$DGP_PREFIX/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$DGP_PREFIX/lib:$LIBRARY_PATH"
export C_INCLUDE_PATH="$DGP_PREFIX/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$DGP_PREFIX/include:$CPLUS_INCLUDE_PATH"

# Load private variables
[[ -f "$script_pwd/private" ]] && . "$script_pwd/private"
