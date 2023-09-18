if [[ $mode == "generate" ]]; then 
    infofile="INFO"
    echo "Generated at $(date) on $(hostname)" > "$infofile"

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
                    invoc[binary_disk]="$(GenerateBinaryName invoc)"
                    invoc[binary_kagen]="$(GenerateKaGenBinaryName invoc)"
                    invoc[timeout]=$(ParseTimelimit "$_timelimit_per_instance")

                    for k in ${_ks[@]}; do
                        if [[ "$_scale_ks" == "1" ]]; then 
                            k=$((k*nodes)) 
                        fi
                        invoc[k]=$k

                        # Graphs from disk
                        invoc[binary]="${invoc[binary_disk]}"
                        for graph in ${_graphs[@]}; do
                            invoc[graph]="$graph"
                            invoc[id]="$(GenerateInvocIdentifier invoc)"
                            invoc[log]="$log_files_dir/${invoc[algorithm]}/${invoc[id]}.log"
                            invoc[exe]="$(InvokePartitionerFromDisk invoc)"
                            invoc[exe]="$(GenerateJobfileEntry invoc)"
                            if [[ "$_timelimit_per_instance" != "" ]]; then 
                                invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${invoc[exe]}"
                            fi
                            echo "${invoc[exe]} >> ${invoc[log]} 2>&1" >> "${invoc[job]}"
                        done 

                        # KaGen graphs
                        invoc[binary]="${invoc[binary_kagen]}"
                        for i in ${!_kagen_graphs[@]}; do
                            kagen="$(ScaleKaGenGraph invoc "${_kagen_graphs[$i]}")"
                            kagen_arguments_arr=($kagen)
                            invoc[kagen_stringified]="$(echo "$kagen" | sed -E 's/filename=([^\/]*\/)*(.*)\.kargb/filename=\2/' | tr ' ' '-')"
                            invoc[kagen_arguments_stringified]="$(echo "$kagen" | tr ' ' ';')"
                            invoc[kagen_generator]="${kagen_arguments_arr[0]}"
                            invoc[kagen_arguments]="${kagen_arguments_arr[@]:1}"
                            invoc[id]="$(GenerateKaGenIdentifier invoc)"
                            invoc[log]="$log_files_dir/${invoc[algorithm]}/${invoc[id]}.log"
                            invoc[exe]="$(InvokePartitionerFromKaGen invoc)"
                            invoc[exe]="$(GenerateJobfileEntry invoc)"
                            if [[ "$_timelimit_per_instance" != "" ]]; then 
                                invoc[exe]="timeout -v $(ParseTimelimit "$_timelimit_per_instance")s ${invoc[exe]}"
                            fi

                            echo "${invoc[exe]} >> ${invoc[log]} 2>&1" >> "${invoc[job]}"
                        done # generator
                    done # k
                done # algorithm
            done # epsilon
        done # parallelism setting
    done

    GenerateJobfileSubmission ${jobfiles[@]} >> $submit_impl_filename
fi # $mode == "generate"

