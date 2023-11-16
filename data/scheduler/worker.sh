#!/bin/bash

# QUEUE_FILE must now be specified as an environment variable. can be done during sbatch with --export=QUEUE_FILE="workload_name.slot_id.queue"
TMP_QUEUE_FILE=$QUEUE_FILE".worker.tmp"
FAILED_QUEUE_FILE=$QUEUE_FILE".failed"
DEBUG_FILE=$QUEUE_FILE".debug"

module load compiler/gnu/9.2
module load mpi/openmpi/4.0
module load devel/python/3.7.4_gnu_9.2

MAX_IDLE_STEPS=100
STEP=0
SLEEP_TIME=3	#in seconds

if [ ! -f $QUEUE_FILE ]
then
	echo "Queue file" $QUEUE_FILE "not found, creating"
	touch $QUEUE_FILE
fi

while [ $STEP -lt $MAX_IDLE_STEPS ]
do
	if [ ! -s $QUEUE_FILE ]
	then
		STEP=$((STEP+1))
		#echo "Queue empty. Sleep for $SLEEP_TIME" >> $DEBUG_FILE
		sleep $SLEEP_TIME"s"
	else
		STEP=0
		LINE=$(head -n 1 $QUEUE_FILE)
		echo "Working on $LINE"
		if eval $LINE
		then
			echo "Finished $LINE"
		else
			echo "Failed $LINE"
			echo "$LINE" >> $FAILED_QUEUE_FILE
		fi
		tail -n +2 $QUEUE_FILE > $TMP_QUEUE_FILE && mv $TMP_QUEUE_FILE $QUEUE_FILE
	fi
done
