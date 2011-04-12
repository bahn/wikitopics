#!/bin/bash
#$ -N redir_stat
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
# memory requirements: 6G
echo redirect_stats.sh $* >&2

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
    echo "Usage: $0 [--dry-run] LANG REDIRECTS SRC_DIR TRG_DIR START_DATE END_DATE" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

LANG_OPTION=$1 # don't use LANG or LANGUAGE, which are used by Perl
REDIRECTS=$2
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
REDIR_SCRIPT="$WIKITOPICS/src/wikistats/redirect_stats.py"
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
    for FILE in *$DATE*.gz $MONTH/*$DATE*.gz $YEAR/*$DATE*.gz $YEAR/$MONTH/*$DATE*.gz; do
        if [ ! -e $FILE ]; then
            # if there is no files of the name of the given pattern, it returns pattern itself.
            # if such pattern found, pass.
            continue
        fi
        if [ $DRYRUN ]; then
            echo "$REDIR_SCRIPT $FILE > $TRG_DIR/$FILE"
        else
            mkdir -p `dirname $TRG_DIR/$FILE`
            $REDIR_SCRIPT -l $LANG_OPTION -r $REDIRECTS $FILE | gzip -c > $TRG_DIR/$FILE 
        fi
    done
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done

# cd back to the previous working directory
cd $CWD
