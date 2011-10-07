if [ $# -ne 2 ]; then
    echo $0 K DAYS
    exit 1
fi
mkdir -p kmeans-$1-$2/raw
#time ./run --input /mnt/data/wikitopics/data/mix/2009-01-27-$2 --k $1 > kmeans-$1-$2/raw/kmeans_0127
#time ./run --input /mnt/data/wikitopics/data/mix/2009-02-10-$2 --k $1 > kmeans-$1-$2/raw/kmeans_0210
#time ./run --input /mnt/data/wikitopics/data/mix/2009-04-19-$2 --k $1 > kmeans-$1-$2/raw/kmeans_0419
time ./run --input /mnt/data/wikitopics/data/mix/2009-05-12-$2 --k $1 > kmeans-$1-$2/raw/kmeans_0512
#time ./run --input /mnt/data/wikitopics/data/mix/2009-10-12-$2 --k $1 > kmeans-$1-$2/raw/kmeans_1012
cd kmeans-$1-$2/raw
for file in *; do
    cat $file | grep -v '^2009-' > ../$file;
done
cd ../..
