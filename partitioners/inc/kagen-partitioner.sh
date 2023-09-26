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

    cmake -S "$src_dir" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        $cmake_option \
        ${generic_kagen_partitioner_install_args[algorithm_build_options]}
    cmake --build "$src_dir/build" --parallel

    cp "$src_dir/build/$binary_name" "${generic_kagen_partitioner_install_args[kagen_driver_bin]}"
}

GenericKaGenPartitionerInvokeFromDisk() {
    local -n generic_kagen_partitioner_invoke_from_disk_args=$1

    graph="${generic_kagen_partitioner_invoke_from_disk_args[graph]}"
    [[ -f "$graph.parhip" ]] && graph="$graph.parhip"
    [[ -f "$graph.bgf" ]] && graph="$graph.bgf"
    [[ -f "$graph.graph" ]] && graph="$graph.graph"
    [[ -f "$graph.metis" ]] && graph="$graph.metis"

    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_disk_args[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_disk_args[k]} "
    echo -n "${generic_kagen_partitioner_invoke_from_disk_args[algorithm_arguments]} "
    echo -n "-G\"file;filename=$graph\""
    echo ""
}

GenericKaGenPartitionerInvokeFromKaGen() {
    local -n generic_kagen_partitioner_invoke_from_kagen=$1
    echo -n "${generic_kagen_partitioner_invoke_from_kagen[kagen_driver_bin]} "
    echo -n "-s ${generic_kagen_partitioner_invoke_from_kagen[seed]} " 
    echo -n "-k ${generic_kagen_partitioner_invoke_from_kagen[k]} "
    #echo -n "-t ${generic_kagen_partitioner_invoke_from_kagen[num_threads]} "
    echo -n "${generic_kagen_partitioner_invoke_from_kagen[algorithm_arguments]} "
    echo -n "-G\"${generic_kagen_partitioner_invoke_from_kagen[kagen_arguments_stringified]}\""
    echo ""
}

