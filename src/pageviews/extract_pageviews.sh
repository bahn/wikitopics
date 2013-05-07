#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -q all.q@*
#$ -l mem_free=1G
echo "$HOSTNAME:`pwd`\$ $0 $*"

if [ "$1" == "" ]; then
	echo usage: `basename $0` list_file or wikipedia_page_title
	exit
fi

if [ ! -e "$1" ]; then
	LIST_FILE=list-$RANDOM.txt
	echo $1 > $LIST_FILE
else
	LIST_FILE=$1
fi

if [ ! -s "$LIST_FILE" ]; then
	echo the $LIST_FILE file is empty
	exit 1
fi

if [ `awk 'NF>1 { print NF; exit }' $LIST_FILE` ]; then
	echo $LIST_FILE is not a proper list
	exit 1
fi

THISYEAR=`date "+%Y"`
JOBIDS=

for YEAR in `seq 2007 $THISYEAR`; do
	for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do
		ARCHIVE="$WIKISTATS/archive/$YEAR/$MONTH"
		if [ -e "$ARCHIVE" ]; then
			for FILE in $ARCHIVE/pagecounts-$YEAR$MONTH*.gz; do
				if [ -e "$FILE" ]; then
					JID=`qsub ./sub_extract_pageviews.sh $LIST_FILE $YEAR $MONTH`
					JOBIDS="$JOBIDS,`echo $JID | sed -e 's/Your job \([0-9]\+\) (\"[^\"]\+\") has been submitted/\1/'`"
				fi
				break
			done
		fi
	done
done

JOBIDS=`echo $JOBIDS | sed -e 's/^,//'`
if [ "$JOBIDS" != "" ]; then
	JID=`qsub -hold_jid $JOBIDS merge_pageviews.sh`
fi

echo done submitting jobs
