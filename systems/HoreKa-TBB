#!/bin/bash 
. "$script_pwd/../systems/Generic"

# HoreKa without OpenMP: unsets all OMP_* env variables
# This is really important when using TBB

HOREKA_OPENMPI_VERSION="4.0"
CUSTOM_CMAKE_FLAGS="-DTBB_DIR=/hkfs/home/software/all/toolkit/Intel_OneAPI/tbb/2021.2.0/lib/cmake/tbb -DMPFR_INCLUDE_DIR=$HOME/usr/include -DMPFR_LIBRARIES=$HOME/usr/lib/libmpfr.so -DSAMPLING_USE_MKL=Off $CUSTOM_CMAKE_FLAGS"

SetupBuildEnv() {
    return
}

UploadExperiment() {
    echo "Error: unsupported"
}

DownloadExperiment() {
    echo "Error: unsupported"
}

GenerateJobfileHeader() {
    local -n args=$1

    if (( $((args[num_mpis] * args[num_threads])) > 78 )); then 
       >&2 echo "Error: too many MPI processes * threads"
       exit 1
    fi
    if (( ${args[num_threads]} > 39 )); then
        >&2 echo "Error: cannot use more threads than available on a single socket"
    fi

    >&2 echo -e "Generating jobfile header for parallel execution mode $ARGS_COLOR${args[num_nodes]}x${args[num_mpis]}x${args[num_threads]}$NO_COLOR:"
    >&2 echo -e "  --nodes=$ARGS_COLOR${args[num_nodes]}$NO_COLOR"
    >&2 echo -e "  --ntasks=$ARGS_COLOR$((args[num_nodes]*args[num_mpis]))$NO_COLOR"
    >&2 echo -e "  --cpus-per-task=$ARGS_COLOR${args[num_threads]}$NO_COLOR"
    >&2 echo -e "  --ntasks-per-node=$ARGS_COLOR${args[num_mpis]}$NO_COLOR"
    >&2 echo -e "  --time=$ARGS_COLOR${args[timelimit]}$NO_COLOR"
    >&2 echo "  --export=ALL"
    >&2 echo "  --mem=230gb"
    >&2 echo "  --partition=cpuonly"

    echo "#!/bin/bash"
    echo "#SBATCH --nodes=${args[num_nodes]}"
    echo "#SBATCH --ntasks=$((args[num_nodes]*args[num_mpis]))"
    echo "#SBATCH --cpus-per-task=${args[num_threads]}"
    echo "#SBATCH --ntasks-per-node=${args[num_mpis]}"
    echo "#SBATCH --time=${args[timelimit]}"
    echo "#SBATCH --export=ALL"
    echo "#SBATCH --mem=230gb"
    echo "#SBATCH --partition=cpuonly"

    if [[ "${args[mpi]}" == "OpenMPI" ]]; then 
        >&2 echo "Running jobs with OpenMPI version ${HOREKA_OPENMPI_VERSION}"
        echo "module load mpi/openmpi/${HOREKA_OPENMPI_VERSION}"
    fi

    >&2 echo "Unsetting OpenMP environment variables OMP_*"
    echo "unset OMP_NUM_THREADS"
    echo "unset OMP_PROC_BIND"
    echo "unset OMP_PLACES"

    >&2 echo ""
}

GenerateJobfileEntry() {
    local -n args=$1

    if [[ "${args[print_wrapper]}" == "1" ]]; then
        >&2 echo -e "Wrapping calls with ${args[mpi]} for algorithm '$ALGO_COLOR${args[algorithm]}$NO_COLOR', $ARGS_COLOR${args[num_nodes]}x${args[num_mpis]}x${args[num_threads]}$NO_COLOR:"
    fi

    case "${args[mpi]}" in
        none)
            >&2 echo "Error: application must be run with MPI"
            exit 1
            ;;
        OpenMPI)
            if [[ "${args[print_wrapper]}" == "1" ]]; then
                >&2 echo -e "  - mpirun -n $ARGS_COLOR$((args[num_nodes]*args[num_mpis]))$NO_COLOR --bind-to core --map-by socket:PE=$ARGS_COLOR${args[num_threads]}$NO_COLOR <call>"
            fi
            echo "mpirun -n $((args[num_nodes]*args[num_mpis])) --bind-to core --map-by socket:PE=${args[num_threads]} ${args[exe]}"
            ;;
        *)
            >&2 echo "Error: unsupported MPI ${args[mpi]}"
            exit 1
    esac

    if [[ "${args[print_wrapper]}" == "1" ]]; then
        >&2 echo ""
    fi
}

GenerateJobfileSubmission() {
    for jobfile in ${@}; do 
        echo "sbatch $jobfile"
    done
}

