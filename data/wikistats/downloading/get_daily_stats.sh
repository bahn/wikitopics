#!/bin/bash
# get_daily_stats.sh
# Download Wikipedia page view statistics for a specific day
# from where the most recent statistics files get dumped.
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -ne 1 ]; then
    echo "Usage: $0 [--dry-run] DATE"
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

DATE=`date --date $1 +"%Y%m%d"`
YEAR=${DATE:0:4}
MONTH=${DATE:4:2}
DAY=${DATE:6:2}
LOGPREFIX="$YEAR-$MONTH-$DAY"
WORKING="working_$DATE"
LOGFILE="log/daily_stats_$DATE.log"

if [ -e $WORKING ]; then
	echo "$WORKING directory exists; cancelling..." >&2
	echo "delete it and try again." >&2
	exit 1
fi

mkdir -p log
mkdir -p $WORKING
cd $WORKING

# download the file listing in the latest folder
wget -nv -o wget.log http://dammit.lt/wikistats/
if [ -e wget.log ]
then
    cat wget.log >> ../$LOGFILE
    rm -f wget.log
fi

if [ ! -e index.html ]
then
    echo "$LOGPREFIX fail to download the directory listing" >&2
    cd ..
    exit 1
fi

FILES=`grep $DATE index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
rm -f index.html

COUNT=0
if [ $DRYRUN ]; then
    for FILE in $FILES; do
		BASENAME=`basename $FILE`
		if [ -e ../../arhive/$YEAR/$MONTH/$BASENAME ]; then
            echo "$BASENAME already exists; pass" >&2
		else
			echo http://dammit.lt/wikistats/$FILE
			COUNT=$[COUNT+1]
		fi
    done
else
    for FILE in $FILES; do
        BASENAME=`basename $FILE`
        if [ -e ../../arhive/$YEAR/$MONTH/$BASENAME ]; then
            echo "$BASENAME already exists; pass" >&2
            continue
        fi
        mkdir -p ../../archive/$YEAR/$MONTH
		# delete if any file of the same name exists
        rm -f $BASENAME
		# download the file
        wget -nv -o wget.log http://dammit.lt/wikistats/$FILE
        if [ -e wget.log ]; then
            cat wget.log >> ../$LOGFILE
            rm -f wget.log
        fi
        if [ ! -e $BASENAME ]; then
            echo "$LOGPREFIX failed to download $FILE" >&2
        else
            mv $BASENAME ../../archive/$YEAR/$MONTH
			COUNT=$[COUNT+1]
        fi
    done
fi

# download the file listing in the archive
wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]; then
    cat wget.log >> ../$LOGFILE
    rm -f wget.log
fi

if [ ! -e index.html ]; then
    echo "$LOGPREFIX fail to download the directory listing http://dammit.lt/wikistats/archive/$YEAR/$MONTH/" >&2
    cd ..
    exit 1
fi

FILES2=`grep $DATE index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
rm -f index.html

if [ $DRYRUN ]; then
    for FILE in $FILES2; do
		BASENAME=`basename $FILE`
		if [ -e ../../archive/$YEAR/$MONTH/$BASENAME ]; then
			echo "$BASENAME already exists; pass" >&2
			continue
		else
			echo http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
			COUNT=$[COUNT+1]
		fi
    done
else
	for FILE in $FILES2; do
		BASENAME=`basename $FILE`
		if [ -e ../../archive/$YEAR/$MONTH/$BASENAME ]; then
			echo "$BASENAME already exists; pass" >&2
			continue
		fi
		mkdir -p ../../archive/$YEAR/$MONTH
		# delete if any file has the same file name
		rm -f $BASENAME
		wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
		if [ -e wget.log ]
		then
			cat wget.log >> ../$LOGFILE
			rm -f wget.log
		fi
		if [ ! -e $BASENAME ]
		then
			echo "$LOGPREFIX failed to download $FILE" >&2
		else
			mv $BASENAME ../../archive/$YEAR/$MONTH
			COUNT=$[COUNT+1]
		fi
	done
fi

cd ..
rmdir $WORKING

if [ $COUNT -ne 48 ]
then
	echo "$LOGPREFIX files missing or redudant: $COUNT files downloaded." >&2
fi

if [ ! $DRYRUN ]; then
	for FILE in $FILES; do
		BASENAME=`basename $FILE`
		if [ -e ../archive/$YEAR/$MONTH/$BASENAME ]; then
			/mnt/data/wikitopics/src/wikistats/verify_stats.py ../archive/$YEAR/$MONTH/$BASENAME > /dev/null
			if [ $? -ne 0 ]; then
				echo "$LOGPREFIX $FILE failed verification." >&2
			fi
		fi
	done

	for FILE in $FILES2; do
		BASENAME=`basename $FILE`
		if [ -e ../archive/$YEAR/$MONTH/$BASENAME ]; then
			/mnt/data/wikitopics/src/wikistats/verify_stats.py ../archive/$YEAR/$MONTH/$BASENAME > /dev/null
			if [ $? -ne 0 ]; then
				echo "$LOGPREFIX $FILE failed verification." >&2
			fi
		fi
	done
fi
