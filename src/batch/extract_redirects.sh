#!/bin/bash
#$ -N ext_redir
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=1G

# memory requirements: 6G
echo $HOSTNAME extract_redirects.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "Set the WIKITOPICS environment variable first." >&2
	exit 1
fi

if [ ! -e $WIKITOPICS/src/redirects/extract_clusters.pl ]; then
	echo "extract_clusters.pl not found" >&2
	exit 1
fi
if [ ! -e $WIKITOPICS/src/redirects/extract_articles.sh ]; then
	echo "extract_articles.sh not found" >&2
	exit 1
fi

# check the command-line options
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "Usage: $0 [--dry-run] DATA_SET START_DATE [END_DATE]" >&2
    echo "Given: $0 $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

DATA_SET="$1"
START_DATE=`date --date "$2" +"%Y-%m-%d"`
if [ "$3" == "" ]; then
	END_DATE=$START_DATE
else
	END_DATE=`date --date "$3" +"%Y-%m-%d"`
fi
if [ $START_DATE \> $END_DATE ]; then
    echo "$START_DATE > $END_DATE" >&2
    exit 1
fi

# don't use LANG or LANGUAGE -- they are used by Perl.
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`

DATE=$START_DATE
while [ ! $DATE \> $END_DATE ]; do
    YEAR=${DATE:0:4}
	if [ -e $WIKITOPICS/data/html/$DATA_SET/$YEAR/$DATE.html ]; then
		mkdir -p $WIKITOPICS/data/redirects/$DATA_SET/$YEAR
		if [ ! -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.topics.revid -o $WIKITOPICS/src/redirects/extract_clusters.pl -nt $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.topics.revid ]; then
			$WIKITOPICS/src/redirects/extract_clusters.pl $WIKITOPICS/data/html/$DATA_SET/$YEAR/$DATE.html > $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.topics.revid
		fi
	fi
	if [ -e $WIKITOPICS/data/html/$DATA_SET/$YEAR/$DATE.clusters.html ]; then
		mkdir -p $WIKITOPICS/data/redirects/$DATA_SET/$YEAR
		if [ ! -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.clusters.revid -o $WIKITOPICS/src/redirects/extract_clusters.pl -nt $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.clusters.revid ]; then
			$WIKITOPICS/src/redirects/extract_clusters.pl $WIKITOPICS/data/html/$DATA_SET/$YEAR/$DATE.clusters.html > $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.clusters.revid
		fi
	fi
	if [ -d $WIKITOPICS/data/articles/$DATA_SET/$YEAR/$DATE ]; then
		mkdir -p $WIKITOPICS/data/redirects/$DATA_SET/$YEAR
		if [ ! -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.articles.list -o $WIKITOPICS/src/redirects/extract_articles.sh -nt $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.articles.list ]; then
			$WIKITOPICS/src/redirects/extract_articles.sh $WIKITOPICS/data/articles/$DATA_SET/$YEAR/$DATE > $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.articles.list
		fi
	fi

	if [ -e $WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics -o -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.topics.revid -o -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.clusters.revid -o -e $WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.articles.list ]; then
		mkdir -p $WIKITOPICS/data/articles/$DATA_SET/$YEAR/$DATE
		TOPIC_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics"
		TOPIC_HTML="$WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.topics.revid"
		CLUSTER_HTML="$WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.clusters.revid"
		OLD_ARTICLE_LIST="$WIKITOPICS/data/redirects/$DATA_SET/$YEAR/$DATE.articles.list"
		REDIRECTS2_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.redirects"
		ARTICLE_RESOLVED="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.articles.list"
		ARTICLE_FETCHED="$WIKITOPICS/data/articles/$DATA_SET/$YEAR/$DATE/$DATE.articles.list"
		FAILED_FILE="$WIKITOPICS/data/topics/$DATA_SET/$YEAR/$DATE.topics.failed"

		echo $WIKITOPICS/src/redirects/extract_redirects.py $TOPIC_FILE $TOPIC_HTML $CLUSTER_HTML $OLD_ARTICLE_LIST \
															$REDIRECTS2_FILE $NEW_ARTICLE_LIST $FAILED_FILE
		if [ ! "$DRYRUN" ]; then
			$WIKITOPICS/src/redirects/extract_redirects.py $TOPIC_FILE $TOPIC_HTML $CLUSTER_HTML $OLD_ARTICLE_LIST \
															$REDIRECTS2_FILE $ARTICLE_RESOLVED $ARTICLE_FETCHED $FAILED_FILE
		fi
	fi
    DATE=`date --date "$DATE 1 day" +"%Y-%m-%d"`
done
