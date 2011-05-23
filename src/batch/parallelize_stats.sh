#!/bin/bash
#$ -N para_proc
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid

# process_stats.sh
echo $HOSTNAME "process_stats.sh $*" >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ $# -lt 3 -o $# -gt 5 ]
then
	echo "Parallelize all jobs. Divide jobs into daily parts." >&2
    echo "Usage: $0 DATA_SET START_DATE END_DATE [REDIRECTS [CUT_OFF]]" >&2
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

if [ "$LANG_OPTION" == "en" -o "$LANG_OPTION" == "ar" -o "$LANG_OPTION" == "zh" ]; then
	SERIFABLE=1
fi

if [ "$HOSTNAME" == "a05" -o "$HOSTNAME" == "a05.clsp.jhu.edu" -o ! -f "/export/common/tools/serif/bin/SerifEnglish" ]; then
	echo "This script only runs on COE grid." >&2
	exit 1
fi

init_qsub()
{
	JOBIDS=""
	JOBIDS_TO_MERGE=""
	PREV_STEP_JOBID=""
}

qsub_run()
{
	if [ "$JOBIDS" == "" ]; then
		JID=`qsub $*`
	else
		JID=`qsub -hold_jid $JOBIDS $*`
	fi
	JOBIDS=`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`
}

qsub_branch()
{
	if [ "$PREV_STEP_JOBID" == "" ]; then
		PREV_STEP_JOBID="$JOBIDS"
	else
		JOBIDS_TO_MERGE=`echo $JOBIDS_TO_MERGE,$JOBIDS | sed -e 's/^,//'`
		JOBIDS="$PREV_STEP_JOBID"
	fi
}

qsub_merge()
{
	JOBIDS=`echo $JOBIDS,$JOBIDS_TO_MERGE | sed -e 's/^,//'`
	JOBIDS_TO_MERGE=""
	PREV_STEP_JOBID=""
}

init_qsub
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
qsub_run $WIKITOPICS/src/batch/list_topics.sh $CUT_OFF $DATA_SET $DATE $DATE

DATE=$START_DATE
while [ ! $DATE \> $END_DATE ]; do
	qsub_branch
	qsub_run $WIKITOPICS/src/batch/check_revisions.sh $DATA_SET $DATE $DATE

	if [ $SENTENCE_SPLIT ]; then
		qsub_run $WIKITOPICS/src/batch/fetch_sentences.sh $DATA_SET $DATE $DATE
		qsub_run $WIKITOPICS/src/batch/kmeans.sh $DATA_SET $DATE $DATE

		if [ $SERIFABLE ]; then # parallelize
			qsub_run $WIKITOPICS/src/batch/parallelize_serif.sh $DATA_SET $DATE $DATE
		else
			qsub_run $WIKITOPICS/src/batch/convert_clusters.sh $DATA_SET $DATE $DATE
		fi
	else
		qsub_run $WIKITOPICS/src/batch/convert_topics.sh $DATA_SET $DATE $DATE
	fi
    DATE=`date --date "$DATE 1 day" +"%Y%m%d"`
done
