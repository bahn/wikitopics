#!/bin/bash
#$ -N get_daily
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid/
#$ -l h_vmem=1G

echo $HOSTNAME get_daily_stats.sh $* >&2
# Download Wikipedia page view statistics for a specific day.

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
if [ $# -ne 1 ]; then
    echo "Usage: $0 [--dry-run] DATE"
    exit 1
fi

if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

DATE=`date --date $1 +"%Y%m%d"`
YEAR=${DATE:0:4}
MONTH=${DATE:4:2}
DAY=${DATE:6:2}

# save current working directory
CWD=`pwd`

# set working directory
WORKING="$DATE-$RANDOM"
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

wget -nv -o wget.log http://dammit.lt/wikistats/
if [ -e wget.log ]; then
    cat wget.log >> download-log.txt
    rm -f wget.log
fi

if [ ! -e index.html ]; then
    echo "fail to download the directory listing" >&2
else
	FILES=`grep $DATE index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
	rm -f index.html

	if [ $DRYRUN ]; then
		for FILE in $FILES; do
			COUNT=$((COUNT+1))
			echo $FILE
		done
	else
		for FILE in $FILES; do
			BASENAME=`basename $FILE`
			if [ -e "$ARCHIVE/$YEAR/$MONTH/$BASENAME" ]; then
				echo "$BASENAME already exists; cancel downloading" >&2
				continue
			fi
			mkdir -p $ARCHIVE/$YEAR/$MONTH
			rm -f $BASENAME # delete if any previous downloaded file exists; otherwise it will interfere with downloading
			wget -nv -o wget.log http://dammit.lt/wikistats/$FILE
			if [ -e wget.log ]; then
				cat wget.log >> download-log.txt
				rm -f wget.log
			fi
			if [ ! -e $BASENAME ]; then
				echo "failed to download $FILE" >&2
			else
				COUNT=$((COUNT+1))
				$WIKITOPICS/src/wiki/verify_stats.py $BASENAME > /dev/null
				if [ $? -ne 0 ]; then
					echo "$FILE failed verification." >&2
				fi
				mv $BASENAME $ARCHIVE/$YEAR/$MONTH
			fi
		done
	fi
fi

wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]; then
    cat wget.log >> download-log.txt
    rm -f wget.log
fi

if [ ! -e index.html ]; then
    echo "fail to download the directory listing http://dammit.lt/wikistats/archive/$YEAR/$MONTH/" >&2
else
	FILES=`grep $DATE index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
	rm -f index.html

	if [ $DRYRUN ]; then
		for FILE in $FILES; do
			COUNT=$((COUNT+1))
			echo $FILE
		done
	else
		for FILE in $FILES; do
			BASENAME=`basename $FILE`
			if [ -e $ARCHIVE/$YEAR/$MONTH/$BASENAME ]; then
				echo "$BASENAME already exists; cancel downloading" >&2
				continue
			fi
			mkdir -p $ARCHIVE/$YEAR/$MONTH
			rm -f $BASENAME # delete if any previous downloaded file exists; otherwise it will interfere with downloading
			wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
			if [ -e wget.log ]; then
				cat wget.log >> download-log.txt
				rm -f wget.log
			fi
			if [ ! -e $BASENAME ]; then
				echo "failed to download $FILE" >&2
			else
				COUNT=$((COUNT+1))
				$WIKITOPICS/src/wiki/verify_stats.py $BASENAME > /dev/null
				if [ $? -ne 0 ]; then
					echo "$FILE failed verification." >&2
				fi
				mv $BASENAME $ARCHIVE/$YEAR/$MONTH
			fi
		done
	fi
fi

# check the number of downloaded files
if [ $[COUNT % 48] -ne 0 ]; then
    echo "missing or redudant: $COUNT files downloaded." >&2
fi

# remove the working directory
mkdir -p $WIKISTATS/downloading/log
mv download-log.txt $WIKISTATS/downloading/log/download-log-$DATE.txt
cd ..
rmdir $WORKING

# cd back to the previous working directory
cd $CWD
