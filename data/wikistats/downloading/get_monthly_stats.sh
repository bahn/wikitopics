#!/bin/bash
# get_monthly_stats.sh
# Download archived Wikipedia page view statistics for a specific month.
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    shift
fi
if [ $# -ne 2 ]
then
    echo "Usage: get_monthly_stats.sh [--dry-run] YEAR MONTH" >&2
    echo "Given command-line options: $*" >&2
    exit 1
fi
if [ $DRYRUN ]; then
    echo "Running a dry run..."
fi

YEAR=$1
MONTH=`printf "%02d" $2`
LOGPREFIX="$YEAR$MONTH:"

mkdir -p log
rm -rf working_$YEAR$MONTH
mkdir -p working_$YEAR$MONTH
cd working_$YEAR$MONTH
wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]
then
    cat wget.log >> ../log/monthly_stats_$YEAR$MONTH.log
    rm -f wget.log
fi

if [ ! -e index.html ]
then
    echo "$LOGPREFIX fail to download the directory listing" >&2
    cd ..
    exit
fi

FILES=`grep $YEAR$MONTH index.html | sed -e 's/^.*href="//' -e 's/".*$//'`
rm -f index.html

COUNT=0
if [ $DRYRUN ]; then
    for FILE in $FILES; do
        echo $FILE
    done
    cd ..
    rmdir working_$YEAR$MONTH
    exit 0
fi

rm -f SUCCESS
for FILE in $FILES; do
    BASENAME=`basename $FILE`
    mkdir -p ../../archive/$YEAR/$MONTH
    rm -f $BASENAME
    wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
    if [ $? -ne 0 -o ! -e $BASENAME ]
    then
        echo "$LOGPREFIX failed to download $FILE" >&2
        if [ -e $BASENAME ]
        then
            rm -f $BASENAME
        fi
    else
        if [ -e ../../latest/$YEAR/$MONTH/$BASENAME ]
        then
            if diff -q $BASENAME ../../latest/$YEAR/$MONTH/$BASENAME > /dev/null; then
                echo $BASENAME >> SUCCESS
                #rm -f ../../latest/$YEAR/$MONTH/$BASENAME
            else
                echo "$LOGPREFIX previous downloaded $BASENAME does not match with the one just downloaded." >&2
                echo $BASENAME >> ../../latest/$YEAR/$MONTH/FAILED
            fi
        fi
        mv $BASENAME ../../archive/$YEAR/$MONTH
        COUNT=$((COUNT+1))
    fi
    if [ -e wget.log ]
    then
        cat wget.log >> ../log/monthly_stats_$YEAR$MONTH.log
        rm -f wget.log
    fi
done

if [ -e SUCCESS ]; then
    for FILE in `cat SUCCESS`; do
        rm -f ../../latest/$YEAR/$MONTH/$FILE
    done
    rm -f SUCCESS
fi
cd ..
rmdir working_$YEAR$MONTH

if [ $[$COUNT % 48] -ne 0 ]
then
    echo "$LOGPREFIX some files are missing: only $COUNT files downloaded." >&2
else
    echo "$LOGPREFIX downloading $COUNT files succeeded."
fi

if [ -e ../latest/$YEAR/$MONTH ]
then
    rmdir ../latest/$YEAR/$MONTH
    if [ $? -ne 0 ]
    then
        echo "$LOGPREFIX the previous downloading folder is not empty." >&2
    fi
fi

if [ -e ../latest/$YEAR ]
then
    rmdir ../latest/$YEAR
    rmdir ../latest
fi

for FILE in $FILES; do
    BASENAME=`basename $FILE`
    if [ -e ../archive/$YEAR/$MONTH/$BASENAME ]; then
        ../../../src/wikistat/verify_stats.py ../archive/$YEAR/$MONTH/$BASENAME > /dev/null
        if [ $? -ne 0 ]; then
            echo "$LOGPREFIX $FILE failed verification." >&2
        fi
    fi
done
