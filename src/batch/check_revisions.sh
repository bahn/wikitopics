#!/bin/bash
#$ -N check_rev
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=1G

echo $HOSTNAME check_revisions.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi
if [ "$WIKISTATS" == "" ]; then
	echo "Set the WIKISTATS environment variable first." >&2
	exit 1
fi
if [ ! -f "$WIKITOPICS/src/wiki/check_revisions.py" ]; then
	echo "The $WIKITOPICS/src/wiki/check_revisions.py script not found" >&2
	exit 1
fi

# check command-line options
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
    echo "Usage: $0 DATA_SET START_DATE [END_DATE]" >&2
    echo "Given: $*" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y-%m-%d"`
if [ "$3" == "" ]; then
	END_DATE="$START_DATE"
else
	END_DATE=`date --date "$3" +"%Y-%m-%d"`
fi

# don't use LANG or LANGUAGE -- they are used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`

DATE=$START_DATE
while [ ! $END_DATE \< $DATE ]; do
    YEAR=${DATE:0:4}
    MONTH=${DATE:5:2}
    DAY=${DATE:8:2}
	TOPIC_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics"
	REDIRECTS_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.redirects"
	ARTICLES_RESOLVED="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.articles.list"
	FAILED_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics.failed"
    if [ -e "$TOPIC_FILE" ]; then
		echo check_revisions.py $LANG_OPTION $DATE $TOPIC_FILE $REDIRECTS_FILE $ARTICLES_RESOLVED $FAILED_FILE >&2
		$WIKITOPICS/src/wiki/check_revisions.py $LANG_OPTION $DATE $TOPIC_FILE $REDIRECTS_FILE $ARTICLES_RESOLVED $FAILED_FILE
    fi
    DATE=`date --date "$DATE 1 day" +"%Y-%m-%d"`
done
