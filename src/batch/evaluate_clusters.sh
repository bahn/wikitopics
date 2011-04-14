#!/bin/bash
#$ -N eval_clust
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo evaluate_clusters.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ $# -gt 2 ]; then
	echo "USAGE: $0 [-v] [START_DATE [END_DATE]]" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LANG_OPTION="en" # for now
DATA_SET="kmeans" # for now
if [ "$1" != "" ]; then
	START_DATE=`date --date "$1" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE=$1
	fi

	if [ "$2" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$2" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE=$2
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi
SCRIPT="$WIKITOPICS/src/cluster/eval/eval.py"
if [ ! -f "$SCRIPT" ]; then
	echo "the $SCRIPT script not found" >&2
	exit 1
fi

CLUSTER_ROOT="$WIKITOPICS/data/clusters"

for FILE in $CLUSTER_ROOT/$DATA_SET/$LANG_OPTION/*/*.clusters; do
	YEAR=`dirname $FILE`; YEAR=`basename $YEAR`
	BASE_NAME=`basename $FILE`
	DATE=${BASE_NAME:0:10}
	echo $YEAR $BASE_NAME $DATE $FILE

	echo $DATE | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the file name is not a date
		continue
	fi
	# check the date is in the range
	if [ "$START_DATE" \> "$DATE" -o "$END_DATE" \< "$DATE" ]; then # if the date falls out of the range
		continue
	fi

	for GOLD_DATA_SET in ben bahn ccb; do
		GOLD_FILE="$CLUSTER_ROOT/$GOLD_DATA_SET/$LANG_OPTION/$YEAR/$BASE_NAME"
		if [ -f $GOLD_FILE ]; then
			$SCRIPT $GOLD_FILE $FILE
		fi
	done
done
#| $WIKITOPICS/src/cluster/eval/tabularize.pl
