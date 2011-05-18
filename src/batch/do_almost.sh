#!/bin/bash
#$ -N do_almost
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=6G

echo "do_almost.sh $*" >&2

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

if [ "$LANG_OPTION" == "en" -o "$LANG_OPTION" == "ar" ]; then
	if [ -f "/export/common/tools/serif/bin/SerifEnglish" ]; then
		$WIKITOPICS/src/batch/parallelize_serif.sh $DATA_SET $START_DATE $END_DATE
	fi
fi
date +"%Y-%m-%d %H:%M:%S" >&2