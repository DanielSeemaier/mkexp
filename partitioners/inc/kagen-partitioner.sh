. "$script_pwd/../partitioners/inc/git.sh"

GenericKaGenPartitionerFetch() {
    local -n generic_kagen_partitioner_fetch_args=$1
    GenericGitFetch generic_kagen_partitioner_fetch_args "git@github.com:KaHIP/KaGen-Partitioner.git" "generic_kagen_driver_src"
}

GenericKaGenPartitionerInstall() {
    local -n generic_kagen_partitioner_install_args=$1
    local cmake_option=$2
    local binary_name=$3

    src_dir="${generic_kagen_partitioner_install_args[generic_kagen_driver_src]}"

    echo -e "Build KaGen-Driver for algorithm '$ALGO_COLOR${generic_kagen_partitioner_install_args[algorithm]}$NO_COLOR' in directory '$src_dir'"
    echo "  - System-specific CMake options: $CUSTOM_CMAKE_FLAGS"
    echo "  - Partitioner-specific CMake options: $cmake_option"
    echo -e "  - Algorithm-specific CMake options: $ARGS_COLOR${generic_kagen_partitioner_install_args[algorithm_build_options]}$NO_COLOR"
    echo "Note: all of these options are passed to the KaGen-Driver CMake command."
    echo ""

    Prefixed cmake -S "$src_dir" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        $cmake_option \
        $CUSTOM_CMAKE_FLAGS \
        ${generic_kagen_partitioner_install_args[algorithm_build_options]}
    Prefixed cmake --build "$src_dir/build" --parallel
    Prefixed cp "$src_dir/build/$binary_name" "${generic_kagen_partitioner_install_args[kagen_driver_bin]}"
}

GenericKaGenPartitionerInvokeFromDisk() {
    local -n generic_kagen_partitioner_invoke_from_disk_args=$1

    graph="${generic_kagen_partitioner_invoke_from_disk_args[graph]}"
    [[ -f "$graph.parhip" ]] && graph="$graph.parhip"
    [[ -f "$graph.bgf" ]] && graph="$graph.bgf"
    [[ -f "$graph.graph" ]] && graph="$graph.graph"
    [[ -f "$graph.metis" ]] && graph="$graph.metis"

    if [[ "${generic_kagen_partitioner_invoke_from_disk_args[print_partitioner]}" == "1" ]]; then 
        >&2 echo -e "Generating calls for algorithm '$ALGO_COLOR${generic_kagen_partitioner_invoke_from_disk_args[algorithm]}$NO_COLOR', from disk, via the library:"
        >&2 echo "  - Binary: ${generic_kagen_partitioner_invoke_from_disk_args[kagen_driver_bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo -e "      -s $ARGS_COLOR${generic_kagen_partitioner_invoke_from_disk_args[seed]}$NO_COLOR"
        >&2 echo -e "      -k $ARGS_COLOR${generic_kagen_partitioner_invoke_from_disk_args[k]}$NO_COLOR"
        >&2 echo -e "      -G\"file;filename=$ARGS_COLOR$graph$NO_COLOR\""
        >&2 echo -e "  - Specified arguments: $ARGS_COLOR${generic_kagen_partitioner_invoke_from_disk_args[algorithm_arguments]}$NO_COLOR"
        >&2 echo "[...]"
        >&2 echo ""
    fi

    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_disk_args[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_disk_args[k]} "
    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[algorithm_arguments]} "
    echo -n "-G\"file;filename=$graph\""
    echo ""
}

GenericKaGenPartitionerInvokeFromKaGen() {
    local -n generic_kagen_partitioner_invoke_from_kagen=$1

    if [[ "${generic_kagen_partitioner_invoke_from_kagen[print_partitioner]}" == "1" ]]; then 
        >&2 echo -e "Generating calls for algorithm '$ALGO_COLOR${generic_kagen_partitioner_invoke_from_kagen[algorithm]}$NO_COLOR', from KaGen, via the library:"
        >&2 echo "  - Binary: ${generic_kagen_partitioner_invoke_from_kagen[kagen_driver_bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo -e "      -s $ARGS_COLOR${generic_kagen_partitioner_invoke_from_kagen[seed]}$NO_COLOR"
        >&2 echo -e "      -k $ARGS_COLOR${generic_kagen_partitioner_invoke_from_kagen[k]}$NO_COLOR"
        >&2 echo -e "      -G\"$ARGS_COLOR${generic_kagen_partitioner_invoke_from_kagen[kagen_arguments_stringified]}$NO_COLOR\""
        >&2 echo -e "  - Specified arguments: $ARGS_COLOR${generic_kagen_partitioner_invoke_from_kagen[algorithm_arguments]}$NO_COLOR"
        >&2 echo "[...]"
        >&2 echo ""
    fi

    echo -n "${generic_kagen_partitioner_invoke_from_kagen[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_kagen[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_kagen[k]} "
    #echo -n "-t ${generic_kagen_partitioner_invoke_from_kagen[num_threads]} "
    echo -n "${generic_kagen_partitioner_invoke_from_kagen[algorithm_arguments]} "
    echo -n "-G\"${generic_kagen_partitioner_invoke_from_kagen[kagen_arguments_stringified]}\""
    echo ""
}

