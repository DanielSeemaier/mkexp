GenerateInfoFile() {
    echo "Generated at $(date) on $(hostname)" > INFO
}

GenerateCrossProduct() {
    local -n prepared_invoc=$1
    local seed="$2"
    local epsilon="$3"
    local algorithm="$4"
    local k="$5"

    prepared_invoc[bin]="${prepared_invoc[disk_driver_bin]}"
    for graph in ${_graphs[@]}; do
        prepared_invoc[graph]="$graph"
        prepared_invoc[id]="$(GenerateInvocIdentifier prepared_invoc)"
        prepared_invoc[log]="$log_files_dir/${prepared_invoc[algorithm]}/${prepared_invoc[id]}.log"
        prepared_invoc[exe]="$(InvokePartitionerFromDisk prepared_invoc)"
        prepared_invoc[exe]="$(GenerateJobfileEntry prepared_invoc)"
        if [[ "$_timelimit_per_instance" != "" ]]; then 
            prepared_invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${prepared_invoc[exe]}"
        fi
        echo "${prepared_invoc[exe]} >> ${prepared_invoc[log]} 2>&1" >> "${prepared_invoc[job]}"
    done 

    # KaGen graphs
    prepared_invoc[bin]="${prepared_invoc[kagen_driver_bin]}"
    for i in ${!_kagen_graphs[@]}; do
        kagen="$(ScaleKaGenGraph prepared_invoc "${_kagen_graphs[$i]}")"
        kagen_arguments_arr=($kagen)
        prepared_invoc[kagen_stringified]="$(echo "$kagen" | sed -E 's/filename=([^\/]*\/)*(.*)\.kargb/filename=\2/' | tr ' ' '-')"
        prepared_invoc[kagen_arguments_stringified]="$(echo "$kagen" | tr ' ' ';')"
        prepared_invoc[kagen_generator]="${kagen_arguments_arr[0]}"
        prepared_invoc[kagen_arguments]="${kagen_arguments_arr[@]:1}"
        prepared_invoc[id]="$(GenerateKaGenIdentifier prepared_invoc)"
        prepared_invoc[log]="$log_files_dir/${prepared_invoc[algorithm]}/${prepared_invoc[id]}.log"
        prepared_invoc[exe]="$(InvokePartitionerFromKaGen prepared_invoc)"
        prepared_invoc[exe]="$(GenerateJobfileEntry prepared_invoc)"
        if [[ "$_timelimit_per_instance" != "" ]]; then 
            prepared_invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${prepared_invoc[exe]}"
        fi

        echo "${prepared_invoc[exe]} >> ${prepared_invoc[log]} 2>&1" >> "${prepared_invoc[job]}"
    done # generator
}

Generate() {
    for algorithm in ${_algorithms[@]}; do 
        mkdir -p "$log_files_dir/$algorithm"
        mkdir -p "$misc_files_dir/$algorithm"
    done

    declare -a jobfiles
    declare -A invoc=( [mpi]=$_mpi [timelimit]=$_timelimit )
    invoc[misc_dir]="$misc_files_dir"
    invoc[experiment]="$experiment_name"

    for nodes_x_mpis_x_threads in ${_nodes_x_mpis_x_threads[@]}; do
        invoc[num_nodes]=$(ParseNodes "$nodes_x_mpis_x_threads")
        invoc[num_mpis]=$(ParseMPIs "$nodes_x_mpis_x_threads")
        invoc[num_threads]=$(ParseThreads "$nodes_x_mpis_x_threads")
        invoc[job]="$job_files_dir/$(GenerateJobfileName invoc)"

        GenerateJobfileHeader invoc > "${invoc[job]}"
        ExportEnv >> "${invoc[job]}"
        jobfiles+=("${invoc[job]}")

        for seed in ${_seeds[@]}; do
            invoc[seed]=$seed

            for epsilon in ${_epsilons[@]}; do 
                invoc[epsilon]=$epsilon

                for algorithm in ${_algorithms[@]}; do
                    invoc[algorithm]=$algorithm
                    invoc[algorithm_base]=$(GetAlgorithmBase "$algorithm")
                    invoc[algorithm_version]=$(GetAlgorithmVersion "$algorithm")
                    invoc[algorithm_arguments]=$(GetAlgorithmArguments "$algorithm")
                    invoc[algorithm_build_options]=$(GetAlgorithmBuildOptions "$algorithm")

                    build_id=$(GenerateBuildIdentifier invoc)
                    invoc[disk_driver_bin]="$PREFIX/bin/disk-$build_id"
                    invoc[kagen_driver_bin]="$PREFIX/bin/kagen-$build_id"

                    invoc[timeout]=$(ParseTimelimit "$_timelimit_per_instance")

                    for k in ${_ks[@]}; do
                        if [[ "$_scale_ks" == "1" ]]; then 
                            k=$((k*nodes)) 
                        fi
                        invoc[k]=$k

                        GenerateCrossProduct invoc "$seed" "$epsilon" "$algorithm" "$k"
                    done # k
                done # algorithm
            done # epsilon
        done # parallelism setting
    done

    GenerateJobfileSubmission ${jobfiles[@]} >> $submit_impl_filename
}

