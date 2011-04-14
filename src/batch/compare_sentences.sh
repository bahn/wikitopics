#!/bin/bash
if [ $# -ne 1 ]; then
	echo "Usage: $0 TEST_SET" >&2
	echo "Given: $0 $*" >&2
	exit 1
fi

TEST_SET=$1
LANG_OPTION="en" # for now
YEAR=2009
TEST_ROOT="$WIKITOPICS/data/sentences/$TEST_SET/$LANG_OPTION/$YEAR"

#echo $TEST_ROOT
for DIR in $TEST_ROOT/*; do
	#echo $DIR
	if [ ! -d "$DIR" ]; then
		continue
	fi
	for FILE in $DIR/*.sentences; do
		#echo $FILE
		if [ ! -f "$FILE" ]; then
			continue
		fi
		BASE_DIR=`basename $DIR`
		BASE_NAME=`basename $FILE`
		EXISTS=0
		for GOLD_DATA_SET in ben bahn; do
			GOLD_FILE="$WIKITOPICS/data/sentences/$GOLD_DATA_SET/$LANG_OPTION/$YEAR/$BASE_DIR/$BASE_NAME"
			if [ -f "$GOLD_FILE" ]; then
				EXISTS=1
			fi
		done
		if [ $EXISTS -eq 1 ]; then
			echo "========$BASE_DIR/$BASE_NAME========"
			cat $FILE
			for GOLD_DATA_SET in ben bahn; do
				GOLD_FILE="$WIKITOPICS/data/sentences/$GOLD_DATA_SET/$LANG_OPTION/$YEAR/$BASE_DIR/$BASE_NAME"
				if [ -f "$GOLD_FILE" ]; then
					echo "--------$GOLD_DATA_SET--------"
					cat $GOLD_FILE
				fi
			done
		fi
	done
done
