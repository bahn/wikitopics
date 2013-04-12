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

for YEAR in `seq 2007 2013`; do
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do
		./get_month.sh $YEAR $MONTH
	done
done
