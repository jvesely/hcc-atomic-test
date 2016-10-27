#!/bin/bash

set -o pipefail

if [ "x$SUFFIX" == "x" ] ; then
	SUFFIX=`uname -n`
fi

DIR=data-${SUFFIX}

mkdir -p $DIR

function run()
{
	./atomic-interference $1 | grep "Copy BW" | sed 's/[^0-9]*\([0-9\.]*\).*/\1/' | tee -a $2
}

if [ "x$ITERATIONS" == "x" ] ; then
	ITERATIONS=20
fi

for i in 0 16 40 80 160 `seq 320 320 20480` ; do
	FILE=${DIR}/${i}.data
	echo -n > $FILE
	for j in `seq $ITERATIONS` ; do
		if ! run $i $FILE; then
			rm -v $FILE;
			exit 1;
		fi
	done
done
