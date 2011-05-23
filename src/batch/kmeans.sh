#$ -N kmeans
#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -o /home/hltcoe/bahn/log/grid
#$ -l h_vmem=3G

echo $HOSTNAME kmeans.sh $* >&2

# check environment variables
if [ "$WIKITOPICS" == "" ]; then
	echo "the WIKITOPICS environment variable not set" >&2
	exit 1
fi
if [ "$MALLET" == "" ]; then
	echo "set the MALLET environment variable" >&2
	exit 1
fi

# check command-line options
if [ $# -lt 1 -o $# -gt 3 ]; then
	echo "Usage: $0 LANG [START_DATE [END_DATE]]" >&2
	exit 1
fi

DATA_SET="$1"
# to avoid using LANG, which is used by Perl
LANG_OPTION=`echo $DATA_SET | sed -e 's/-.\+$//'`
if [ "$2" != "" ]; then
	START_DATE=`date --date "$2" +"%Y-%m-%d"`
	if [ $? -ne 0 ]; then
		echo "error using date... fallback to using plain text" >&2
		START_DATE=$2
	fi

	if [ "$3" == "" ]; then
		END_DATE="$START_DATE"
	else
		END_DATE=`date --date "$3" +"%Y-%m-%d"`
		if [ $? -ne 0 ]; then
			echo "error using date... fallback to using plain text" >&2
			END_DATE=$3
		fi
	fi
else
# if DATE is omitted, process all articles
	START_DATE="0000-00-00"
	END_DATE="9999-99-99"
fi

INPUT_ROOT="$WIKITOPICS/data/articles/$DATA_SET"
OUTPUT_ROOT="$WIKITOPICS/data/clusters/kmeans/$DATA_SET"
for DIR in $INPUT_ROOT/*/*; do
	if [ ! -d "$DIR" ]; then # such directory not found
		continue
	fi
	DATE=`basename $DIR`
	echo $DATE | grep "^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$" > /dev/null
	if [ $? -ne 0 ]; then # the directory's name is not a date
		continue
	fi
	if [ "$START_DATE" \> "$DATE" -o "$END_DATE" \< "$DATE" ]; then # if the date falls out of the range
		continue
	fi

	YEAR=${DATE:0:4}
	INPUT_FILE="$DIR/$DATE.articles.list"
	OUTPUT_FILE="$OUTPUT_ROOT/$YEAR/$DATE.clusters"
	echo "Input: $DIR" >&2
	echo "Output: $OUTPUT_FILE" >&2
	mkdir -p `dirname $OUTPUT_FILE`
# ClusterFiles reads the input file names from the input file if it exists, otherwise reads all files in the input directory.
	java -cp $WIKITOPICS/src/cluster/kmeans/ClusterFiles:$MALLET/class:$MALLET/lib/mallet-deps.jar -Xmx2g ClusterFiles --k 50 --limit 100 --input-file $INPUT_FILE --input-dir $DIR > "$OUTPUT_FILE"
done
