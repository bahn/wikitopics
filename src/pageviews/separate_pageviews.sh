#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
#echo "$HOSTNAME:`pwd`\$ $0 $*"

THISYEAR=`date "+%Y"`
THISMONTH=`date "+%m"`

if [ "$1" -ge 2007 -a "$1" -le $THISYEAR ] 2> /dev/null; then
	YEAR=$1
	shift
fi

if [ $? -eq 1 ]; then
	echo "Year $1 is out of range"
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

DAY=
if [ $1 -ge 1 -a $1 -le 31 ] 2> /dev/null; then
	DAY=$1
	shift
fi

if [ $? -eq 1 ]; then
	echo "Day $1 is out of range"
	exit 1
fi

# make each numbers two-digited
for i in `seq 9`; do
	if [ "$MONTH" -eq $i ] 2>/dev/null; then
		MONTH="0$i"
	fi
	if [ "$DAY" -eq $i ] 2>/dev/null; then
		DAY="0$i"
	fi
done

if [ "$1" == "" ]; then
	#OUTPUT_PATH=pageviews
	OUTPUT_PATH=$WIKITOPICS/data/pageviews/raw
else
	if [ -d $1 -o ! -e $1 ]; then
		OUTPUT_PATH=$1
		shift
	else
		echo "$OUTPUT_PATH is not a directory"
		exit 1
	fi
fi

date
echo "separating pageviews..."
mkdir -p "$OUTPUT_PATH"

if [ "$YEAR" == "" ]; then
	FILES=$WIKITOPICS/data/pageviews/pageviews_????.txt
elif [ "$MONTH" == "" ]; then
	FILES=$WIKITOPICS/data/pageviews/pageviews_$YEAR.txt
elif [ "$DAY" == "" ]; then
	FILES=$WIKITOPICS/data/pageviews/$YEAR/pageviews_$YEAR$MONTH.txt
else
	FILES=$WIKITOPICS/data/pageviews/$YEAR/$MONTH/pageviews_$YEAR$MONTH$DAY.txt
fi

#time ./sub_merge_pageviews.pl $FILES | ./separate_pageviews.pl $OUTPUT_PATH
time sort -m -k 2,2 -k 1,1 $FILES | ./separate_pageviews.pl $OUTPUT_PATH

echo "done separating pageviews."
echo "separated pageviews are located at $OUTPUT_PATH"
date
