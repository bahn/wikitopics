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
LOGPREFIX="$DATE:"

mkdir -p log
rm -rf working_$DATE
mkdir -p working_$DATE
cd working_$DATE
wget -nv -o wget.log http://dammit.lt/wikistats/
if [ -e wget.log ]
then
    cat wget.log >> ../log/daily_stats_$DATE.log
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
        echo $FILE
    done
else
    for FILE in $FILES
    do
        BASENAME=`basename $FILE`
        mkdir -p ../../latest/$YEAR/$MONTH
        rm -f $BASENAME
        wget -nv -o wget.log http://dammit.lt/wikistats/$FILE
        if [ -e wget.log ]
        then
            cat wget.log >> ../log/daily_stats_$DATE.log
            rm -f wget.log
        fi
        if [ ! -e $BASENAME ]
        then
            echo "$LOGPREFIX failed to download $FILE" >&2
        else
            mv $BASENAME ../../latest/$YEAR/$MONTH
            COUNT=$((COUNT+1))
        fi
    done
fi

wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/
if [ -e wget.log ]; then
    cat wget.log >> ../log/daily_stats_$DATE.log
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
        echo $FILE
    done
    cd ..
    rmdir working_$DATE
    exit 0
fi

for FILE in $FILES2; do
    BASENAME=`basename $FILE`
    mkdir -p ../../archive/$YEAR/$MONTH
    rm -f $BASENAME
    wget -nv -o wget.log http://dammit.lt/wikistats/archive/$YEAR/$MONTH/$FILE
    if [ -e wget.log ]
    then
        cat wget.log >> ../log/daily_stats_$DATE.log
        rm -f wget.log
    fi
    if [ ! -e $BASENAME ]
    then
        echo "$LOGPREFIX failed to download $FILE" >&2
    else
        mv $BASENAME ../../archive/$YEAR/$MONTH
        COUNT=$((COUNT+1))
    fi
done

rm -f SUCCESS
for FILE in $FILES2; do
    BASENAME=`basename $FILE`
    if [ -e ../../archive/$YEAR/$MONTH/$BASENAME -a -e ../../latest/$YEAR/$MONTH/$BASENAME ]; then
        if diff -q ../../archive/$YEAR/$MONTH/$BASENAME ../../latest/$YEAR/$MONTH/$BASENAME > /dev/null; then
            echo $BASENAME >> SUCCESS
        fi
    fi
done

if [ -e SUCCESS ]; then
    for FILE in `cat SUCCESS`; do
        rm -f ../../latest/$YEAR/$MONTH/$BASENAME
        COUNT=$((COUNT-1))
    done
    rm -f SUCCESS
fi
cd ..
rmdir working_$DATE

if [ $COUNT -ne 48 ]
then
    echo "$LOGPREFIX missing or redudant: $COUNT files downloaded." >&2
fi

for FILE in FILES; do
    BASENAME=`basename $FILE`
    if [ -e ../latest/$YEAR/$MONTH/$BASENAME ]; then
        ../../../src/wikistat/verify_stats.py ../latest/$YEAR/$MONTH/$BASENAME > /dev/null
        if [ $? -ne 0 ]; then
            echo "$LOGPREFIX $FILE failed verification." >&2
        fi
    fi
done

for FILE in FILES2; do
    BASENAME=`basename $FILE`
    if [ -e ../archive/$YEAR/$MONTH/$BASENAME ]; then
        ../../../src/wikistat/verify_stats.py ../archive/$YEAR/$MONTH/$BASENAME > /dev/null
        if [ $? -ne 0 ]; then
            echo "$LOGPREFIX $FILE failed verification." >&2
        fi
    fi
done
