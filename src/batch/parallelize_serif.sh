#!/bin/bash
#$ -N para_serif
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
echo $HOSTNAME parallelize_serif.sh $* >&2

if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ "$1" == "-v" ]; then
	VERBOSE=1
	shift
fi

if [ $# -lt 2 -o $# -gt 3 ]; then
	echo "USAGE: $0 [-v] LANGUAGE START_DATE [END_DATE]" >&2
	exit 1
fi

DATA_SET="$1"
# to avoid using LANG, which is used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
if [ "$2" != "" ]; then
	START_DATE=`date --date "$2" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE=$2
	fi

	if [ "$3" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$3" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE=$3
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi

if [ "$LANG_OPTION" != "en" -a "$LANG_OPTION" != "ar" ]; then
	echo "serif does not support the language $LANG_OPTION" >&2
	exit 1
fi

BLOCK=50
for DIRPATH in $WIKITOPICS/data/articles/$DATA_SET/*/*; do
	if [ ! -d "$DIRPATH" ]; then # such directory not found
		continue
	fi
	DATE=`basename $DIRPATH`
	echo $DATE | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$DATE" -o "$END_DATE" \< "$DATE" ]; then # if the date falls out of the range
		continue
	fi

	YEAR=${DATE:0:4}
	NUM=0
	JOBIDS=""
	PART=0
	PART_FILE=$WIKITOPICS/data/serif/input/$DATA_SET/$YEAR/$DATE/files_part$PART.txt
	mkdir -p `dirname $PART_FILE`
	rm -f $PART_FILE
	for FILE in $DIRPATH/*.sentences; do
		if [ -f $FILE ]; then
			echo $FILE >> $PART_FILE
			NUM=$[$NUM+1]
			if [ $NUM -eq $BLOCK ]; then
				if [ $VERBOSE ]; then
					echo qsub $WIKITOPICS/src/batch/parallelize_serif_part.sh $DATA_SET $DATE $PART_FILE
				else
					JID=`qsub $WIKITOPICS/src/batch/parallelize_serif_part.sh $DATA_SET $DATE $PART_FILE`
					JOBIDS="$JOBIDS,`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`"
				fi
				NUM=0
				PART=$[$PART+1]
				PART_FILE=$WIKITOPICS/data/serif/input/$DATA_SET/$YEAR/$DATE/files_part$PART.txt
				rm -f $PART_FILE
			fi
		fi
	done
	if [ $NUM -gt 0 ]; then
		if [ $VERBOSE ]; then
			echo qsub $WIKITOPICS/src/batch/parallelize_serif_part.sh $DATA_SET $DATE $PART_FILE
		else
			JID=`qsub $WIKITOPICS/src/batch/parallelize_serif_part.sh $DATA_SET $DATE $PART_FILE`
			JOBIDS="$JOBIDS,`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`"
		fi
	fi
	if [ ! $VERBOSE ]; then
		JOBIDS=`echo $JOBIDS | sed -e 's/^,//'`
		qsub -hold_jid $JOBIDS $WIKITOPICS/src/batch/convert_clusters.sh $DATA_SET $DATE
	fi
done
