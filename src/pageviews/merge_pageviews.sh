#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G

echo "$HOSTNAME:`pwd`\$ $0 $*"

THISYEAR=`date "+%Y"`
THISMONTH=`date "+%m"`

date
JOBIDS2=
#JIDJID=1
# merge pageviews
for YEAR in `seq 2007 $THISYEAR`; do
	if [ ! -e "$WIKITOPICS/data/pageviews/$YEAR" ]; then
		echo "skipping $YEAR; data does not exist"
		continue
	fi
	FILE=$WIKITOPICS/data/pageviews/pageviews_$YEAR.txt
	if [ -f $FILE ]; then
		echo "$FILE exists; skipping..."
		continue
	fi

	JOBIDS=
	JOBIDS_TO_WAIT=
	JOBRUNNING=0
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do
		if [ $YEAR == 2007 -a $MONTH -lt 12 -o $YEAR == $THISYEAR -a $MONTH -gt $THISMONTH ]; then
			continue
		fi
		if [ ! -e "$WIKITOPICS/data/pageviews/$YEAR/$MONTH" ]; then
			echo "skipping $YEAR/$MONTH; data does not exist"
			continue
		fi
		FILE=$WIKITOPICS/data/pageviews/$YEAR/pageviews_$YEAR$MONTH.txt
		if [ -f $FILE ]; then
			echo "$FILE exists; skipping..."
		else
			if [ $JOBRUNNING -ge 3 -a "$JOBIDS" != "" ]; then
				JOBRUNNING=0
				JOBIDS_TO_WAIT=`echo $JOBIDS | sed -e 's/^,//'`
				JOBIDS=
			fi

			#JID=$[JIDJID]
			#JIDJID=$[JIDJID+1]
			if [ "$JOBIDS_TO_WAIT" != "" ]; then
				#echo "$JID: wait $JOBIDS_TO_WAIT and then run $YEAR $MONTH"
				JID=`qsub -hold_jid $JOBIDS_TO_WAIT ./sub_merge_pageviews.sh $YEAR $MONTH`
			else
				#echo "$JID: run $YEAR $MONTH"
				JID=`qsub ./sub_merge_pageviews.sh $YEAR $MONTH`
			fi
			JOBIDS="$JOBIDS,`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`"

			JOBRUNNING=$[JOBRUNNING+1]
		fi
	done

	#JID=$[JIDJID]
	#JIDJID=$[JIDJID+1]
	if [ "$JOBIDS" != "" ]; then
		JOBIDS=`echo $JOBIDS | sed -e 's/^,//'`
		#echo "$JID: wait $JOBIDS and then run $YEAR"
		JID=`qsub -hold_jid $JOBIDS ./sub_merge_pageviews.sh $YEAR`
		JOBIDS=
	else
		#echo "$JID: run $YEAR"
		JID=`qsub ./sub_merge_pageviews.sh $YEAR`
	fi
	JOBIDS2="$JOBIDS2,`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`"
done

#JID=$[JIDJID]
#JIDJID=$[JIDJID+1]
if [ "$JOBIDS2" != "" ]; then
	JOBIDS2=`echo $JOBIDS2 | sed -e 's/^,//'`
	JID=`qsub -hold_jid $JOBIDS2 ./separate_pageviews.sh $WIKITOPICS/data/pageviews/raw`
	#echo "$JID: wait $JOBIDS2 and then run separate_pageviews.sh"
	JOBIDS2=
else
	JID=`qsub ./separate_pageviews.sh $WIKITOPICS/data/pageviews/raw`
	#echo "$JID: run separate_pageviews.sh"
fi
JOBIDS=`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`

#JID=`qsub -hold_jid $JOBIDS ./sum_daily_pageviews.sh`
#JOBIDS=`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`

echo done submitting jobs.
date
