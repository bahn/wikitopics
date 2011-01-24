# extract_cluster.sh
#
# Usage:
#	extract_cluster.sh [# clusters] [doc-topics filename]

if [ $# -ne 2 ]
then
	echo "Usage: $0 [# clusers] [doc-topics filename]"
	exit
fi

num_clusters=$1
file=$2

for (( i = 0; i < $num_clusters; i++ ))
do
	awk '$3=='$i' {print $2}' $file | sed 's/.*\///g' | sed 's/\.sentences*$//g'
	echo
done
