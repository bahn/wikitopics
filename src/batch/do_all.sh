#!/bin/bash
#$ -N do_all
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
# process_stats.sh
echo "do_all.sh $*" >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ $# -lt 2 -o $# -gt 3 ]
then
    echo "Usage: $0 DATA_SET START_DATE [END_DATE]" >&2
    echo "Given command-line options: $*" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y%m%d"`
if [ "$3" == "" ]; then
	END_DATE=$START_DATE
else
	END_DATE=`date --date "$3" +"%Y%m%d"`
fi

# don't use LANG or LANGUAGE -- they are used by Perl.
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`

date +"%Y-%m-%d %H:%M:%S" >&2
time $WIKITOPICS/src/batch/kmeans.sh $LANG_OPTION $START_DATE $END_DATE

# check SERIF
if [ -f "/export/common/tools/serif/bin/SerifEnglish" ]; then
#time $WIKITOPICS/src/batch/fetch_sentences.sh $LANG_OPTION $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/filter_sentences.sh $LANG_OPTION $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/serif.sh $LANG_OPTION $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/pick_sentence.sh $LANG_OPTION first $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/pick_sentence.sh $LANG_OPTION recent $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/pick_sentence.sh $LANG_OPTION self $START_DATE $END_DATE
fi
date +"%Y-%m-%d %H:%M:%S" >&2
