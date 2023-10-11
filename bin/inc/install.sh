FetchPartitioner() {
    local -n fetch_partitioner_args=$1
    LoadAlgorithm "${fetch_partitioner_args[algorithm_base]}"
    Fetch fetch_partitioner_args
}

FetchLibrary() {
    local -n fetch_library_args=$1
    LoadLibrary "${fetch_library_args[library]}"
    Fetch fetch_partitioner_args
}

InstallPartitioner() {
    local -n install_partitioner_args=$1
    LoadAlgorithm "${install_partitioner_args[algorithm_base]}"
    Install install_partitioner_args
}

InstallLibrary() {
    local -n install_library_args=$1
    LoadLibrary "${install_library_args[library]}"
    Install install_partitioner_args
}

LoadSystem() {
    name="$1"
    filename="$script_pwd/../systems/$name"
    [[ -f "$filename" ]] || {
        echo "Error: invalid system $name"
        echo "       $filename"
        exit 1
    }
    . "$filename"
}

InstallLibraries() {
    local fetch=$1
    local install=$2

    for lib in ${_libs[@]}; do 
        declare -A install_libraries_args
        install_libraries_args[library] = "$lib"

        if [[ $fetch == "1" ]]; then
            FetchLibrary install_libraries_args
        fi
        if [[ $install == "1" ]]; then 
            InstallLibrary install_libraries_args
        fi
    done
}

InstallPartitioners() {
    local fetch=$1
    local install=$2

    for partitioner in ${_algorithms[@]}; do 
        declare -A install_partitioners_args

        install_partitioners_args[algorithm]="$partitioner"
        install_partitioners_args[algorithm_base]=$(GetAlgorithmBase "$partitioner")
        install_partitioners_args[algorithm_build_options]=$(GetAlgorithmBuildOptions "$partitioner")
        install_partitioners_args[algorithm_version]=$(GetAlgorithmVersion "$partitioner")

        install_partitioners_args[install_disk_driver]=$((${#_graphs[@]}))
        install_partitioners_args[install_kagen_driver]=$((${#_kagen_graphs[@]}))

        build_id=$(GenerateBuildIdentifier install_partitioners_args)
        generic_build_id=$(GenerateGenericBuildIdentifier install_partitioners_args)

        install_partitioners_args[disk_driver_bin]="$PREFIX/bin/disk-$build_id"
        install_partitioners_args[kagen_driver_bin]="$PREFIX/bin/kagen-$build_id"
        install_partitioners_args[disk_driver_src]="$PREFIX/src/disk-$build_id/"
        install_partitioners_args[kagen_driver_src]="$PREFIX/src/kagen-$build_id/"
        install_partitioners_args[generic_kagen_driver_src]="$PREFIX/src/generic-$generic_build_id/"

        if [[ $fetch == "1" ]]; then
            FetchPartitioner install_partitioners_args
        fi    
        if [[ $install == "1" ]]; then 
            InstallPartitioner install_partitioners_args
        fi
    done
}

