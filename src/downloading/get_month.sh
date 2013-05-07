#!/bin/bash
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -l mem_free=1G
#$ -l h_rt=20:00:00
# Download archived Wikipedia page view statistics for a specific month.
echo "$HOSTNAME\$ $0 $*"

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
    echo "Usage: `basename $0` [--dry-run] YEAR MONTH" >&2
    exit 1
fi

if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

YEAR=$1
MONTH=$2

#check the arguments
if [ $YEAR -lt 2007 -o $YEAR -gt 2100 ]; then
	echo Year $YEAR seems wrong. quitting...
	exit 1
fi

if [ $MONTH -lt 1 -o $MONTH -gt 12 ]; then
	echo Month $MONTH seems wrong. quitting...
	exit 1
fi

for i in `seq 9`; do
	if [ $MONTH -eq $i ]; then
		MONTH="0$i"
	fi
done

# save current working directory
CWD=`pwd`

# set working directory
WORKING="$WIKISTATS/downloading/$YEAR-$MONTH-$RANDOM"
ARCHIVE="$WIKISTATS/archive/$YEAR/$MONTH"
LOCATION="http://dumps.wikimedia.org/other/pagecounts-raw/$YEAR/$YEAR-$MONTH"
SCRIPT="$WIKITOPICS/src/downloading/check_md5sum.py"

if [ -e "$WORKING" ]; then
	echo "$WORKING already exists. cancel downloading..." >&2
	cd $CWD
	exit 1
fi

mkdir -p $WORKING
cd $WORKING

# reset the count of downloaded files
COUNT=0
CHECKSUM_FAILURE=0
VERIFAIL=0

# download the file listing
wget -nv -o wget.log $LOCATION

# print the log
if [ -e wget.log ]; then
    cat wget.log
    rm -f wget.log
fi

if [ -e "$YEAR-$MONTH" ]; then
	mv $YEAR-$MONTH index.html
fi

if [ ! -e index.html ]; then
    echo "failed while downloading the directory listing" >&2
	ls
	cd $CWD
	rm -rf $WORKING
	exit 1
fi

# extract the file listing
FILES=`grep $YEAR$MONTH index.html | sed -e 's/^.*href="//' -e 's/".*$//' | grep -v "^\."`
rm -f index.html

# get the md5 sums
wget -nv -o wget.log $LOCATION/md5sums.txt
if [ -e wget.log ]; then
	cat wget.log
	rm -f wget.log
fi

if [ ! -e md5sums.txt ]; then
	echo "failed downloading md5 sums. continuing to download..."
fi

for FILE in $FILES; do
	BASENAME=`basename $FILE`
	if [ $DRYRUN ]; then
		echo "download $FILE from $LOCATION/$BASENAME"
		COUNT=$[COUNT+1]
		continue
	fi

	mkdir -p $ARCHIVE
	if [ -e $ARCHIVE/$BASENAME ]; then
		if $SCRIPT md5sums.txt $BASENAME $ARCHIVE/$BASENAME; then
			COUNT=$[COUNT+1]
			continue
		else
			echo "$BASENAME exists but it has a wrong md5 sum. redownloading..."
		fi
	fi

	# download the pagecounts
	rm -f $BASENAME # delete if any previous downloaded file exists; otherwise it will interfere with downloading
	wget -nv -o wget.log $LOCATION/$BASENAME

	# print the log
	if [ -e wget.log ]; then
		cat wget.log
		rm -f wget.log
	fi

	if [ ! -e $BASENAME ]; then
		echo "failed to download $FILE" >&2
	else
		if [ $COUNT -gt 0 ]; then
			sleep 0.5
		fi
		COUNT=$[COUNT+1]
		if $SCRIPT md5sums.txt $BASENAME $BASENAME; then
			echo "$BASENAME successfully downloaded."
#			$WIKITOPICS/src/wiki/verify_stats.py $BASENAME
#			if [ $? -ne 0 ]; then
#				VERIFAIL=$[VERIFAIL+1]
#				echo "$BASENAME failed verification." >&2
#			fi
			mv $BASENAME $ARCHIVE
		else
			CHECKSUM_FAILURE=$[CHECKSUM_FAILURE+1]
			if [ ! -e "$ARCHIVE/$BASENAME" ]; then
				mv $BASENAME $ARCHIVE
				echo "$BASENAME downloaded but the checksum failed. the file was saved though."
			else
				rm $BASENAME
				echo "$BASENAME downloaded but the checksum failed. the file was discarded."
			fi
		fi
	fi
done

# check the number of downloaded files
if [ $[$COUNT % 48] -ne 0 ]; then
    echo "missing or redundant: $COUNT files downloaded." >&2
else
    echo "downloading $COUNT files succeeded."
fi

if [ $CHECKSUM_FAILURE -ne 0 ]; then
	echo "$CHECKSUM_FAILURE files failed the checksum test."
fi

if [ $VERIFAIL -ne 0 ]; then
	echo "$VERIFAIL files failed verification."
fi

# cd back to the previous working directory
cd $CWD

# remove the working directory
rm -rf $WORKING
