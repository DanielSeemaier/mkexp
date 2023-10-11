LoadAlgorithm() {
    local name="$1"
    local filename="$script_pwd/../partitioners/$name"
    [[ -f "$filename" ]] || {
        echo "Error: invalid partitioner $name"
        echo "       $filename"
        exit 1
    }
    . "$filename"
}

LoadLibrary() {
    local name="$1"
    local filename="$script_pwd/../libs/$name"
    [[ -f "$filename" ]] || {
        echo "Error: invalid library $name"
        echo "       $filename"
        exit 1
    }
    . "$filename"
}

ScaleKaGenGraph() {
    local -n args=$1
    local kagen="$2"

    num_nodes=${args[num_nodes]}
    num_mpis=${args[num_mpis]}
    num_threads=${args[num_threads]}
    num_pes=$((num_nodes*num_mpis*num_threads))
    log_nodes=$(printf "%.0f" $(echo "l($num_nodes)/l(2)" | bc -l))
    log_mpis=$(printf "%.0f" $(echo "l($num_mpis)/l(2)" | bc -l))
    log_threads=$(printf "%.0f" $(echo "l($num_threads)/l(2)" | bc -l))
    log_pes=$(printf "%.0f" $(echo "l($num_pes)/l(2)" | bc -l))

    sub=$(echo "$kagen" | N=$num_nodes M=$num_mpis T=$num_threads P=$num_pes lN=$log_nodes lM=$log_mpis lT=$log_threads lP=$log_pes envsubst)
    eval "echo $sub"
}

# Parse argument to "Threads"
ParseNodes() {
    if [[ "$1" == *x*x* ]]; then
        echo "${1%%x*}"
    else
        echo "1"
    fi
}

ParseMPIs() {
    if [[ "$1" == *x* ]]; then 
        without_threads="${1%x*}"
        echo "${without_threads#*x}"
    else # Number of nodes can be omitted
        echo "1"
    fi
}

ParseThreads() {
    echo "${1##*x}"
}

ParseTimelimit() {
    time="$1"
    seconds="${time##*:}"
    minutes=0
    hours=0
    days=0
    if [[ "$time" == *:* ]]; then 
        time="${time%:*}"
        minutes="${time##*:}"
    fi 
    if [[ "$time" == *:* ]]; then
        time="${time%:*}"
        hours="${time##*:}"
    fi
    if [[ "$time" == *:* ]]; then
        time="${time%:*}"
        days="${time}"
    fi
    
    echo $((seconds+60*minutes+60*60*hours+24*60*60*days))
}

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

GenerateBuildIdentifier() {
    local -n generate_build_identifier_args=$1

    version=$(echo ${generate_build_identifier_args[algorithm_version]} | \
        tr '/' '_' \
    )
    build=$(echo ${generate_build_identifier_args[algorithm_build_options]} | \
        tr '/' '_' | \
        tr ' ' '_' \
    )

    echo "${generate_build_identifier_args[algorithm_base]}-$version-$build"
}

GenerateGenericBuildIdentifier() {
    local -n generate_build_identifier_args=$1

    version=$(echo ${generate_build_identifier_args[algorithm_version]} | \
        tr '/' '_' \
    )
    build=$(echo ${generate_build_identifier_args[algorithm_build_options]} | \
        tr '/' '_' | \
        tr ' ' '_' \
    )

    echo "$version-$build"
}

GetAlgorithmBase() {
    local algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
        GetAlgorithmBase "${_algorithm_definition_bases[$algorithm]}"
    else 
        echo "$algorithm"
    fi
}

GetAlgorithmArguments() {
    local algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
        additional_arguments=$(GetAlgorithmArguments "${_algorithm_definition_bases[$algorithm]}")
        echo "${_algorithm_definition_arguments[$algorithm]} $additional_arguments"
    else 
        echo ""
    fi
}

GetAlgorithmVersion() {
    local algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
       if [[ -v "_algorithm_definition_versions[$algorithm]" && ${_algorithm_definition_versions[$algorithm]} != "" ]]; then 
           echo "${_algorithm_definition_versions[$algorithm]}"
       else 
           GetAlgorithmVersion "${_algorithm_definition_bases[$algorithm]}"
       fi
    else 
        echo "latest"
    fi
}

GetAlgorithmBuildOptions() {
    local algorithm="$1"
    if [[ -v "_algorithm_definition_names[$algorithm]" ]]; then 
        additional_build_options=$(GetAlgorithmBuildOptions "${_algorithm_definition_bases[$algorithm]}")
        echo "${_algorithm_definition_build_options[$algorithm]} $additional_build_options"
    else 
        echo ""
    fi
}

CMD_COLOR='\033[0;36m'
STEP_COLOR='\033[1;34m'
PREFIX_COLOR='\033[1;31m'
NO_COLOR='\033[0m'
ALGO_COLOR='\033[0;35m'
ARGS_COLOR='\033[0;31m'
WARNING_COLOR='\033[1;31m'

Prefixed() {
    echo -e "  \$$CMD_COLOR $@ $NO_COLOR"
    "$@" 2>&1 | sed 's/^/  | /'
    exit_code=$?
    echo "  \`-- Exit code: $? --------------------------------------------------------------------------------------------------"
    echo ""
}

PrintExperiment() {
    echo -e ">>> Processing\033[1;35m $@ $NO_COLOR"
    echo ""
}
