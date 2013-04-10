#!/bin/bash
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -l mem_free=1G
#$ -l h_rt=120:00:00
# Download archived Wikipedia page view statistics for a specific month.
set -x

echo "$HOSTNAME $0 $*"

../batch/get_monthly_stats.sh 2013 03
../batch/get_monthly_stats.sh 2013 02
../batch/get_monthly_stats.sh 2013 01
../batch/get_monthly_stats.sh 2012 12
../batch/get_monthly_stats.sh 2012 11
../batch/get_monthly_stats.sh 2012 10
