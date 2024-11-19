#!/bin/bash 

if [[ "$wrapper" == "Taskset" ]]; then
    for job in ${JOBS[@]}; do
        echo "taskset -c 0-$(( $NUM_THREADS - 1 )) $job"
    done
elif [[ "$wrapper" == "Plain" ]]; then
    for job in ${JOBS[@]}; do
        echo "$job"
    done
elif [[ "$wrapper" == "OpenMPI" ]]; then
    for job in ${JOBS[@]}; do
        echo "mpirun -n $NUM_PROCESSES --bind-to core --map-by socket:PE=$NUM_THREADS $job"
    done
elif [[ "$wrapper" == "OpenMP" ]]; then
    for job in ${JOBS[@]}; do
        echo "OMP_PROC_BIND=spread OMP_PLACES=threads OMP_NUM_THREADS=$NUM_THREADS $job"
    done
else
    Error "fatal: unsupported wrapper $wrapper"
fi
