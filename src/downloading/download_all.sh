#!/bin/bash
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -l mem_free=1G
#$ -l h_rt=120:00:00
#$ -q all.q@*

# Download archived Wikipedia page view statistics for a specific month.
echo "$HOSTNAME\$ $0 $*"

THISYEAR=`date "+%Y"`
THISMONTH=`date "+%m"`

date
for YEAR in `seq 2007 $THISYEAR`; do
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do
		if [ $YEAR == 2007 -a $MONTH -lt 12 -o $YEAR == $THISYEAR -a $MONTH -gt $THISMONTH ]; then
			continue
		fi
		./get_month.sh $YEAR $MONTH
	done
done
date
