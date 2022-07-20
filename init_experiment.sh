#!/bin/bash
if [[ "$1" == "" ]]; then 
    echo "usage: ./init_experiment.sh <generator-script>"
    exit 1
fi 

# Source environment
if [[ ! -f "env.sh" ]]; then 
    echo "must be run from the directory containing this script"
    exit 1
fi 
source env.sh

# Check CLI arguments
generator_script="$1"
if [[ ! -f "$generator_script" ]]; then 
    echo "cannot find generator scrpt at $generator_script"
    exit 1
fi

# Setup generator environment
_num_nodes=1
_num_cores=1
_name=""

num_nodes() {
    _num_nodes="$@"
}

num_cores() {
    _num_cores="$@"
}

name() {
    _name="$1"
}

# Read generator script
source "$generator_script"

# Perform sanity checks
has_errors=0

if [[ "$_name" == "" ]]; then 
    echo "Error: name must be set"
    has_errors=1
fi

if [[ "$has_errors" == 1 ]]; then 
    exit 1
fi

# Generate output
for num_nodes in $_num_nodes; do 
    echo $num_nodes 
done
