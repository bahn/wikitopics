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
    echo "Usage: $0 [-r REDIRECTS] DATA_SET START_DATE [END_DATE]" >&2
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

time $WIKITOPICS/src/batch/add_hourly_stats.sh -l $LANG_OPTION $INPUT_DIR $OUTPUT_DIR/daily $START_DATE $END_DATE

if [ "$REDIRECTS" != "" ]; then
    time $WIKITOPICS/src/batch/redirect_stats.sh $LANG_OPTION $REDIRECTS $OUTPUT_DIR/daily $OUTPUT_DIR/redir/daily $START_DATE $END_DATE
fi
