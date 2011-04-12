#!/bin/bash
#$ -N conv_topic
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo convert_topics.sh $* >&2

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
START_DATE=`date --date "$2" +"%Y%m%d"`
if [ "$3" == "" ]; then
	END_DATE="$START_DATE"
else
	END_DATE=`date --date "$3" +"%Y%m%d"`
fi

# don't use LANG or LANGUAGE -- they are used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`

# set working directories
TOPIC_DIR="$WIKITOPICS/data/topics/$DATA_SET"
HTML_ROOT="/export/people/bahn/wikitopics"
if [ "$DATA_SET" == "en" ]; then
    HTML_DIR="$HTML_ROOT"
else
    HTML_DIR="$HTML_ROOT/$DATA_SET"
fi

if [ ! -d "$TOPIC_DIR" ]; then
	echo "$TOPIC_DIR not found" >&2
	exit 1
fi
if [ ! -d "$HTML_ROOT" ]; then
	echo "$HTML_ROOT not found" >&2
	exit 1
fi

DATE=$START_DATE
while [ ! $END_DATE \< $DATE ]; do
    YEAR=${DATE:0:4}
    MONTH=${DATE:4:2}
    DAY=${DATE:6:2}
    TOPICFILE="$YEAR-$MONTH-$DAY.topics"
    HTMLFILE="$YEAR-$MONTH-$DAY.html"
    if [ -e "$TOPIC_DIR/$YEAR/$TOPICFILE" ]; then
        echo "convert_topics.py $TOPIC_DIR/$YEAR/$TOPICFILE > $HTML_DIR/$YEAR/$HTMLFILE" >&2
        mkdir -p $HTML_DIR/$YEAR
        $WIKITOPICS/src/topics/convert_topics.py -l $LANG_OPTION "$TOPIC_DIR/$YEAR/$TOPICFILE" > "$HTML_DIR/$YEAR/$HTMLFILE"
    fi
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done
