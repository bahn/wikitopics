#!/bin/bash
YEAR=`date "+%Y"`
for M in `seq 2007 $YEAR`; do
	for MM in 01 02 03 04 05 06 07 08 09 10 11 12; do
		if [ ! -e wikistats/archive/$M/$MM ]; then
			continue
		fi
		NUM=`ls wikistats/archive/$M/$MM | wc -l`
		DAYS=$[NUM/24]
		if [ "$DAYS" -ge 32 ]; then
			DAYS=$[NUM/48]
		fi
		echo "$M $MM $DAYS $NUM"
	done
done
