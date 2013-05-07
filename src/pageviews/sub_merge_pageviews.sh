#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
#$ -o /export/a05/wikitopics/src/pageviews/log/
echo "$HOSTNAME:`pwd`\$ $0 $*"

# check the command-line arguments
if [ "$1" == "" ]; then
	echo "usage: `basename $0` YEAR [MONTH] [OUTPUT_PATH]"
	exit 1
fi

THISYEAR=`date "+%Y"`
THISMONTH=`date "+%m"`
YEAR=$1
shift

if [ "$YEAR" -lt 2007 -o "$YEAR" -gt $THISYEAR ] 2> /dev/null; then
	echo "Year $YEAR is out of range"
	exit 1
fi

if [ $? -eq 2 ]; then
	echo "Year $YEAR must be a number"
	exit 1
fi

MONTH=
if [ $1 -ge 1 -a $1 -le 12 ] 2> /dev/null; then
	MONTH=$1
	shift

	if [ "$YEAR" -eq 2007 -a "$MONTH" -lt 12 -o "$YEAR" -eq "$THISYEAR" -a "$MONTH" -gt "$THISMONTH" -o "$MONTH" -lt 1 -o "$MONTH" -gt 12 ] 2> /dev/null; then
		echo "Pair of year-month $YEAR-$MONTH is out of range"
		exit 1
	fi
fi

if [ $? -eq 1 ]; then
	echo "Month $MONTH is out of range"
	exit 1
fi

# make each numbers two-digited
for i in `seq 9`; do
	if [ "$MONTH" -eq $i ] 2>/dev/null; then
		MONTH="0$i"
	fi
done

BASE_PATH=$WIKITOPICS/data/pageviews
if [ "$1" == "" ]; then
	if [ "$MONTH" == "" ]; then
		OUTPUT_PATH=$BASE_PATH
	else
		OUTPUT_PATH=$BASE_PATH/$YEAR
	fi
else
	if [ -d $1 -o ! -e $1 ]; then
		OUTPUT_PATH=$1
		shift
	fi
fi

if [ -e "$OUTPUT_PATH" -a ! -d "$OUTPUT_PATH" ]; then
	echo "$OUTPUT_PATH is not a directory. quitting..."
	exit 1
fi

# merge pageviews
date
mkdir -p $OUTPUT_PATH
if [ "$MONTH" == "" ]; then
	for INPUT_FILE in $BASE_PATH/$YEAR/pageviews_$YEAR??.txt; do
		if [ ! -e "$INPUT_FILE" ]; then
			echo "$INPUT_FILE does not exist. quitting..."
			exit 1
		fi
		if [ ! -f "$INPUT_FILE" ];  then
			echo "$INPUT_FILE is not a file. quitting..."
			exit 1
		fi
	done
	#./sub_merge_pageviews.pl $BASE_PATH/$YEAR/pageviews_$YEAR??.txt > $OUTPUT_FILE
	time sort -m -k 2,2 -k 1,1 $BASE_PATH/$YEAR/pageviews_$YEAR??.txt > $OUTPUT_PATH/pageviews_$YEAR.txt
else
	for INPUT_FILE in $BASE_PATH/$YEAR/$MONTH/pageviews_$YEAR$MONTH??.txt; do
		if [ ! -e "$INPUT_FILE" ]; then
			echo "$INPUT_FILE does not exist. quitting..."
			exit 1
		fi
		if [ ! -f "$INPUT_FILE" ];  then
			echo "$INPUT_FILE is not a file. quitting..."
			exit 1
		fi
	done
	#time ./sub_merge_pageviews.pl $BASE_PATH/$YEAR/$MONTH/pageviews_$YEAR$MONTH??.txt > $OUTPUT_FILE
	time sort -m -k 2,2 -k 1,1 $BASE_PATH/$YEAR/$MONTH/pageviews_$YEAR$MONTH??.txt > $OUTPUT_PATH/pageviews_$YEAR$MONTH.txt
fi

echo "merged pageviews: $OUTPUT_FILE"
echo done merging monthly pageviews.
date
