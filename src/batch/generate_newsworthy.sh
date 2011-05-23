#!/bin/bash
echo $HOSTNAME generate_newsworthy.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ $# -ne 2 ]; then
    echo "Usage: $0 DATA_SET START_DATE [END_DATE]" >&2
    echo "Given: $*" >&2
    exit 1
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y-%m-%d"`
if [ "$3" == "" ]; then
	END_DATE="$START_DATE"
else
	END_DATE=`date --date "$3" +"%Y-%m-%d"`
fi

# don't use LANG or LANGUAGE -- they are used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`

DATE=$START_DATE
while [ ! $END_DATE \< $DATE ]; do
    YEAR=${DATE:0:4}
	TEMP_FILE="$WIKITOPICS/src/mturk/$DATA_SET-$DATE-$RANDOM.csv"
	CSV_FILE="$WIKITOPICS/data/mturk/$DATA_SET/$YEAR/$DATE.newsworthy.csv"
	if [ "$DATA_SET" == "en" ]; then
		CSV_EX_DIR="/export/people/bahn/wikitopics"
	else
		CSV_EX_DIR="/export/people/bahn/wikitopics/$DATA_SET"
	fi

	echo "generate_newsworthy.pl $LANG_OPTION $DATE > $CSV_FILE"
	if $WIKITOPICS/src/mturk/generate_newsworthy.pl $LANG_OPTION $DATE > $TEMP_FILE; then
		mkdir -p `dirname $CSV_FILE`
		mv $TEMP_FILE $CSV_FILE
		if [ "$HOSTNAME" != "a05" ]; then
			scp $CSV_FILE login.clsp.jhu.edu:$CSV_EX_DIR/$YEAR/$DATE.newsworthy.csv
		fi
	else
		rm -f $TEMP_FILE
		echo failed generating a csv file from $DATA_SET $DATE >&2
	fi
    DATE=`date --date "$DATE 1 day" +"%Y-%m-%d"`
done
