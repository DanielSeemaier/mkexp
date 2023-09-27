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
    prepared_invoc[print_partitioner]=${prepared_invoc[first_algorithm_call]}
    prepared_invoc[print_wrapper]=${prepared_invoc[first_parallelism_call]}
    for graph in ${_graphs[@]}; do
        prepared_invoc[graph]="$graph"
        prepared_invoc[id]="$(GenerateInvocIdentifier prepared_invoc)"
        prepared_invoc[log]="$log_files_dir/${prepared_invoc[algorithm]}/${prepared_invoc[id]}.log"
        prepared_invoc[exe]="$(InvokeFromDisk prepared_invoc)"
        prepared_invoc[exe]="$(GenerateJobfileEntry prepared_invoc)"
        if [[ "$_timelimit_per_instance" != "" ]]; then 
            prepared_invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${prepared_invoc[exe]}"
        fi
        echo "${prepared_invoc[exe]} >> ${prepared_invoc[log]} 2>&1" >> "${prepared_invoc[job]}"
        prepared_invoc[print_partitioner]=0
        prepared_invoc[print_wrapper]=0
    done 

    # KaGen graphs
    prepared_invoc[bin]="${prepared_invoc[kagen_driver_bin]}"
    prepared_invoc[print_partitioner]=${prepared_invoc[first_algorithm_call]}
    for i in ${!_kagen_graphs[@]}; do
        kagen="$(ScaleKaGenGraph prepared_invoc "${_kagen_graphs[$i]}")"
        kagen_arguments_arr=($kagen)
        prepared_invoc[kagen_stringified]="$(echo "$kagen" | sed -E 's/filename=([^\/]*\/)*(.*)\.kargb/filename=\2/' | tr ' ' '-')"
        prepared_invoc[kagen_arguments_stringified]="$(echo "$kagen" | tr ' ' ';')"
        prepared_invoc[kagen_generator]="${kagen_arguments_arr[0]}"
        prepared_invoc[kagen_arguments]="${kagen_arguments_arr[@]:1}"
        prepared_invoc[id]="$(GenerateKaGenIdentifier prepared_invoc)"
        prepared_invoc[log]="$log_files_dir/${prepared_invoc[algorithm]}/${prepared_invoc[id]}.log"
        prepared_invoc[exe]="$(InvokeFromKaGen prepared_invoc)"
        prepared_invoc[exe]="$(GenerateJobfileEntry prepared_invoc)"
        if [[ "$_timelimit_per_instance" != "" ]]; then 
            prepared_invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${prepared_invoc[exe]}"
        fi

        echo "${prepared_invoc[exe]} >> ${prepared_invoc[log]} 2>&1" >> "${prepared_invoc[job]}"
        prepared_invoc[print_partitioner]=0
    done # generator
}

Generate() {
    declare -A invoc=( [mpi]=$_mpi [timelimit]=$_timelimit )
    invoc[misc_dir]="$misc_files_dir"
    invoc[experiment]="$experiment_name"

    # Prepare jobfiles for each "Threads" configuration
    declare -a jobfiles
    for nodes_x_mpis_x_threads in ${_nodes_x_mpis_x_threads[@]}; do
        invoc[num_nodes]=$(ParseNodes "$nodes_x_mpis_x_threads")
        invoc[num_mpis]=$(ParseMPIs "$nodes_x_mpis_x_threads")
        invoc[num_threads]=$(ParseThreads "$nodes_x_mpis_x_threads")
        invoc[job]="$job_files_dir/$(GenerateJobfileName invoc)"

        GenerateJobfileHeader invoc > "${invoc[job]}"
        ExportEnv >> "${invoc[job]}"
        jobfiles+=("${invoc[job]}")
    done

    # Generate the job file entries for each instance
    for algorithm in ${_algorithms[@]}; do 
        mkdir -p "$log_files_dir/$algorithm"
        mkdir -p "$misc_files_dir/$algorithm"

        invoc[algorithm]=$algorithm
        invoc[algorithm_base]=$(GetAlgorithmBase "$algorithm")
        invoc[algorithm_version]=$(GetAlgorithmVersion "$algorithm")
        invoc[algorithm_arguments]=$(GetAlgorithmArguments "$algorithm")
        invoc[algorithm_build_options]=$(GetAlgorithmBuildOptions "$algorithm")

        LoadAlgorithm "${invoc[algorithm_base]}"
        invoc[first_algorithm_call]=1

        for nodes_x_mpis_x_threads in ${_nodes_x_mpis_x_threads[@]}; do
            invoc[num_nodes]=$(ParseNodes "$nodes_x_mpis_x_threads")
            invoc[num_mpis]=$(ParseMPIs "$nodes_x_mpis_x_threads")
            invoc[num_threads]=$(ParseThreads "$nodes_x_mpis_x_threads")
            invoc[job]="$job_files_dir/$(GenerateJobfileName invoc)"
            invoc[first_parallelism_call]=1

            for seed in ${_seeds[@]}; do
                invoc[seed]=$seed

                for epsilon in ${_epsilons[@]}; do 
                    invoc[epsilon]=$epsilon

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
                        invoc[first_algorithm_call]=0
                        invoc[first_parallelism_call]=0
                    done # k
                done # epsilon
            done # seed
        done # parallelism setting
    done # algorithm

    GenerateJobfileSubmission ${jobfiles[@]} >> $submit_impl_filename
}

