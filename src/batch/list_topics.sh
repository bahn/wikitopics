#!/bin/bash
#$ -N list_topic
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
# memory requirements: 6G
echo list_topics.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi
if [ "$WIKISTATS" == "" ]; then
	echo "Set the WIKISTATS environment variable first." >&2
	exit 1
fi
if [ ! -f "$WIKITOPICS/src/topics/convert_topics.py" ]; then
	echo "The $WIKITOPICS/src/topics/convert_topics.py script not found" >&2
	exit 1
fi

while [ "$1" == "-w" -o "$1" == "-l" -o "$1" == "-c" ]; do
	if [ "$1" == "-w" ]; then
		WINDOW_SIZE="$1 $2"
		shift; shift
	fi
	if [ "$1" == "-l" ]; then
		LIST_SIZE="$1 $2"
		shift; shift
	fi
	if [ "$1" == "-c" ]; then
		CUT_OFF="$1 $2"
		shift; shift
	fi
done

if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "Usage: $0 [-w WINDOW_SIZE] [-l LIST_SIZE] [-c CUT_OFF] DATA_SET START_DATE [END_DATE]" >&2
    echo "Given: $*" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE="$2"
if [ "$3" == "" ]; then
	END_DATE="$START_DATE"
else
	END_DATE=$3
fi

# don't use LANG or LANGUAGE -- they are used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
OUTPUT_DIR="/mnt/data/wikitopics/data/wikistats/process/$DATA_SET/redir/daily"
TOPIC_DIR="/mnt/data/wikitopics/data/topics/$DATA_SET"

$WIKITOPICS/src/wikistats/list_topics.py $WINDOW_SIZE $LIST_SIZE $CUT_OFF $LANG_OPTION $OUTPUT_DIR $TOPIC_DIR $START_DATE $END_DATE
$WIKITOPICS/src/batch/convert_topics.sh $DATA_SET $START_DATE $END_DATE
