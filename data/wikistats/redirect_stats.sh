#!/bin/bash
# redirect_stats.sh
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -ne 6 ]; then
    echo "Usage: $0 LANG REDIRECTS SRC_DIR TRG_DIR FROM_DATE UNTIL_DATE" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

CWD=`pwd`
LANG=$1
REDIRECTS=$2
SRC_DIR=$3
TRG_DIR=$4
FROM_DATE=`date --date "$5" +"%Y%m%d"`
UNTIL_DATE=`date --date "$6" +"%Y%m%d"`

# get full path for directories
cd `dirname $0`/../../src/wikistats; REDIR_SCRIPT=`pwd`"/redirect_stats.py"
cd $SRC_DIR; SRC_DIR=`pwd`
cd $CWD; mkdir -p $TRG_DIR; cd $TRG_DIR; TRG_DIR=`pwd`
cd $CWD

if [ $FROM_DATE \> $UNTIL_DATE ]; then
    echo "$FROM_DATE > $UNTIL_DATE" >&2
    exit 1
fi

if [ ! -e $SRC_DIR ]; then
    echo "$SRC_DIR not found" >&2
    exit 1
fi

if [ $SRC_DIR == $TRG_DIR ]; then
    echo "$SRC_DIR == $TRG_DIR" >&2
    exit 1
fi

cd $SRC_DIR
DATE=$FROM_DATE
while [ ! $DATE \> $UNTIL_DATE ]; do
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
            $REDIR_SCRIPT -l $LANG -r $REDIRECTS $FILE > $TRG_DIR/$FILE 
        fi
    done
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done

cd $CWD
