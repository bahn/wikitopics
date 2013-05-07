#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
#$ -o /export/a05/wikitopics/src/pageviews/log/
echo "$HOSTNAME:`pwd`\$ $0 $*"

if [ $# -lt 3 ]; then
	echo "usage: `basename $0` [LIST_FILE|PAGE_TITLE] YEAR MONTH [DAY [HOUR]] [OUTPUT_PATH]"
	exit
fi

DELETE_LATER=
if [ ! -e "$1" ]; then
	LIST_FILE=list-$RANDOM.txt
	echo $1 > $LIST_FILE
	DELETE_LATER=1
else
	LIST_FILE=$1
fi

if [ ! -s "$LIST_FILE" ]; then
	echo the $LIST_FILE file is empty
	exit 1
fi

if [ `awk 'NF>1 { print NF; exit }' $LIST_FILE` ]; then
	echo $LIST_FILE is not a proper list
	exit 1
fi

YEAR=$2
MONTH=$3
THISYEAR=`date "+%Y"`
THISMONTH=`date "+%m"`
shift; shift; shift

if [ "$YEAR" -lt 2007 -o "$YEAR" -gt $THISYEAR ] 2> /dev/null; then
	echo "Year $YEAR is out of range"
	exit 1
fi

if [ $? -eq 2 ]; then
	echo "Year $YEAR must be a number"
	exit 1
fi

if [ "$YEAR" -eq 2007 -a "$MONTH" -lt 12 -o "$YEAR" -eq "$THISYEAR" -a "$MONTH" -gt "$THISMONTH" -o "$MONTH" -lt 1 -o "$MONTH" -gt 12 ] 2> /dev/null; then
	echo "Pair of year-month $YEAR-$MONTH is out of range"
	exit 1
fi

if [ $? -eq 2 ]; then
	echo "Month $MONTH must be a number"
	exit 1
fi

DAY=
if [ "$1" != "" ]; then
	if [ "$1" -ge 1 -o "$1" -le 31 ] 2> /dev/null; then
		DAY=$1
		shift
	elif [ $? -eq 1 ]; then
		echo "Day $1 is out of range"
		exit 1
	fi
fi

HOUR=
if [ "$1" != "" ]; then
	if [ $1 -ge 0 -o $1 -lt 24 ] 2> /dev/null; then
		HOUR=$1
		shift
	elif [ $? -eq 1 ]; then
		echo "Hour $1 is out of range"
		exit 1
	fi
fi

# make each numbers two-digited
for i in `seq 9`; do
	if [ "$MONTH" -eq $i ] 2> /dev/null; then
		MONTH="0$i"
	fi
	if [ "$DAY" -eq $i ] 2> /dev/null; then
		DAY="0$i"
	fi
	if [ "$HOUR" -eq $i ] 2> /dev/null; then
		HOUR="0$i"
	fi
done

if [ "$1" == "" ]; then
	OUTPUTPATH="$WIKITOPICS/data/pageviews/$YEAR/$MONTH"
else
	OUTPUTPATH=$1
fi

# check the input and output paths
ARCHIVE="$WIKISTATS/archive/$YEAR/$MONTH"
if [ ! -e "$ARCHIVE" ]; then
	echo "no pageviews files at $ARCHIVE"
	exit 1
fi

mkdir -p $OUTPUTPATH
if [ "$DAY" != "" ]; then
	OUTPUTFILE="$OUTPUTPATH/pageviews_$YEAR$MONTH$DAY.txt"
	if [ -e "$OUTPUTFILE" ]; then
		echo "$OUTPUTFILE exists. skipping..."
		exit
	fi

	if [ "$HOUR" != "" ]; then
		HOUR="-$HOUR"
	fi

	date
	echo "processing $YEAR$MONTH$DAY$HOUR"

	for FILE in $ARCHIVE/pagecounts-$YEAR$MONTH$DAY$HOUR*.gz; do
		if [ ! -e "$FILE" ]; then
			continue
		fi

		DATETIME=`echo $FILE | sed -e 's/.*pagecounts-//' -e 's/\.gz$//'`
		echo "processing   $FILE" 1>&2
		time gunzip -c $FILE | grep '^en ' | ./sub_extract_pageviews.pl $LIST_FILE $DATETIME >> $OUTPUTFILE
		if [ ! $? ]; then
			echo "failed."
			exit 1
		fi
	done

	if [ -e "$OUTPUTFILE" ]; then
		TEMP_FILE=$OUTPUTPATH/foo$RANDOM.txt
		echo "sorting the results..."
		time sort -k 2,2 -k 1,1 $OUTPUTFILE > $TEMP_FILE
		mv $TEMP_FILE $OUTPUTFILE
	fi
else
	date
	echo "processing $YEAR/$MONTH"
	for DAY in `seq 31`; do
		if [ $DAY -ge 1 -a $DAY -le 9 ]; then
			DAY="0$DAY"
		fi

		OUTPUTFILE="$OUTPUTPATH/pageviews_$YEAR$MONTH$DAY.txt"
		if [ -e "$OUTPUTFILE" ]; then
			echo "$OUTPUTFILE exists. skipping..."
			exit
		fi

		for FILE in $ARCHIVE/pagecounts-$YEAR$MONTH$DAY*.gz; do
			if [ ! -e "$FILE" ]; then
				continue
			fi

			DATETIME=`echo $FILE | sed -e 's/.*pagecounts-//' -e 's/\.gz$//'`
			echo "processing   $FILE" 1>&2
			time gunzip -c $FILE | grep '^en ' | ./sub_extract_pageviews.pl $LIST_FILE $DATETIME >> $OUTPUTFILE
			if [ ! $? ]; then
				echo "failed."
				exit 1
			fi
		done

		if [ -e $OUTPUTFILE ]; then
			TEMP_FILE=$OUTPUTPATH/foo$RANDOM.txt
			echo "sorting the results..."
			time sort -k 2,2 -k 1,1 $OUTPUTFILE > $TEMP_FILE
			mv $TEMP_FILE $OUTPUTFILE
		fi
	done
fi

if [ "$DELETE_LATER" ]; then
	rm -f $LIST_FILE
fi
echo done extracting monthly pageviews.
date
