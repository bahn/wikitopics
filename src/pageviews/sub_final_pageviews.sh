#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
#$ -o /export/a05/wikitopics/src/pageviews/log/
echo "$HOSTNAME:`pwd`\$ $0 $*"

INPUT_PATH=$WIKITOPICS/data/pageviews/raw
HOURLY_PATH=$WIKITOPICS/data/pageviews/hourly
DAILY_PATH=$WIKITOPICS/data/pageviews/daily
FILE_PREFIX=

if [ "$1" != "" ]; then
	INPUT_PATH=$1
	shift
fi
if [ "$1" != "" ]; then
	HOURLY_PATH=$1
	shift
fi
if [ "$1" != "" ]; then
	DAILY_PATH=$1
	shift
fi
if [ "$1" != "" ]; then
	FILE_PREFIX=$1
	shift
fi

if [ ! -e $INPUT_PATH -o ! -d $INPUT_PATH ]; then
	echo cannot read from $INPUT_PATH
	exit 1
fi

mkdir -p $HOURLY_PATH
if [ ! -e $HOURLY_PATH -a ! -d $HOURLY_PATH ]; then
	echo cannot create a directory at $HOURLY_PATH
	exit 1
fi

mkdir -p $DAILY_PATH
if [ ! -e $DAILY_PATH -a ! -d $DAILY_PATH ]; then
	echo cannot create a directory at $DAILY_PATH
	exit 1
fi

date
for FILE in $INPUT_PATH/$FILE_PREFIX*.txt; do
	if [ ! -e $FILE ]; then
		continue
	fi
	echo $FILE
	time ./sub_final_pageviews.py $FILE $HOURLY_PATH $DAILY_PATH
done
date
