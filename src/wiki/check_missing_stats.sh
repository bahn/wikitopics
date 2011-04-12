#!/bin/bash
if [ "$1" == "-h" ]; then
    echo "Usage: $0 [-v] [DIR]" >&2
    exit 1
fi
if [ "$1" == "-v" ]; then
    VERBOSE=1
    shift
fi
CWD=`pwd`
if [ "$1" != "" -a -d "$1" ]; then
    cd $1
elif [ "$1" != "" ]; then
    echo "$1 is not a directory" >&2
    exit 1
fi

for YEAR in ????; do 
    for DIR in $YEAR/??; do
        if [ ! -e "$DIR" ]; then
            continue
        fi
        MONTH=`basename $DIR`
        for I in `seq 31`; do
            DAY=`printf "%02d" $I`
            COUNT=`ls $YEAR/$MONTH/*$YEAR$MONTH$DAY* 2>/dev/null | grep $YEAR$MONTH$DAY | wc -l`
            if [ $COUNT -ne 48 -a $COUNT -ne 24 ]; then
                if [ $COUNT -eq 0 -a $DAY -eq 31 ]; then
                    if [ $MONTH -eq 2 -o $MONTH -eq 4 -o $MONTH -eq 6 -o $MONTH -eq 9 -o $MONTH -eq 11 ]; then
                        continue
                    fi
                fi
                if [ $COUNT -eq 0 -a $DAY -gt 28 -a $MONTH -eq 2 ]; then
                    continue
                fi
                if [ $COUNT -eq 0 ]; then
                    echo "$YEAR$MONTH$DAY missing"
                else
                    echo "$YEAR$MONTH$DAY has $COUNT files"
                    if [ $VERBOSE ]; then
                        ls $YEAR/$MONTH/* | grep $YEAR$MONTH$DAY
                    fi
                fi
            fi
        done
    done
done

for YEAR in ????; do 
    for I in `seq 12`; do
        MONTH=`printf "%02d" $I`
        COUNT=` ls $YEAR/*$YEAR$MONTH* 2>/dev/null | grep $YEAR$MONTH | wc -l`
        if [ $COUNT -eq 0 ]; then
            continue;
        fi
        for J in `seq 31`; do
            DAY=`printf "%02d" $J`
            if [ $DAY -eq 31 ]; then
                if [ $MONTH -eq 2 -o $MONTH -eq 4 -o $MONTH -eq 6 -o $MONTH -eq 9 -o $MONTH -eq 11 ]; then
                    continue
                fi
            fi
            if [ $DAY -gt 28 -a $MONTH -eq 2 ]; then
                date --date "$YEAR$MONTH$DAY" >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    continue
                fi
            fi
            COUNT=`ls $YEAR/*$YEAR$MONTH$DAY* 2>/dev/null | grep $YEAR$MONTH$DAY | wc -l`
            if [ $COUNT -eq 0 ]; then
                echo "$YEAR$MONTH$DAY missing"
            fi
        done
    done
done

cd $CWD
