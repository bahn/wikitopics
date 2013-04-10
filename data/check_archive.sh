#!/bin/bash
for M in 2007 2008 2009 2010 2011 2012; do
	for MM in 01 02 03 04 05 06 07 08 09 10 11 12; do
		if [ ! -e archive/$M/$MM ]; then
			continue
		fi
		NUM=`ls archive/$M/$MM | wc -l`
		echo "$M $MM $NUM $[NUM/48] $[NUM/24]"
	done
done
