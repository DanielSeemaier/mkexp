if [[ $mode == "progress" ]]; then
    num_total_logs=$(( \
        ${#_nodes_x_mpis_x_threads[@]} * \
        ${#_seeds[@]} * \
        ${#_epsilons[@]} * \
        ${#_ks[@]} * \
        (${#_graphs[@]} + ${#_kagen_graphs[@]}) \
    ))
    num_total_logs_per_seed=$((num_total_logs / ${#_seeds[@]}))

    max_len=$(tput cols)
    name_max_len=20

    name_len=0
    for algorithm in ${_algorithms[@]}; do
        if (( ${#algorithm} > $name_len )); then 
            name_len=${#algorithm}
        fi
    done
    if (( name_len > name_max_len )); then 
        name_len=$name_max_len
    fi

    progress_len=$((max_len - name_len - 18))

    OutputProgressLine() {
        local dir="$1"
        local name="$2"
        local filter="$3"
        local n="$4"

        cur=$(ls -1 "$dir" | grep "$filter" | wc -l)
        filled=$((cur * progress_len / n))
        if (( ${#name} > $name_max_len - 4 )); then 
            printf "%.$((name_len-3))s... " "$name"
        else 
            printf "%-${name_len}s " "$name"
        fi
        printf "[%-${progress_len}s]" $(printf "%${filled}s" | tr ' ' '#')
        if (( cur == 0 )); then
            printf " INACTIVE 00:00"
        else 
            oldest_file=$(find "$dir" -name "*$filter*" -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -d ' ' -f 2)
            newest_file=$(find "$dir" -name "*$filter*" -type f -printf '%T+ %p\n' | sort | tail -n 1 | cut -d ' ' -f 2)
            oldest_file_time=$(date -r "$oldest_file" +%s)
            newest_file_time=$(date -r "$newest_file" +%s)
            time_diff=$((newest_file_time - oldest_file_time))
            hours=$((time_diff / 3600))
            minutes=$(( (time_diff % 3600) / 60 ))
            if (( cur == n )); then 
                printf " DONE     "
            else 
                printf " ACTIVE   "
            fi
            printf "%02d:%02d" $hours $minutes
        fi
        printf "\n"
    }

    for algorithm in ${_algorithms[@]}; do
        dir="$log_files_dir/$algorithm"

        OutputProgressLine "$dir" "$algorithm" "" "$num_total_logs"
        if (( ${#_seeds[@]} > 1 )); then 
            for seed in ${_seeds[@]}; do
                prefix=" |- "
                if (( seed == ${_seeds[-1]} )); then 
                    prefix=" \`- "
                fi
                OutputProgressLine "$dir" "${prefix}Seed $seed" "seed$seed" "$num_total_logs_per_seed"
            done
        fi
    done
fi

