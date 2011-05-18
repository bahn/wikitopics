#!/bin/bash
if [ $# -lt 2 -o $# -gt 3 ]; then
	echo "list_files.sh DATASET DATE PART" >&2
	exit 1
fi

DATASET=$1
DATE=`date --date "$2" +"%Y-%m-%d"`
YEAR=${DATE:0:4}
PART=$3

echo "topics"
echo "======"
ls -hl $WIKITOPICS/data/topics/$DATASET/$YEAR/$DATE.*
echo
if [ "$3" == "" ]; then
	echo "articles"
	echo "========"
	ls -hl $WIKITOPICS/data/articles/$DATASET/$YEAR/$DATE
	echo
	echo "serif input"
	echo "==========="
	ls -hl $WIKITOPICS/data/serif/input/$DATASET/$YEAR/$DATE
	echo
	echo "serif output"
	echo "============"
	ls -hl $WIKITOPICS/data/serif/$DATASET/$YEAR/$DATE/output
	echo
	echo "sentences"
	echo "========="
	ls -hl $WIKITOPICS/data/sentences/*/$DATASET/$YEAR/$DATE
else
	echo "part"
	echo "===="
	echo
	PARTFILE=$WIKITOPICS/data/serif/input/en/2011/2011-05-10/files_part$3.txt
	if [ -f "$PARTFILE" ]; then
		FILES=`cat $PARTFILE`
		echo "articles"
		echo "========"
		for FILE in $FILES; do
			BASENAME=`basename $FILE | sed -e 's/\.sentences$//'`
			ls -hl $WIKITOPICS/data/articles/$DATASET/$YEAR/$DATE/$BASENAME*
		done
		echo
		echo "serif input"
		echo "==========="
		for FILE in $FILES; do
			BASENAME=`basename $FILE | sed -e 's/\.sentences$//'`
			ls -hl $WIKITOPICS/data/serif/input/$DATASET/$YEAR/$DATE/$BASENAME*
		done
		echo
		echo "serif output"
		echo "============"
		for FILE in $FILES; do
			BASENAME=`basename $FILE | sed -e 's/\.sentences$//'`
			ls -hl $WIKITOPICS/data/serif/$DATASET/$YEAR/$DATE/output/$BASENAME*
		done
		echo
		echo "sentences"
		echo "========="
		for FILE in $FILES; do
			BASENAME=`basename $FILE | sed -e 's/\.sentences$//'`
			ls -hl $WIKITOPICS/data/sentences/*/$DATASET/$YEAR/$DATE/$BASENAME*
		done
	fi
fi
