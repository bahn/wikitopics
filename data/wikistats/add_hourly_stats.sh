#!/bin/bash
# add_hourly_stats.sh
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ "$1" == "-l" ]; then
    LANG="$1 $2"
    shift; shift
fi
if [ $# -ne 4 ]; then
    echo "Usage: $0 [--dry-run] [-l LANG] SRC_DIR TRG_DIR FROM_DATE UNTIL_DATE" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

CWD=`pwd`
SRC_DIR=$1
TRG_DIR=$2
FROM_DATE=`date --date "$3" +"%Y%m%d"`
UNTIL_DATE=`date --date "$4" +"%Y%m%d"`

# get full path for directories
cd `dirname $0`/../../src/wikistats; ADD_SCRIPT=`pwd`"/add_stats.py"
cd $CWD; cd $SRC_DIR; SRC_DIR=`pwd`
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
    DAY=${DATE:6:2}
    if [ -d $YEAR/$MONTH ]; then
        SRC_PREFIX="$SRC_DIR/$YEAR/$MONTH/"
    elif [ -d $MONTH ]; then
        SRC_PREFIX="$SRC_DIR/$MONTH/"
    else
        SRC_PREFIX="$SRC_DIR/"
    fi
    if [ "`basename $TRG_DIR`" == "$YEAR" ]; then
        TRG_PREFIX="$TRG_DIR/"
    else
        TRG_PREFIX="$TRG_DIR/$YEAR/"
    fi

# Don't take all the files with the date, and only take one file for each hour.
# Sometimes there are (almost) duplicate stats file due to some unknown error.
    FILES=""
    for I in `seq 0 23`; do
        HOUR=`printf "%02d" $I`
        FILE="`ls -d -x -1 $SRC_PREFIX*$DATE-$HOUR*.gz 2>/dev/null | head -1`"
        if [ "$FILE" != "" -a -e "$FILE" ]; then
            FILES="$FILES $FILE"
        fi
    done
    if [ $DRYRUN ]; then
        echo $ADD_SCRIPT
        echo $FILES | tr " " "\n"
    fi
    if [ "$FILES" != "" ]; then
        mkdir -p $TRG_PREFIX
        if [ $DRYRUN ]; then
            echo "${TRG_PREFIX}pagecounts-$DATE.gz"
        else
            $ADD_SCRIPT $LANG $FILES | gzip -c - > "${TRG_PREFIX}pagecounts-$DATE.gz"
        fi
    fi
 
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done

cd $CWD
