#!/bin/bash
# get_monthly_stats.sh
# Download archived Wikipedia page view statistics for a specific month.
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -ne 2 ]
then
    echo "Usage: get_monthly_stats.sh [--dry-run] YEAR MONTH" >&2
    echo "Given command-line options: $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

YEAR=$1
MONTH=`printf "%02d" $2`
LOGPREFIX="$YEAR-$MONTH"
WORKING="working_$YEAR$MONTH"
LOGFILE="log/monthly_stats_$YEAR$MONTH.log"

if [ -e $WORKING ]; then
	echo "$WORKING directory exists; cancelling downloading..." >&2
	echo "delete it and try again." >&2
	exit 1
fi

mkdir -p log
mkdir -p $WORKING
cd $WORKING

# download the directory listing
wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]
then
    cat wget.log >> ../log/monthly_stats_$YEAR$MONTH.log
    rm -f wget.log
fi

if [ ! -e index.html ]
then
    echo "$LOGPREFIX fail to download the directory listing" >&2
    cd ..
    exit
fi

FILES=`grep $YEAR$MONTH index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
rm -f index.html

if [ $DRYRUN ]; then
    for FILE in $FILES; do
        echo http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
    done
    cd ..
    rmdir $WORKING
    exit 0
fi

COUNT=0
for FILE in $FILES; do
    BASENAME=`basename $FILE`
    rm -f $BASENAME
    wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE

    if [ $? -ne 0 -o ! -e $BASENAME ]; then
        echo "$LOGPREFIX failed to download $FILE" >&2
        if [ -e $BASENAME ]; then
            rm -f $BASENAME
        fi
    else
        COUNT=$[COUNT+1]
    fi

    if [ -e wget.log ]; then
        cat wget.log >> ../$LOGFILE
        rm -f wget.log
    fi
done

if [ $[COUNT % 48] -ne 0 ]; then
    echo "$LOGPREFIX missing or redundant: $COUNT files are downloaded." >&2
else
    echo "$LOGPREFIX downloading $COUNT files succeeded."
fi

for FILE in $FILES; do
    BASENAME=`basename $FILE`
	if [ ! -e ../../archive/$YEAR/$MONTH/$BASENAME ]; then
        /mnt/data/wikitopics/src/wikistats/verify_stats.py $BASENAME > /dev/null
        if [ $? -ne 0 ]; then
            echo "$LOGPREFIX $BASENAME failed verification." >&2
        fi
		mkdir -p ../../archive/$YEAR/$MONTH
		mv $BASENAME ../../archive/$YEAR/$MONTH
	else
		if diff -q $BASENAME ../../archive/$YEAR/$MONTH/$BASENAME > /dev/null; then
			echo "$LOGPREFIX $BASENAME matched." >> ../$LOGFILE
			rm -f $BASENAME
		else
			echo "$LOGPREFIX $BASENAME does not match." >&2
			echo "$LOGPREFIX $BASENAME does not match." >> ../$LOGFILE
			echo $BASENAME >> FAILED
			/mnt/data/wikitopics/src/wikistats/verify_stats.py $BASENAME > /dev/null
			if [ $? -ne 0 ]; then
				echo "$LOGPREFIX $FILE failed verification." >&2
			fi
		fi
	fi
done

cd ..
rmdir $WORKING
