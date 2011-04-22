#!/bin/bash
echo compare_all_sentences.sh $* >&2
# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ $# -lt 2 -o $# -gt 3 ]; then
	echo "Usage: $0 LANG START_DATE [END_DATE]" >&2
	echo "Given: $0 $*" >&2
	exit 1
fi

LANG_OPTION="$1"
START_DATE=`date --date "$2" +"%Y-%m-%d"`
if [ $? -ne 0 ]; then
	echo "error using date... fallback to using plain text" >&2
	START_DATE="$2"
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

TEST_ROOT="$WIKITOPICS/data/articles/$LANG_OPTION"

#echo $TEST_ROOT
for DIR in $TEST_ROOT/*/*; do
	if [ ! -d "$DIR" ]; then
		continue
	fi
	BASE_DIR=`basename $DIR`
	if [ "$START_DATE" \> "$BASE_DIR" -o "$END_DATE" \< "$BASE_DIR" ]; then # if the date falls out of the range
		continue
	fi
	YEAR=${BASE_DIR:0:4}

	for FILE in $DIR/*.sentences; do
		if [ ! -f "$FILE" ]; then
			continue
		fi
		BASE_NAME=`basename $FILE`
		echo "========$BASE_DIR/$BASE_NAME========"
		for DATA_DIR in $WIKITOPICS/data/sentences/*; do
			if [ ! -d "$DATA_DIR" ]; then
				continue
			fi
			DATA_SET=`basename $DATA_DIR`

			FILE="$WIKITOPICS/data/sentences/$DATA_SET/$LANG_OPTION/$YEAR/$BASE_DIR/$BASE_NAME"
			if [ -f "$FILE" ]; then
				echo "--------$DATA_SET--------"
				cat $FILE
			fi
		done
	done
done
