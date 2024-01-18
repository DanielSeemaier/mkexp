#!/bin/bash

. "$script_pwd/../partitioners/inc/git.sh"

Fetch() {
    local -n fetch_args=$1

    if (( ${fetch_args[install_disk_driver]} )); then 
        FetchDiskDriver fetch_args
    fi
    if (( ${fetch_args[install_kagen_driver]} )); then 
        echo "KaGen support not implemented for MtKaHyPar"
        exit 1
    fi
}

FetchDiskDriver() {
    GenericGitFetch $1 $MTKAHYPAR_REPOSITORY_URL "disk_driver_src"
}

Install() {
    local -n install_args=$1
    
    if (( ${install_args[install_disk_driver]} )); then 
        InstallDiskDriver install_args
    fi
    if (( ${install_args[install_kagen_driver]} )); then 
        echo "KaGen support not implemented for MtKaHyPar"
        exit 1
    fi
}

InstallDiskDriver() {
    local -n install_disk_driver_args=$1
    src_dir="${install_disk_driver_args[disk_driver_src]}"

    current_pwd="$PWD"

    echo "Build algorithm '${install_disk_driver_args[algorithm]}' in directory '$src_dir'"
    echo "  - System-specific CMake options: $CUSTOM_CMAKE_FLAGS"
    echo "  - Algorithm-specific CMake options: ${install_disk_driver_args[algorithm_build_options]}"
    echo ""

    # For -DKAHYPAR_DOWNLOAD_TBB=ON to work, the cmake command must be run from within the build directory
    mkdir -p "$src_dir/build" 
    cd "$src_dir/build"
    Prefixed cmake -S "$src_dir" \
        -B "$src_dir/build" \
        -DCMAKE_BUILD_TYPE=Release \
        $CUSTOM_CMAKE_FLAGS \
        ${install_disk_driver_args[algorithm_build_options]}
    cd "$current_pwd"

    Prefixed cmake --build "$src_dir/build" --target MtKaHyPar --parallel

    Prefixed cp "$src_dir/build/mt-kahypar/application/MtKaHyPar" "${install_disk_driver_args[disk_driver_bin]}"
}

InvokeFromDisk() {
    local -n invoke_from_disk_args=$1

    graph="${invoke_from_disk_args[graph]}"
    format="metis"
    if [[ -f "$graph.graph" ]]; then
        graph="$graph.graph"
        format="metis"
    elif [[ -f "$graph.metis" ]]; then
        graph="$graph.metis"
        format="metis"
    elif [[ -f "$graph.hgr" ]]; then
        graph="$graph.hgr"
        format="hmetis"
    elif [[ -f "$graph.hmetis" ]]; then
        graph="$graph.hmetis"
        format="hmetis"
    fi

    if [[ "${invoke_from_disk_args[print_partitioner]}" == "1" ]]; then 
        >&2 echo -e "Generating calls for algorithm '$ALGO_COLOR${invoke_from_disk_args[algorithm]}$NO_COLOR', from disk, via the binary:"
        >&2 echo "  - Binary: ${invoke_from_disk_args[bin]}"
        >&2 echo "  - Generated arguments: "
        >&2 echo -e "      -h $ARGS_COLOR$graph$NO_COLOR"
        >&2 echo -e "      --input-file-format=$ARGS_COLOR$format$NO_COLOR"
        >&2 echo -e "      -k $ARGS_COLOR${invoke_from_disk_args[k]}$NO_COLOR"
        >&2 echo -e "      -e $ARGS_COLOR${invoke_from_disk_args[epsilon]}$NO_COLOR"
        >&2 echo -e "      --seed=$ARGS_COLOR${invoke_from_disk_args[seed]}$NO_COLOR"
        >&2 echo -e "      -t $ARGS_COLOR${invoke_from_disk_args[num_threads]}$NO_COLOR"
        >&2 echo -e "  - Specified arguments: $ARGS_COLOR${invoke_from_disk_args[algorithm_arguments]}$NO_COLOR"
        >&2 echo "[...]"
        >&2 echo ""
    fi

    if [[ -f "$graph" ]]; then
        echo -n "${invoke_from_disk_args[bin]} "
        echo -n "-h $graph "
        echo -n "--input-file-format=$format "
        echo -n "-k ${invoke_from_disk_args[k]} "
        echo -n "-e ${invoke_from_disk_args[epsilon]} "
        echo -n "--seed=${invoke_from_disk_args[seed]} "
        echo -n "-t ${invoke_from_disk_args[num_threads]} "
        echo -n "${invoke_from_disk_args[algorithm_arguments]}"
        echo ""
    else 
        >&2 echo "Warning: Graph $graph does not exist"
        return 1
    fi
}

ReportVersion() {
    GenericGitReportVersion $1
}
