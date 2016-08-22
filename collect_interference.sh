#!/bin/bash

DIR=data-${SUFFIX}

mkdir -p $DIR

if [ "x$ITERATIONS" == "x" ] ; then
	ITERATIONS=20
fi

for i in 16 40 80 160 `seq 320 320 20480` ; do
	FILE=${DIR}/${i}.data
	echo -n > $FILE
	for j in `seq $ITERATIONS` ; do
		./atomic-interference $i | grep "Copy BW" | sed 's/[^0-9]*\([0-9\.]*\).*/\1/' | tee -a $FILE
	done
done
