if [ "$1" == "-v" ]; then
    VERBOSE=1
fi

for YEAR in ????; do 
    for DIR in $YEAR/??; do
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
