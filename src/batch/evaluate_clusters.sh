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
if [ "$1" == "-g" ]; then
	GOLD_DATA_SETS="$2"
	shift; shift
else
	GOLD_DATA_SETS="bahn ben ccb"
fi

if [ $# -lt 1 -o $# -gt 3 ]; then
	echo "USAGE: $0 [-g GOLD_DATA_SET] DATA_SET [START_DATE [END_DATE]]" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LANG_OPTION="en" # for now
DATA_SET="$1" # for now
if [ "$2" != "" ]; then
	START_DATE=`date --date "$2" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE="$2"
	fi

	if [ "$3" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$3" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE="$3"
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

perl -e 'print "test\tgold\tdate      \tgold\ttest\tprec\trec\tfscore\n";'
for FILE in $CLUSTER_ROOT/$DATA_SET/*.clusters $CLUSTER_ROOT/$DATA_SET/$LANG_OPTION/*/*.clusters; do
	if [ ! -f $FILE ]; then
		continue
	fi
	BASE_NAME=`basename $FILE` # cluster file
	DATE=${BASE_NAME:0:10}
	YEAR=${DATE:0:4}

	echo $DATE | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the file name is not a date
		continue
	fi
	# check the date is in the range
	if [ "$START_DATE" \> "$DATE" -o "$END_DATE" \< "$DATE" ]; then # if the date falls out of the range
		continue
	fi

	for GOLD_DATA_SET in $GOLD_DATA_SETS; do
		if [ "$GOLD_DATA_SET" == "$DATA_SET" ]; then
			continue
		fi
		GOLD_FILE="$CLUSTER_ROOT/$GOLD_DATA_SET/$LANG_OPTION/$YEAR/$BASE_NAME"
		if [ -f $GOLD_FILE ]; then
			$SCRIPT $GOLD_FILE $FILE
		fi
	done
done | $WIKITOPICS/src/cluster/eval/tabularize.pl
