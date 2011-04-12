#!/bin/bash
# get_monthly_stats.sh
# Download archived Wikipedia page view statistics for a specific month.

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "the WIKITOPICS environment variable not set" >&2
	exit 1
fi
if [ "$WIKISTATS" == "" ]; then
	echo "the WIKISTATS environment variable not set" >&2
	exit 1
fi

# check command-line options
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

# save current working directory
CWD=`pwd`

# set working directory
WORKING="$YEAR-$MONTH-$RANDOM"
ARCHIVE="$WIKISTATS/archive"

cd $WIKISTATS/downloading
if [ -e "$WORKING" ]; then
	echo "$WORKING already exists. cancel downloading..." >&2
	cd $CWD
	exit 1
fi

mkdir -p $WORKING
cd $WORKING

# reset the count of downloaded files
COUNT=0

wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]; then
    cat wget.log >> download-log.txt
    rm -f wget.log
fi

if [ ! -e index.html ]; then
    echo "fail to download the directory listing" >&2
else
	FILES=`grep $YEAR$MONTH index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
	rm -f index.html

	if [ $DRYRUN ]; then
		for FILE in $FILES; do
			echo http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
		done
	else
		for FILE in $FILES; do
			BASENAME=`basename $FILE`
			mkdir -p $ARCHIVE/$YEAR/$MONTH
			rm -f $BASENAME # delete if any previous downloaded file exists; otherwise it will interfere with downloading
			wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
			if [ -e wget.log ]; then
				cat wget.log >> download-log.txt
				rm -f wget.log
			fi
			if [ -e $BASENAME ]; then
				echo "failed to download $FILE" >&2
			else
				COUNT=$((COUNT+1))
				if [ ! -e "$ARCHIVE/$YEAR/$MONTH/$BASENAME" ]; then
					mv $BASENAME $ARCHIVE/$YEAR/$MONTH
				else
					$WIKITOPICS/src/wikistats/verify_stats.py $BASENAME > /dev/null
					if [ $? -ne 0 ]; then
						echo "$FILE failed verification." >&2
					fi
					if diff -q $BASENAME $ARCHIVE/$YEAR/$MONTH/$BASENAME > /dev/null; then
						rm -f $BASENAME
					else
						echo "previous downloaded $BASENAME does not match with the one just downloaded." >&2
					fi
				fi
			fi
			if [ -e wget.log ]; then
				cat wget.log >> download-log.txt
				rm -f wget.log
			fi
		done
	fi
fi

# check the number of downloaded files
if [ $[$COUNT % 48] -ne 0 ]
then
    echo "missing or redundant: $COUNT files downloaded." >&2
else
    echo "downloading $COUNT files succeeded."
fi

# remove the working directory
mkdir -p $WIKISTATS/downloading/log
mv donwload-log.txt $WIKISTATS/downloading/log/download-log-$YEAR-$MONTH.txt
cd ..
rmdir $WORKING

# cd back to the previous working directory
cd $CWD
