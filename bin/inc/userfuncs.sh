declare -A _algorithm_definition_names=()
declare -A _algorithm_definition_bases=()
declare -A _algorithm_definition_arguments=()
declare -A _algorithm_definition_versions=()
declare -A _algorithm_build_options=()
declare -a _libs=()
declare -a _algorithms=()
declare -a _ks=()
declare -a _seeds=()
declare -a _graphs=()
declare -a _epsilons=()
declare -a _nodes_x_mpis_x_threads=()
declare -a _kagen_graphs=()

_timelimit=""
_timelimit_per_instance=""
_system="generic"
_mpi="none"
_oversubscribe_mpi=0
_scale_ks=0
_username=""
_project=""
_partition=""

# Specifies additional build options for an algorithm.
# The exact semantics depends on the Install*() functions of the underlying 
# partitioner.
#
# BuildOptions <algorithm> <parameters ...>
BuildOptions() {
    name="$1"
    options="${*:2}"
    _algorithm_build_options[$name]="$options"
}

# Enable the -oversubscribe flag for MPI.
Oversubscribe() {
    _oversubscribe_mpi=1
}

# Install a library; the parameter must be a filename in libs/
#
# UseLibrary <name>
UseLibrary() {
    _libs+=(${@})
}

# Define a new algorithm by providing additional CLI arguments to some base
# partitioner (a filename in partitioners/).
#
# DefineAlgorithm <new name> <base partitioner> <additional arguments ...>
DefineAlgorithm() {
    name="$1"
    base_algorithm="$2"
    custom_arguments="${*:3}"

    if [[ "$name" == "$base_algorithm" ]]; then 
        echo "Error: algorithm $name cannot be based on itself"
        exit 1
    fi

    [[ ! -v "_algorithm_definition_names[$name]" ]] || {
        echo "Warning: overwriting already defined algorithm $name"
    }

    _algorithm_definition_names[$name]=1
    _algorithm_definition_bases[$name]="$base_algorithm"
    _algorithm_definition_arguments[$name]="$custom_arguments"
}

# Define a custom algorithm, which is a specific version of some base 
# partitioner (a filename in partitioners/). The exact semantics depend on the 
# Install*() functions of the base partitioner, but are usually git branches 
# or commits.
#
# DefineAlgorithmVersion <new name> <base partitioner> <origin/dev>
# DefineAlgorithmVersion <new name> <base partitioner> <abcd1234>
DefineAlgorithmVersion() {
    name="$1"
    base_algorithm="$2"
    version="$3"

    if [[ "$name" == "$base_algorithm" ]]; then 
        echo "Error: algorithm $name cannot be based on itself"
        exit 1
    fi

    [[ ! -v "_algorithm_definition_names[$name]" ]] || {
        echo "Warning: overwriting already defined algorithm $name"
    }

    [[ "$(GetAlgorithmVersion "$base_algorithm")" == "latest" ]] || {
        echo "Warning: base algorithm $base_algorithm of version definition $name is already a version definition with version $(GetAlgorithmVersion "$base_algorithm")"
    }

    _algorithm_definition_names[$name]=1
    _algorithm_definition_bases[$name]="$base_algorithm"
    _algorithm_definition_arguments[$name]=""
    _algorithm_definition_versions[$name]="$version"
}

# Specifies the system on which the experiment will be run on. This is a 
# filename in systems/
#
# System i10
System() {
    _system="$1"
}

# Specify a username for a HPC system (if the system requires it).
#
# Username <username>
Username() {
    _username="$1"
}

# Specify a project for a HPC system (if the system requires it).
#
# Project <project>
Project() {
    _project="$1"
}

# Specify a partition for a HPC system (if the system requires it).
#
# Partition <mikro|default|fat>
Partition() {
    _partition="$1"
}

# Specify the MPI library that should be used, e.g., OpenMPI, IMPI or 
# other runners, e.g., none or taskset.
#
# MPI <OpenMPI|IMPI|none|taskset>
MPI() {
    _mpi="$1"
}

# Specify which algorithms to run, can be base partitioners or names defined by
# BuildOptions, DefineAlgorithmVersion, DefineAlgorithm.
#
# Algorithms <names ...>
Algorithms() {
    _algorithms+=(${@})
}

# Specify the number of nodes, MPI processes and threads to be used for 
# execution. Can provide multiple values for scaling experiments etc.
#
# Threads <<nodes>x<mpis>x<threads> ...>
Threads() {
    _nodes_x_mpis_x_threads+=(${@})
}

# Specify seeds for PRNG. Can provide multiple values for repeated execution.
#
# Seeds <seed ...>
Seeds() {
    _seeds+=(${@})
}

# Specify number of blocks. Can provide multiple values.
#
# Ks <k ...>
Ks() {
    _ks+=(${@})
}

# If set, scale K with the number of compute nodes.
#
# ScaleKs
ScaleKs() {
    _scale_ks=1
}

# Provide a timelimit in hh:mm:ss format for the whole experiment.
#
# Timelimit <hh:mm:ss>
Timelimit() {
    _timelimit="$1"
}

# Provide a per-instance time limit in hh:mm:ss format.
#
# TimelimitPerInstance <hh:mm:ss>
TimelimitPerInstance() {
    _timelimit_per_instance="$1"
}

# Specify a directory containing graphs. 
#
# Graphs <dirs ...>
Graphs() {
    for filename in ${1%/}/*.*; do 
        _graphs+=("${filename%.*}")
    done
}

Graph() {
    _graphs+=("${1%.*}")
}

Epsilons() {
    _epsilons+=(${@})
}

KaGen() {
    generator="$1"
    arguments="${@:2}"
    _kagen_graphs+=("$generator $arguments")
}

GetAlgorithmBase() {
    algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
        GetAlgorithmBase "${_algorithm_definition_bases[$algorithm]}"
    else 
        echo "$algorithm"
    fi
}

GetAlgorithmArguments() {
    algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
        additional_arguments=$(GetAlgorithmArguments "${_algorithm_definition_bases[$algorithm]}")
        echo "${_algorithm_definition_arguments[$algorithm]} $additional_arguments"
    else 
        echo ""
    fi
}

GetAlgorithmVersion() {
    algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
       if [[ -v "_algorithm_definition_versions[$algorithm]" ]]; then 
           echo "${_algorithm_definition_versions[$algorithm]}"
       else 
           GetAlgorithmVersion "${_algorithm_definition_bases[$algorithm]}"
       fi
    else 
        echo "latest"
    fi
}

# Print a summary for the whole experiment
PrintSummary() {
    if [[ $mode != "generate" ]]; then 
        return 0
    fi

    echo "Custom algorithm definitions:"
    for algorithm in ${!_algorithm_definition_names[@]}; do 
        echo "- $algorithm <- $(GetAlgorithmBase "$algorithm")"
        echo "  Version: $(GetAlgorithmVersion "$algorithm")"
        echo "  Arguments: $(GetAlgorithmArguments "$algorithm")"
    done
    echo ""

    echo "Algorithms:"
    for algorithm in ${_algorithms[@]}; do 
        echo "- $algorithm"
    done
    echo ""

    echo "Graphs:"
    for graph in ${_graphs[@]}; do 
        echo "- $graph"
    done
    echo ""

    echo "KaGen graphs:"
    for i in "${!_kagen_graphs[@]}"; do 
        arguments="${_kagen_graphs[$i]}"
        echo "- $arguments"
    done 
    echo ""

    echo "Parallel executions:"
    for nodes_x_mpis_x_threads in ${_nodes_x_mpis_x_threads[@]}; do
        echo "- $(ParseNodes "$nodes_x_mpis_x_threads") nodes X $(ParseMPIs "$nodes_x_mpis_x_threads") MPI processes X $(ParseThreads "$nodes_x_mpis_x_threads") threads"
    done
    echo ""

    echo "Seeds: ${_seeds[*]}"
    echo "Ks: ${_ks[*]}"
}

