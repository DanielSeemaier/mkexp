if [[ $skip_install == "0" && ($mode == "generate" || $mode == "fetch" || $mode == "install" || $mode == "install-fetched" ) ]]; then
    SetupBuildEnv

    for lib in ${_libs[@]}; do 
        declare -A library 
        library[library]="$lib"
        if [[ $mode == "fetch" ]]; then 
            FetchLibrary library
        elif [[ $mode == "install-fetched" ]]; then 
            InstallLibrary library
        else
            FetchLibrary library
            InstallLibrary library
        fi
    done

    for algorithm in ${_algorithms[@]}; do
        declare -A partitioner
        partitioner[algorithm]="$algorithm"
        partitioner[algorithm_base]=$(GetAlgorithmBase "$algorithm")
        partitioner[algorithm_version]=$(GetAlgorithmVersion "$algorithm")
        partitioner[binary_disk]="$(GenerateBinaryName partitioner)"
        partitioner[binary_kagen]="$(GenerateKaGenBinaryName partitioner)"
        partitioner[install_disk]=$((${#_graphs[@]}))
        partitioner[install_kagen]=$((${#_kagen_graphs[@]}))
        partitioner[install_dir]="$PREFIX/src/$(GenerateInstallDir partitioner)"
        partitioner[build_options]=""
        if [[ -v "_algorithm_build_options[${partitioner[algorithm_base]}]" ]]; then 
            partitioner[build_options]="${_algorithm_build_options[${partitioner[algorithm_base]}]}"
        fi
        if [[ $mode == "fetch" ]]; then 
            FetchPartitioner partitioner
        elif [[ $mode == "install-fetched" ]]; then 
            InstallPartitioner partitioner
        else
            FetchPartitioner partitioner
            InstallPartitioner partitioner
        fi
    done
fi

