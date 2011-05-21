#!/bin/bash
#$ -N para_serif
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=4G
echo parallelize_serif_part.sh $* >&2

if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ "$1" == "-v" ]; then
	VERBOSE=1
	shift
fi

# check command-line options
if [ $# -ne 3 ]; then
	echo "USAGE: $0 [-v] DATASET DATE FILE_LIST.TXT" >&2
	exit 1
fi

DATASET=$1
# to avoid using LANG, which is used by Perl
LANG_OPTION=`echo $DATASET | sed -e 's/-.\+$//'`
DATE=$2
YEAR=${DATE:0:4}
FILES=`cat $3`

if [ $VERBOSE ]; then
	echo $FILES
	exit
fi

if [ "$LANG_OPTION" != "en" -a "$LANG_OPTION" != "ar" ]; then
	echo "serif does not support the language $LANG_OPTION" >&2
	exit 1
fi

OUTPUT_XML_DIR=$WIKITOPICS/data/serif/$DATASET/$YEAR/$DATE

BATCH_FILE=$OUTPUT_XML_DIR/filelist_xml_`echo $FILES | sed -e 's/ .*$//'`.txt
mkdir -p `dirname $BATCH_FILE`
rm -f $BATCH_FILE

echo exporting articles... >&2
time for FILENAME in $FILES; do
	BASENAME=`basename $FILENAME` # just to make sure
	SENTENCES=$WIKITOPICS/data/articles/$DATASET/$YEAR/$DATE/$BASENAME
	INPUT_SENTENCES=$WIKITOPICS/data/serif/input/$DATASET/$YEAR/$DATE/$BASENAME
	INPUT_XML=`echo $INPUT_SENTENCES | sed -e 's/\.sentences$/.xml/'`

	mkdir -p `dirname $INPUT_SENTENCES`
# page title
	echo $BASENAME | sed -e 's/\.sentences$//' | sed -e 's/_/ /g' | perl -e 'use URI::Escape; print uri_unescape(<STDIN>);' > $INPUT_SENTENCES
#cat $FILE | perl -ne "if (/[\.\,\'\"\!\?\:\;][\)]?$/) { print }" >> "$OUTPUT_DIR/$BASENAME"
	cat $SENTENCES >> $INPUT_SENTENCES
	$WIKITOPICS/src/sent/generate_serifxml.py $INPUT_SENTENCES > $INPUT_XML
	echo $INPUT_XML >> $BATCH_FILE
done

echo running serif... >&2
if [ "$LANG_OPTION" == "en" ]; then
	time /export/common/tools/serif/bin/SerifEnglish \
		/export/common/tools/serif/par/english.par \
		-p start_stage=tokens \
		-p source_format=serifxml \
		-p output_format=serifxml \
		-p batch_file=$BATCH_FILE \
		-o $OUTPUT_XML_DIR
elif [ "$LANG_OPTION" == "ar" ]; then
	time /export/common/tools/serif/bin/SerifArabic \
		/export/common/tools/serif/par/arabic.par \
		-p start_stage=tokens \
		-p source_format=serifxml \
		-p output_format=serifxml \
		-p batch_file=$BATCH_FILE \
		-o $OUTPUT_XML_DIR
elif [ "$LANG_OPTION" == "zh" ]; then
	time /export/common/tools/serif/bin/SerifChinese \
		/export/common/tools/serif/par/chinese.par \
		-p start_stage=tokens \
		-p source_format=serifxml \
		-p output_format=serifxml \
		-p batch_file=$BATCH_FILE \
		-o $OUTPUT_XML_DIR
fi

# sentence selection
echo selecting sentences... >&2
time for FILENAME in $FILES; do
	BASENAME=`basename $FILENAME` # just to make sure
	INPUT_SENTENCES=$WIKITOPICS/data/serif/input/$DATASET/$YEAR/$DATE/$BASENAME
	OUTPUT_XML=`echo $OUTPUT_XML_DIR/output/$BASENAME | sed -e 's/\.sentences/.xml.xml/'`

	if [ ! -f "$INPUT_SENTENCES" -o ! -f "$OUTPUT_XML" ]; then
		if [ ! -f "$INPUT_SENTENCES" ]; then
			echo "$INPUT_SENTENCES is missing" >&2
		fi
		if [ ! -f "$OUTPUT_XML" ]; then
			echo "$OUTPUT_XML is missing" >&2
		fi
	else
		mkdir -p $WIKITOPICS/data/sentences/first/$DATASET/$YEAR/$DATE
		$WIKITOPICS/src/sent/pick_first.sh $DATE $INPUT_SENTENCES $OUTPUT_XML > $WIKITOPICS/data/sentences/first/$DATASET/$YEAR/$DATE/$BASENAME
		mkdir -p $WIKITOPICS/data/sentences/recent/$DATASET/$YEAR/$DATE
		$WIKITOPICS/src/sent/pick_recent_xml.py $DATE $INPUT_SENTENCES $OUTPUT_XML > $WIKITOPICS/data/sentences/recent/$DATASET/$YEAR/$DATE/$BASENAME
		mkdir -p $WIKITOPICS/data/sentences/self/$DATASET/$YEAR/$DATE
		$WIKITOPICS/src/sent/pick_self_xml.py $DATE $INPUT_SENTENCES $OUTPUT_XML > $WIKITOPICS/data/sentences/self/$DATASET/$YEAR/$DATE/$BASENAME
	fi
done
