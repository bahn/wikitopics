#!/bin/bash
#$ -N para_proc
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid

# parallelize_stats.sh
echo $HOSTNAME "parallelize_stats.sh $*" >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ "$1" == "-s" ]; then
	STARTING_STEP="$2"
	shift; shift
fi

if [ $# -lt 3 -o $# -gt 5 ]
then
	echo "Parallelize all jobs. Divide jobs into daily parts." >&2
    echo "Usage: $0 [-s STARTING_STEP] DATA_SET START_DATE END_DATE" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y%m%d"`
END_DATE=`date --date "$3" +"%Y%m%d"`
REDIRECTS="$4"
CUT_OFF="$5"

# don't use LANG or LANGUAGE -- they are used by Perl.
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
if echo $DATA_SET | grep - > /dev/null; then
	FILTER="-f `echo $DATA_SET | sed -e 's/^.\+-//'`"
fi

if [ "$LANG_OPTION" == "en" -o "$LANG_OPTION" == "ar" -o "$LANG_OPTION" == "zh" -o "$LANG_OPTION" == "ur" -o "$LANG_OPTION" == "hi" -o "$LANG_OPTION" == "es" -o "$LANG_OPTION" == "de" -o "$LANG_OPTION" == "fr" -o "$LANG_OPTION" == "cs" -o "$LANG_OPTION" == "ko" -o "$LANG_OPTION" == "ja" ]; then
	SENTENCE_SPLIT=1
fi

if [ "$LANG_OPTION" == "en" ]; then
	# process only English. Serif is available for Arabic and Chinese, but SerifArabic crashed quite often - once a few days. - 9/29/2011 bahn.
	SERIFABLE=1
fi

#if [ "$HOSTNAME" == "a05" -o "$HOSTNAME" == "a05.clsp.jhu.edu" -o ! -f "/export/common/tools/serif/bin/SerifEnglish" ]; then
#	echo "This script only runs on COE grid." >&2
#	exit 1
#fi

init_qsub()
{
	JOBIDS=""
	JOBIDS_TO_MERGE=""
	PREV_STEP_JOBID=""
	PREV_STEP_SET=
}

qsub_run()
{
	if [ "$JOBIDS" == "" ]; then
		echo qsub $*
		JID=`qsub $*`
	else
		echo qsub -hold_jid $JOBIDS $*
		JID=`qsub -hold_jid $JOBIDS $*`
	fi
	JOBIDS=`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`
}

qsub_branch()
{
	if [ ! $PREV_STEP_SET ]; then
		PREV_STEP_SET=1
		PREV_STEP_JOBID="$JOBIDS"
	else
		JOBIDS_TO_MERGE=`echo $JOBIDS_TO_MERGE,$JOBIDS | sed -e 's/^,//'`
		JOBIDS="$PREV_STEP_JOBID"
	fi
}

qsub_merge()
{
	JOBIDS=`echo $JOBIDS_TO_MERGE,$JOBIDS | sed -e 's/,$//'`
	JOBIDS_TO_MERGE=""
	PREV_STEP_JOBID=""
	PREV_STEP_SET=
}

if [ "$STARTING_STEP" == "" ]; then
	WORKING=1
fi

init_qsub

if [ $WORKING ]; then
	DATE=$START_DATE
	while [ ! $DATE \> $END_DATE ]; do
		qsub_branch
		qsub_run $WIKITOPICS/src/batch/add_hourly_stats.sh $DATA_SET $DATE $DATE
		if [ "$REDIRECTS" != "" ]; then
			qsub_run $WIKITOPICS/src/batch/redirect_stats.sh $DATA_SET $REDIRECTS $DATE $DATE
		fi
		DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
	done
	qsub_merge
fi

if [ "$STARTING_STEP" == "1" -o "$STARTING_STEP" == "articles" -o "$STARTING_STEP" == "article_selection" ]; then
	WORKING=1
fi

if [ $WORKING ]; then
	qsub_run $WIKITOPICS/src/batch/list_topics.sh $CUT_OFF $DATA_SET $START_DATE $END_DATE
fi
WORKING_SAVE=$WORKING

DATE=$START_DATE
while [ ! $DATE \> $END_DATE ]; do
	WORKING=$WORKING_SAVE
	qsub_branch
	
	if [ $WORKING ]; then
		qsub_run $WIKITOPICS/src/batch/check_revisions.sh $DATA_SET $DATE $DATE
	fi

	if [ "$STARTING_STEP" == "2" -o "$STARTING_STEP" == "clusters" -o "$STARTING_STEP" == "clustering" ]; then
		WORKING=1
	fi

	if [ $SENTENCE_SPLIT ]; then
		if [ $WORKING ]; then
			qsub_run $WIKITOPICS/src/batch/fetch_sentences.sh $DATA_SET $DATE $DATE
			qsub_run $WIKITOPICS/src/batch/kmeans.sh $DATA_SET $DATE $DATE
		fi

		if [ "$STARTING_STEP" == "3" -o "$STARTING_STEP" == "sentences" -o "$STARTING_STEP" == "sentence_selection" ]; then
			WORKING=1
		fi

		if [ $SERIFABLE -a $WORKING ]; then # parallelize
			qsub_run $WIKITOPICS/src/batch/parallelize_serif.sh $DATA_SET $DATE $DATE
		else
			qsub_run $WIKITOPICS/src/batch/convert_clusters.sh $DATA_SET $DATE $DATE
		fi
	else
		qsub_run $WIKITOPICS/src/batch/convert_topics.sh $DATA_SET $DATE $DATE
	fi
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done
