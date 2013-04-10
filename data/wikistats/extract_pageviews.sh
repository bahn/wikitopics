#$ -S /bin/bash
#$ -j y
#$ -cwd
#$ -V
#$ -l hostname=a05
#$ -q all.q@*
#$ -l mem_free=1G

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
	exit
fi

if [ `awk 'NF>1 { print NF; exit }' $LIST_FILE` ]; then
	echo $LIST_FILE is not a proper list
	exit
fi

#TMP=foo_$RANDOM
#if [ -e "$TMP" ]; then
#	echo the $TMP temporary file exists already
#	exit
#fi

#CONDITIONS=`cat $LIST_FILE | tr '\n' ' ' | sed -e 's/ $//' -e 's/ /" || $2 == "/g' | sed -e 's/^/$2 == "/' | sed -e 's/$/"/'`
#LAST_LINE=`cat $LIST_FILE | sort | tail -1`
#cat $LIST_FILE | sort > $TMP

mkdir -p pageviews

for YEAR in 2007; do
#for YEAR in `seq 2007 2011`; do
	for MONTH in 12; do
	#for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12; do
		if [ ! -e "archive/$YEAR/$MONTH" ]; then
			continue
		fi
		if [ "$YEAR" == "2011" -a "$MONTH" \> "07" ]; then
			break
		fi
		echo "processing $YEAR $MONTH" 1>&2
		for FILE in archive/$YEAR/$MONTH/pagecounts-20071209*.gz; do
			DATETIME=`echo $FILE | sed -e 's/.*pagecounts-//' -e 's/\.gz$//'`
			#gunzip -c $FILE | awk "$CONDITIONS"' { print '\"${DATE:0:4}-${DATE:4:2}-${DATE:6:2}\"' " " $2 " " $3 } $2 > "'$LAST_LINE'" { exit }'
			echo "processing   $FILE" 1>&2
			gunzip -c $FILE | grep '^en ' | python sub_extract_pageviews.py $DATETIME $LIST_FILE | python sub_separate_pageviews.py
		done
	done
done

TEMPFILE=foo$RANDOM.txt
for FILE in pageviews/*_pageviews.txt; do
	head -1 $FILE > $TEMPFILE
	cat $FILE | grep -v '^date' | sort >> $TEMPFILE
	cat $TEMPFILE > $FILE
done
rm -f $TEMPFILE
