#!/usr/bin/env bash

# Find location of this script
source=${BASH_SOURCE[0]}
while [ -L "$source" ]; do 
  dir=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
  source=$(readlink "$source")
  [[ $source != /* ]] && source=$dir/$source 
done
dir=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )

# Global configuration
source "$dir/config"

# Check arguments
if [[ "$1" == "" ]]; then 
    echo "usage: $0 <generator-script>"
    exit 1
fi 

generator_script="$dir/$1"
if [[ ! -f "$generator_script" ]]; then 
    echo "invalid generator script"
    exit 1
fi

# Setup generator environment
_num_nodes=1
_num_cores=1
_mpi="openmpi"
_ks=()
_time_limit=""
_time_limit_per_instance=""
_algorithms=()
_graphs=()
_parallelism=()
_ws_kagen_graphs=()
_ss_kagen_graphs=()

num_nodes() {
    _num_nodes="$@"
}

num_cores() {
    _num_cores="$@"
}

mpi() {
    _mpi="$1"
}

parallelism() {
    return 0
}

ks() {
    _ks="$1"
}

time_limit() {
    _time_limit="$1"
}

time_limit_per_instance() {
    _time_limit_per_instance="$1"
}

algorithms() {
    _algorithms+=("$1")
}

algorithm() {
    _algorithms+=("$@")
}

ws_kagen() {
    return 0
}

graph() {
    _graphs+=("$1")
}

graphs() {
    for file in $1/*; do 
        _graphs+=("${file%.*}")
    done
}

seeds() {
    return 0
}

# Read generator script
source "$generator_script"

param_mpi="$_mpi"
param_time_limit="$_time_limit"
param_time_limit_per_instance="$_time_limit_per_instance"

# System-specific configuration
if [[ "$(hostname)" == "login"* ]]; then 
    source "$dir/clusters/supermuc"
elif [[ "$(hostname)" == "hkn"* ]]; then
    source "$dir/clusters/horeka"
else
    source "$dir/clusters/generic"
fi

# Perform sanity checks
has_errors=0

if [[ ${#_graphs[@]} > 0 ]]; then 
    for algorithm in ${_algorithms[@]}; do 
        if [[ ! -f "$dir/runners/disk/$algorithm" ]]; then 
            echo "Error: algorithm $algorithm cannot be used to partition graphs from disk"
            has_errors=1
        fi
    done
fi

num_ws_kagen_graphs=${#_ws_kagen_graphs[@]}
num_ss_kagen_graphs=${#_ss_kagen_graphs[@]}
if [[ $((num_ws_kagen_graphs+num_ss_kagen_graphs)) > 0 ]]; then 
    for algorithm in ${_algorithms[@]}; do 
        if [[ ! -f "$dir/runners/kagen/$algorithm" ]]; then 
            echo "Error: algorithm $algorithm cannot be used to partition in-memory graphs from KaGen"
            has_errors=1 
        fi
    done
fi

system_validate || has_errors=1

if [[ "$has_errors" == 1 ]]; then 
    exit 1
fi

# Generate output
jobs_dir="jobs/$_name/"
out_dir="out/$_name/"
mkdir -p "$jobs_dir"
mkdir -p "$out_dir"

get_job_file() {
    echo "$jobs_dir/$1.sh"
}

for parallelism in ${_parallelism[@]}; do 
    param_num_nodes=${parallelism%x*}
    param_num_cores=${parallelism#*x}

    jobs_file="$(get_job_file "$parallelism")"
    system_generate_slurm_job_header > "$jobs_file"
done

for algorithm in ${_algorithms[@]}; do 
    for parallelism in ${_parallelism[@]}; do 
        param_num_nodes=${parallelism%x*}
        param_num_cores=${parallelism#*x}
        jobs_file="$(get_job_file "$parallelism")"
    
        mpi_cmd="$(system_generate_mpi_cmd)"

        for graph in ${_graphs[@]}; do 
            source "$dir/runners/disk/$algorithm"
            algorithm_generate_invoke >> "$jobs_file"
        done
    done
done
