#!/bin/bash
#$ -N pick_sent
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=1G

echo $HOSTNAME pick_sentence.sh $* >&2

if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ "$1" == "--dry-run" ]; then
	DRYRUN=1
	shift
fi

if [ "$1" == "-v" ]; then
	VERBOSE=1
	shift
fi

if [ $# -lt 2 ]; then
	echo "USAGE: $0 [-v] [-x EXT] LANGUAGE SCHEME_ID [START_DATE [END_DATE]]" >&2
	exit 1
fi

DATA_SET="$1"
# to avoid using LANG, which is used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
SCHEME_ID=$2
if [ "$SCHEME_ID" == "first" ]; then
	SCHEME_SCRIPT_APF="pick_first.sh"
	SCHEME_SCRIPT_XML="pick_first.sh"
elif [ "$SCHEME_ID" == "recent" ]; then
	SCHEME_SCRIPT_APF="pick_recent_apf.py"
	SCHEME_SCRIPT_XML="pick_recent_xml.py"
elif [ "$SCHEME_ID" == "self" ]; then
	SCHEME_SCRIPT_APF="pick_self_apf.py"
	SCHEME_SCRIPT_XML="pick_self_xml.py"
fi
if [ "$SCHEME_SCRIPT_APF" == "" -o "$SCHEME_SCRIPT_XML" == "" ]; then
	echo "$SCHEME_ID not defined" >&2
	exit 1
fi

if [ ! -f "$WIKITOPICS/src/sent/$SCHEME_SCRIPT_APF" -o ! -f "$WIKITOPICS/src/sent/$SCHEME_SCRIPT_XML" ]; then
	echo "$SCHEME_SCRIPT_APF or $SCHEME_SCRIPT_XML not found" >&2
	exit 1
fi

if [ "$3" != "" ]; then
	START_DATE=`date --date "$3" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE=$3
	fi

	if [ "$4" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$4" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE=$4
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi

INPUT_ROOT="$WIKITOPICS/data/serif/input/$DATA_SET"
OUTPUT_ROOT="$WIKITOPICS/data/sentences/$SCHEME_ID/$DATA_SET"

if [ ! -d "$INPUT_ROOT" ]; then
	echo "input directory not found: $INPUT_ROOT" >&2
	exit 1
fi

if [ $VERBOSE ]; then
	echo "Script: $SCRIPT" >&2
fi

for INPUT_DIR in $INPUT_ROOT/*/*; do
	if [ ! -d "$INPUT_DIR" ]; then # such directory not found
		continue
	fi
	BASE_DIR=`basename $INPUT_DIR`
	echo $BASE_DIR | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$BASE_DIR" -o "$END_DATE" \< "$BASE_DIR" ]; then # if the date falls out of the range
		continue
	fi

	YEAR=${BASE_DIR:0:4}
	for FILE in $INPUT_DIR/*.sentences; do
		if [ -f $FILE ]; then
			BASE_NAME=`basename $FILE`
			SENTENCES=$FILE
			SERIF_FILE_APF=`echo $$WIKITOPICS/data/serif/$DATA_SET/$YEAR/$BASE_DIR/output/$BASE_NAME | sed -e "s/$/.apf/"`
			SERIF_FILE_XML=`echo $$WIKITOPICS/data/serif/$DATA_SET/$YEAR/$BASE_DIR/output/$BASE_NAME | sed -e "s/\.sentences$/.xml.xml/"`
			if [ -e $SERIF_FILE_XML ]; then
				SERIF_FILE=$SERIF_FILE_XML
				SCRIPT=$SCHEME_SCRIPT_XML
			elif [ -e $SERIF_FILE_APF ]; then
				SERIF_FILE=$SERIF_FILE_APF
				SCRIPT=$SCHEME_SCRIPT_APF
			fi
			OUTPUT_FILE="$OUTPUT_ROOT/$YEAR/$BASE_DIR/$BASE_NAME"
			if [ $VERBOSE ]; then
				echo "Date: $BASE_DIR" >&2
				echo "Sentences: $SENTENCES" >&2
				echo "Source: $FILE" >&2
				echo "Serif: $SERIF_FILE" >&2
				echo "Output: $OUTPUT_FILE" >&2
				echo "$SCRIPT $BASE_DIR $SENTENCES $SERIF_FILE > $OUTPUT_FILE"
			fi
			mkdir -p `dirname $OUTPUT_FILE`
			# here BASE_DIR is the date
			if [ $DRYRUN ]; then
				echo "$SCRIPT $BASE_DIR $SENTENCES $SERIF_FILE > $OUTPUT_FILE"
			else
				$SCRIPT $BASE_DIR $SENTENCES $SERIF_FILE > $OUTPUT_FILE
			fi
		fi
	done
done
