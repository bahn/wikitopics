# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check the command-line options
if [ $# -ne 3 ]; then
	echo "$0 LANG DATE ARTICLE" >&2
	exit 1
fi

LANG_OPTION="$1"
DATE=`date --date "$2" +"%Y-%m-%d"`
ARTICLE="$3"
YEAR=${DATE:0:4}

INPUT_FILE="$WIKITOPICS/data/serif/input/$LANG_OPTION/$YEAR/$DATE/$ARTICLE.sentences"
APF_FILE="$WIKITOPICS/data/serif/$LANG_OPTION/$YEAR/$DATE/output/$ARTICLE.sentences.apf"
if [ -f "$INPUT_FILE" -a -f "$APF_FILE" ]; then
	echo "Input: $INPUT_FILE" >&2
	echo "Serif: $APF_FILE" >&2
	$WIKITOPICS/src/sent/extract_dates.py $INPUT_FILE $APF_FILE
fi
