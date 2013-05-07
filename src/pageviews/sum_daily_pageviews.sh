#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
echo "$HOSTNAME:`pwd`\$ $0 $*"

if [ "$1" == "" ]; then
	INPUT_PATH=$WIKITOPICS/data/pageviews/hourly
	OUTPUT_PATH=$WIKITOPICS/data/pageviews/daily
else
	if [ "$2" == "" ]; then
		INPUT_PATH=$1
		OUTPUT_PATH=daily_pageviews
	else
		INPUT_PATH=$1
		OUTPUT_PATH=$2
	fi
fi

if [ ! -e $INPUT_PATH -o ! -d $INPUT_PATH ]; then
	echo cannot read from $INPUT_PATH
	exit 1
fi

mkdir -p $OUTPUT_PATH
if [ ! -e $OUTPUT_PATH -a ! -d $OUTPUT_PATH ]; then
	echo cannot create a directory at $OUTPUT_PATH
	exit 1
fi

for FILE in $INPUT_PATH/*.txt; do
	if [ ! -e $FILE ]; then
		continue
	fi
	BASENAME=`basename $FILE`
	OUTPUTFILE="$OUTPUT_PATH/$BASENAME"
	./sum_daily_pageviews.pl $FILE $OUTPUTFILE
done
