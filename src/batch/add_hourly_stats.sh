#!/bin/bash
#$ -N add_stats
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo add_hourly_stats.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check the command-line options
while [ "$1" == "--dry-run" -o "$1" == "-l" -o "$1" == "-f" ]; do
    if [ "$1" == "--dry-run" ]; then
        DRYRUN=1
        shift
    elif [ "$1" == "-l" ]; then
        LANG_OPTION="$1 $2" # don't use LANG or LANGUAGE, which are used by Perl
        shift; shift
    elif [ "$1" == "-f" ]; then
        FILTER="$1 $2"
        shift; shift
    fi
done
if [ $# -lt 3 -o $# -gt 4 ]; then
    echo "Usage: $0 [--dry-run] [-l LANG] [-f FILTER] SRC_DIR TRG_DIR START_DATE [END_DATE]" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
SRC_DIR=$1
TRG_DIR=$2
START_DATE=`date --date "$3" +"%Y%m%d"`
if [ "$4" == "" ]; then
	END_DATE=$START_DATE
else
	END_DATE=`date --date "$4" +"%Y%m%d"`
fi
if [ $START_DATE \> $END_DATE ]; then
    echo "$START_DATE > $END_DATE" >&2
    exit 1
fi

if [ $DRYRUN ]; then
    echo "Running a dry run..."
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
    if [ "$DRYRUN" -a "$FILES" != "" ]; then
        echo $FILES | tr " " "\n"
    fi
    if [ "$FILES" != "" ]; then
        if [ $DRYRUN ]; then
            echo "> ${TRG_PREFIX}pagecounts-$DATE.gz"
        else
			mkdir -p $TRG_PREFIX
			$WIKITOPICS/src/wiki/add_stats.py $LANG_OPTION $FILTER $FILES | gzip -c - > "${TRG_PREFIX}pagecounts-$DATE.gz"
        fi
    fi
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done

# cd back to the previous working directory
cd $CWD
