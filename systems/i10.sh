#!/bin/bash 

echo "#SBATCH --job-name=$EXPERIMENT_NAME-$ITERATION"
echo "#SBATCH --output=$EXPERIMENT_NAME-$ITERATION.out"
echo "#SBATCH --error=$EXPERIMENT_NAME-$ITERATION.err"
echo "#SBATCH --exclusive"

prefix=""

if [[ "$wrapper" == "Taskset" ]]; then
    prefix="taskset -c 0-$(( $NUM_THREADS - 1 ))"
elif [[ "$wrapper" == "Plain" ]]; then
    prefix=""
elif [[ "$wrapper" == "OpenMPI" ]]; then
    prefix="mpirun -n $NUM_PROCESSES --bind-to core --map-by socket:PE=$NUM_THREADS"
elif [[ "$wrapper" == "OpenMP" ]]; then
    prefix="OMP_PROC_BIND=spread OMP_PLACES=threads OMP_NUM_THREADS=$NUM_THREADS"
else
    Error "fatal: unsupported wrapper $wrapper"
fi

for job in ${JOBS[@]}; do
    echo "$prefix $job"
done
