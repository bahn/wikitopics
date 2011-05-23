#!/bin/bash
#$ -N conv_clust
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=1G

echo $HOSTNAME convert_clusters.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi
if [ "$WIKISTATS" == "" ]; then
	echo "Set the WIKISTATS environment variable first." >&2
	exit 1
fi
if [ ! -f "$WIKITOPICS/src/html/convert_clusters.pl" ]; then
	echo "The $WIKITOPICS/src/html/convert_clusters.pl script not found" >&2
	exit 1
fi

# check command-line options
while [ "$1" == "-w" -o "$1" == "-l" -o "$1" == "-c" ]; do
	if [ "$1" == "-w" ]; then
		WINDOW_SIZE="$1 $2"
		shift; shift
	fi
	if [ "$1" == "-l" ]; then
		LIST_SIZE="$1 $2"
		shift; shift
	fi
	if [ "$1" == "-c" ]; then
		CUT_OFF="$1 $2"
		shift; shift
	fi
done

if [ $# -lt 2 -o $# -gt 3 ]; then
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

# set working directories
CLUSTERS_DIR="$WIKITOPICS/data/clusters/kmeans/$DATA_SET"
HTML_EX_ROOT="/export/people/bahn/wikitopics"
if [ "$DATA_SET" == "en" ]; then
    HTML_EX_DIR="$HTML_EX_ROOT"
else
    HTML_EX_DIR="$HTML_EX_ROOT/$DATA_SET"
fi

if [ ! -d "$CLUSTERS_DIR" ]; then
	echo "$CLUSTERS_DIR not found" >&2
	exit 1
fi
#if [ ! -d "$HTML_ROOT" ]; then
#	echo "$HTML_ROOT not found" >&2
#	exit 1
#fi

DATE=$START_DATE
while [ ! $END_DATE \< $DATE ]; do
    YEAR=${DATE:0:4}
    MONTH=${DATE:5:2}
    DAY=${DATE:8:2}


	TOPIC_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics"
	REDIRECTS_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.redirects"
	ARTICLES_RESOLVED="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.articles.list"
	FAILED_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics.failed"
    if [ -e "$TOPIC_FILE" ]; then
		echo check_revisions.py $LANG_OPTION $DATE $TOPIC_FILE $REDIRECTS_FILE $ARTICLES_RESOLVED $FAILED_FILE >&2
		$WIKITOPICS/src/wiki/check_revisions.py $LANG_OPTION $DATE $TOPIC_FILE $REDIRECTS_FILE $ARTICLES_RESOLVED $FAILED_FILE
    fi

	ARTICLES_LIST="$WIKITOPICS/data/articles/$DATA_SET/$YEAR/$DATE/$DATE.articles.list"
    CLUSTERS_FILE="$CLUSTERS_DIR/$YEAR/$YEAR-$MONTH-$DAY.clusters"
	SENTENCE_DIRS="$WIKITOPICS/data/sentences/*/$DATA_SET/$YEAR/$DATE"
	TEMP_FILE="$WIKITOPICS/src/html/$DATA_SET-$DATE-$RANDOM.html"
    HTML_FILE="$WIKITOPICS/data/html/$DATA_SET/$YEAR/$YEAR-$MONTH-$DAY.clusters.html"

    if [ -e "$ARTICLES_LIST" -a -e "$CLUSTERS_FILE" ]; then
        echo "convert_clusters.py -t `basename $ARTICLES_LIST` `basename $CLUSTERS_FILE` $SENTENCE_DIRS > `basename $HTML_FILE`" >&2
        mkdir -p `dirname $HTML_FILE`
        if $WIKITOPICS/src/html/convert_clusters.py -t $ARTICLES_LIST -l $LANG_OPTION $CLUSTERS_FILE $SENTENCE_DIRS > $TEMP_FILE; then
			mv $TEMP_FILE $HTML_FILE
			if [ -d "$HTML_EX_ROOT" ]; then
				echo # do nothing
				#mkdir -p $HTML_EX_DIR/$YEAR
				#cp $HTML_FILE $HTML_EX_DIR/$YEAR
			else
				scp $HTML_FILE login.clsp.jhu.edu:$HTML_EX_DIR/$YEAR
			fi
		else # don't remove the temporary file so that it can be referred to later
			rm -f $TEMP_FILE # remove the temporary file if converting failed
		fi
	else
		echo "$DATE: file not found. $ARTICLES_LIST or $CLUSTERS_FILE" >&2
    fi
    DATE=`date --date "$DATE 1 day" +"%Y-%m-%d"`
done
