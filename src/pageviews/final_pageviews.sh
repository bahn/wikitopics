#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
echo "$HOSTNAME:`pwd`\$ $0 $*"

INPUT_PATH=$WIKITOPICS/data/pageviews/raw
HOURLY_PATH=$WIKITOPICS/data/pageviews/hourly
DAILY_PATH=$WIKITOPICS/data/pageviews/daily
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

for i in `seq 0 9` A B C D E F G H I J K L M N O P Q R S T U V W X Y Z %; do
	qsub ./sub_final_pageviews.sh $INPUT_PATH $HOURLY_PATH $DAILY_PATH $i
done
echo done submitting jobs
