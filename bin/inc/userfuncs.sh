# Functions to be called from the Experiment file
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

ResetExperiment() {
    _algorithm_definition_names=()
    _algorithm_definition_bases=()
    _algorithm_definition_arguments=()
    _algorithm_definition_versions=()
    _algorithm_build_options=()
    _algorithms=()
    _libs=()
    _ks=()
    _seeds=()
    _graphs=()
    _epsilons=()
    _nodes_x_mpis_x_threads=()
    _kagen_graphs=()
    _timelimit=""
    _time_per_instance=""
    _system="generic"
    _mpi="none"
    _oversubscribe_mpi=0
    _scale_ks=0
}

BuildOptions() {
    name="$1"
    options="${*:2}"
    _algorithm_build_options[$name]="$options"
}

Oversubscribe() {
    _oversubscribe_mpi=1
}

UseLibrary() {
    _libs+=(${@})
}

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

System() {
    _system="$1"
}

Username() {
    _username="$1"
}

Project() {
    _project="$1"
}

Partition() {
    _partition="$1"
}

MPI() {
    _mpi="$1"
}

Algorithms() {
    _algorithms+=(${@})
}

Threads() {
    _nodes_x_mpis_x_threads+=(${@})
}

Seeds() {
    _seeds+=(${@})
}

Ks() {
    _ks+=(${@})
}

ScaleKs() {
    _scale_ks=1
}

Timelimit() {
    _timelimit="$1"
}

TimelimitPerInstance() {
    _timelimit_per_instance="$1"
}

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

