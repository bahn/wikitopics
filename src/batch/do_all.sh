#!/bin/bash
#$ -N do_all
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=6G

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
if [ "$LANG_OPTION" != "en" ]; then
	echo "Only en is supported for now." >&2
	exit 1
fi

date +"%Y-%m-%d %H:%M:%S" >&2
time $WIKITOPICS/src/batch/check_revisions.sh $DATA_SET $START_DATE $END_DATE

if [ "$LANG_OPTION" == "en" -o "$LANG_OPTION" == "ar" -o "$LANG_OPTION" == "zh" -o "$LANG_OPTION" == "ur" -o "$LANG_OPTION" == "hi" -o "$LANG_OPTION" == "es" -o "$LANG_OPTION" == "de" -o "$LANG_OPTION" == "fr" -o "$LANG_OPTION" == "cs" -o "$LANG_OPTION" == "ko" -o "$LANG_OPTION" == "ja" ]; then
	time $WIKITOPICS/src/batch/fetch_sentences.sh $DATA_SET $START_DATE $END_DATE
	time $WIKITOPICS/src/batch/kmeans.sh $DATA_SET $START_DATE $END_DATE
	if [ -f "/export/common/tools/serif/bin/SerifEnglish" ]; then
		if [ "$LANG_OPTION" == "en" -o "$LANG_OPTION" == "ar" ]; then
			$WIKITOPICS/src/batch/parallelize_serif.sh $DATA_SET $START_DATE $END_DATE
		fi
	fi
fi
date +"%Y-%m-%d %H:%M:%S" >&2
