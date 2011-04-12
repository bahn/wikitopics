#!/bin/bash
#$ -N filt_stats
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo filter_stats.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check the command-line options
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -lt 5 -o $# -gt 6 ]; then
    echo "Usage: $0 [--dry-run] LANG THRESHOLD SRC_DIR TRG_DIR START_DATE END_DATE" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

LANG_OPTION=$1 # don't use LANG or LANGUAGE, which are used by Perl
THRESHOLD=$2
SRC_DIR=$3
TRG_DIR=$4
START_DATE=`date --date "$5" +"%Y%m%d"`
if [ "$6" == "" ]; then
	END_DATE=$START_DATE
else
	END_DATE=`date --date "$6" +"%Y%m%d"`
fi
if [ $START_DATE \> $END_DATE ]; then
    echo "$START_DATE > $END_DATE" >&2
    exit 1
fi

# save the current working directory
CWD=`pwd`

# get full path for directories
if [ ! -e $SRC_DIR ]; then
    echo "$SRC_DIR not found" >&2
    exit 1
fi
cd $SRC_DIR; SRC_DIR=`pwd`

cd $CWD; mkdir -p $TRG_DIR; cd $TRG_DIR; TRG_DIR=`pwd`
if [ $SRC_DIR == $TRG_DIR ]; then
    echo "$SRC_DIR == $TRG_DIR" >&2
    exit 1
fi

cd $SRC_DIR
DATE=$START_DATE
while [ ! $DATE \> $END_DATE ]; do
    YEAR=${DATE:0:4}
    MONTH=${DATE:4:2}
    for FILE in *$DATE*.gz $YEAR/*$DATE*.gz $MONTH/*$DATE*.gz $YEAR/$MONTH/*$DATE*.gz; do
        if [ ! -e $FILE ]; then
            # if there is no files of the name of the given pattern, it returns pattern itself.
            # if such pattern found, pass.
            continue
        fi
        if [ $DRYRUN ]; then
            echo "$FILE > $TRG_DIR/$FILE"
        else
            mkdir -p `dirname $TRG_DIR/$FILE`
            gunzip -c $FILE | awk '$1=="'$LANG_OPTION'" && $3>'$THRESHOLD | gzip -c - > $TRG_DIR/$FILE
        fi
    done
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done

cd $CWD
