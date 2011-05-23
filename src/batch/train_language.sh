#!/bin/bash
#$ -N train_lang
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -l h_vmem=2G

echo train_language.sh $*

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ $# -ne 2 -a $# -ne 3 ]; then
	echo "Train a sentence split model for NLTK's Punkt."
	echo "Usage: train_language.sh LANG_ID LANGUAGE [TRAIN_DATA_SIZE]"
	echo "Example: train_language.sh zh Chinese"
	exit 1
fi

mkdir -p $WIKITOPICS/data/punkt
if [ -f $WIKITOPICS/data/punkt/$2.pickle ]; then
	mkdir -p ~/nltk_data/tokenizers/punkt
	cp $WIKITOPICS/data/punkt/$2.pickle ~/nltk_data/tokenizers/punkt
	echo "Cancelling training; a model exists"
	echo "If you want to train, rm -f $WIKITOPICS/data/punkt/$2.pickle"
	exit 1
fi

cd $WIKITOPICS/data/punkt
$WIKITOPICS/src/wiki/train_tokenizer.py $*

if [ -e $2.pickle ]; then
	mkdir -p ~/nltk_data/tokenizers/punkt
	cp $2.pickle ~/nltk_data/tokenizers/punkt
fi
