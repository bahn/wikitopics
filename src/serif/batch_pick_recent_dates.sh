#!/usr/bin/env bash
#
# batch_pick_recent_dates.sh
if [ "$2" == "" ] || [ "$1" == "" ]
then
    echo "Usage: $0 /path/to/directory/ YYYY-MM-DD"
    exit 1
fi

for sgm in `find $1 -name "*.sgm"`
do
	short_sgm=`echo $sgm | perl -lane 's/[^\/]*\///g; s/\.apf$//; s/\.sgm$//; s/\.sentences//; print'`
    if [ -f $sgm.apf ]
    then
	best_sentence=`./pick_recent_date.py $2 $sgm $sgm.apf`
	echo "$short_sgm $best_sentence" | perl -lane 's/^(\S+) /\1\t/; print'
    else
	echo "# $sgm.apf does not exist"
    fi
done
