#!/bin/bash

set -o pipefail

if [ "x$SUFFIX" == "x" ] ; then
	SUFFIX=`uname -n`
fi

DIR=data-${SUFFIX}

mkdir -p $DIR

function run()
{
	./atomic-interference $1 | tee -a $2.log | grep "Copy BW" | sed 's/[^0-9]*\([0-9\.]*\).*/\1/' | tee -a $2
}

if [ "x$ITERATIONS" == "x" ] ; then
	ITERATIONS=20
fi

for i in 0 16 40 80 160 `seq 320 320 20480` ; do
	FILE=${DIR}/${i}.data
	LOG_FILE=${DIR}/${i}.log
	rm -f $FILE $LOG_FILE
	until [ -f $FILE ] ; do
		for j in `seq $ITERATIONS` ; do
			if ! run $i $FILE; then
				GPU_UTIL=`radeontop -d - -l 1 | grep -o 'gpu[^,]*'`
				if [ "$GPU_UTIL" != "gpu 0.00%" ]; then
					echo "ERROR: program crashed and the GPU is in not recoverable state. Exiting"
					rm -v $FILE $LOG_FILE
					exit 1
				else
					rm -vf $FILE $LOG_FILE
					break
				fi
			fi
		done
	done
done
