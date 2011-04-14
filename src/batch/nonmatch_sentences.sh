#!/bin/bash
#$ -N non_match
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
echo nonmatch_sentence.sh $* >&2

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

TEST_ROOT="$WIKITOPICS/data/sentences/$SCHEME_ID/$LANG_OPTION"

if [ ! -d "$TEST_ROOT" ]; then
	echo "$TEST_ROOT directory not found" >&2
	exit 1
fi

YEAR=2009 # for now
cd $TEST_ROOT/$YEAR
grep '^-1 .*[A-Za-z].*' */*.sentences
