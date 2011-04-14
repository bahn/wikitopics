#!/bin/bash
#$ -N eval_sents
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo evaluate_sentence.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

# check command-line options
if [ $# -ne 1 ]; then
	echo "USAGE: $0 [-v] SCHEME_ID" >&2
	exit 1
fi

# to avoid using LANG, which is used by Perl
LANG_OPTION="en" # for now
SCHEME_ID=$1
SCRIPT="$WIKITOPICS/src/sent_eval/eval_sents.py"
if [ ! -f "$SCRIPT" ]; then
	echo "$SCRIPT not found" >&2
	exit 1
fi

GOLD_ROOT="$WIKITOPICS/data/sentences"
TEST_ROOT="$WIKITOPICS/data/sentences/$SCHEME_ID/$LANG_OPTION"

if [ ! -d "$GOLD_ROOT" ]; then
	echo "$GOLD_ROOT directory not found" >&2
	exit 1
fi

YEAR=2009 # for now
perl -e 'printf "'"$SCHEME_ID"'\tgold\tprec\trec\tf-1\tprec\trec\tf-1\n"'
for GOLD_DATA_SET in ben bahn; do
	$SCRIPT "$TEST_ROOT/$YEAR" "$GOLD_ROOT/$GOLD_DATA_SET/$LANG_OPTION/$YEAR"
done | $WIKITOPICS/src/sent_eval/tabularize.pl
echo gold: 1=ben 2=bahn
