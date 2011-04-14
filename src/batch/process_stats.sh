#!/bin/bash
#$ -N proc_stat
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
# process_stats.sh
echo "process_stats.sh $*" >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
while [ "$1" == "-r" ]; do
    if [ "$1" == "-r" ]; then
        REDIRECTS="$2"
        shift; shift
        if [ ! -e "$REDIRECTS" ]; then
            echo "Redirect file $REDIRECTS not found" >&2
            exit 1
        fi
    fi
done

if [ $# -lt 2 -o $# -gt 3 ]
then
    echo "Usage: $0 DATA_SET START_DATE [END_DATE]" >&2
    echo "Given command-line options: $*" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y%m%d"`
if [ "$3" == "" ]; then
	END_DATE=$START_DATE
else
	END_DATE=`date --date "$3" +"%Y%m%d"`
fi

# don't use LANG or LANGUAGE -- they are used by Perl.
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
if echo $DATA_SET | grep - > /dev/null; then
	FILTER="-f `echo $DATA_SET | sed -e 's/^.\+-//'`"
fi

INPUT_DIR="$WIKISTATS/archive"
OUTPUT_DIR="$WIKISTATS/process/$DATA_SET"
if [ "$DATA_SET" == "ko" ]; then
	REDIRECTS="$WIKIDUMP/kowiki-20110303/redirects.txt"
elif [ "$DATA_SET" == "ja" ]; then
	REDIRECTS="$WIKIDUMP/jawiki-20110308/redirects.txt"
	CUT_OFF="-c 100"
elif [ "$DATA_SET" == "en" ]; then
	REDIRECTS="$WIKIDUMP/enwiki-20110115/redirects.txt"
	CUT_OFF="-c 100"
elif [ "$DATA_SET" == "en-10" ]; then
	REDIRECTS="$WIKIDUMP/enwiki-20110115/redirects.txt"
fi

time $WIKITOPICS/src/batch/add_hourly_stats.sh $DATA_SET $START_DATE $END_DATE

if [ "$REDIRECTS" != "" ]; then
    time $WIKITOPICS/src/batch/redirect_stats.sh $DATA_SET $REDIRECTS $START_DATE $END_DATE
fi

time $WIKITOPICS/src/batch/list_topics.sh $CUT_OFF $DATA_SET $START_DATE $END_DATE
