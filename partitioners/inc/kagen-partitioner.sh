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

    echo "Build KaGen-Driver for algorithm '${generic_kagen_partitioner_install_args[algorithm]}' in directory '$src_dir'"
    echo "  - System-specific CMake options: $CUSTOM_CMAKE_FLAGS"
    echo "  - Partitioner-specific CMake options: $cmake_option"
    echo "  - Algorithm-specific CMake options: ${generic_kagen_partitioner_install_args[algorithm_build_options]}"
    echo "Note: all of these options are passed to the KaGen-Driver CMake command."

    Prefixed cmake -S "$src_dir" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        $cmake_option \
        $CUSTOM_CMAKE_FLAGS \
        ${generic_kagen_partitioner_install_args[algorithm_build_options]}
    Prefixed cmake --build "$src_dir/build" --parallel
    Prefixed cp "$src_dir/build/$binary_name" "${generic_kagen_partitioner_install_args[kagen_driver_bin]}"
}

generic_disk_last_algorithm_name=""

GenericKaGenPartitionerInvokeFromDisk() {
    local -n generic_kagen_partitioner_invoke_from_disk_args=$1

    graph="${generic_kagen_partitioner_invoke_from_disk_args[graph]}"
    [[ -f "$graph.parhip" ]] && graph="$graph.parhip"
    [[ -f "$graph.bgf" ]] && graph="$graph.bgf"
    [[ -f "$graph.graph" ]] && graph="$graph.graph"
    [[ -f "$graph.metis" ]] && graph="$graph.metis"

    if [[ $generic_disk_last_algorithm_name != ${generic_kagen_partitioner_invoke_from_disk_args[algorithm]} ]]; then 
        >&2 echo "Generating calls for algorithm '${generic_kagen_partitioner_invoke_from_disk_args[algorithm]}', from disk, via the library:"
        >&2 echo "  - Binary: ${generic_kagen_partitioner_invoke_from_disk_args[kagen_driver_bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo "      -s {${generic_kagen_partitioner_invoke_from_disk_args[seed]}}"
        >&2 echo "      -k {${generic_kagen_partitioner_invoke_from_disk_args[k]}}"
        >&2 echo "      -G\"file;filename={$graph}\""
        >&2 echo "  - Specified arguments: ${generic_kagen_partitioner_invoke_from_disk_args[algorithm_arguments]}"
        generic_disk_last_algorithm_name="${generic_kagen_partitioner_invoke_from_disk_args[algorithm]}"
    fi

    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_disk_args[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_disk_args[k]} "
    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[algorithm_arguments]} "
    echo -n "-G\"file;filename=$graph\""
    echo ""
}

generic_kagen_last_algorithm_name=""

GenericKaGenPartitionerInvokeFromKaGen() {
    local -n generic_kagen_partitioner_invoke_from_kagen=$1

    if [[ $generic_kagen_last_algorithm_name != ${generic_kagen_partitioner_invoke_from_kagen[algorithm]} ]]; then 
        >&2 echo "Generating calls for algorithm '${generic_kagen_partitioner_invoke_from_kagen[algorithm]}', from KaGen, via the library:"
        >&2 echo "  - Binary: ${generic_kagen_partitioner_invoke_from_kagen[kagen_driver_bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo "      -s {${generic_kagen_partitioner_invoke_from_kagen[seed]}}"
        >&2 echo "      -k {${generic_kagen_partitioner_invoke_from_kagen[k]}}"
        >&2 echo "      -G\"{${generic_kagen_partitioner_invoke_from_kagen[kagen_arguments_stringified]}}\""
        >&2 echo "  - Specified arguments: ${generic_kagen_partitioner_invoke_from_kagen[algorithm_arguments]}"
        generic_kagen_last_algorithm_name="${generic_kagen_partitioner_invoke_from_kagen[algorithm]}"
    fi

    echo -n "${generic_kagen_partitioner_invoke_from_kagen[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_kagen[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_kagen[k]} "
    #echo -n "-t ${generic_kagen_partitioner_invoke_from_kagen[num_threads]} "
    echo -n "${generic_kagen_partitioner_invoke_from_kagen[algorithm_arguments]} "
    echo -n "-G\"${generic_kagen_partitioner_invoke_from_kagen[kagen_arguments_stringified]}\""
    echo ""
}

