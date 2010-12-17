#!/usr/bin/env bash
#
# batch_pick_self.sh
# ------------------
# 	Run the script that picks the best sentence with the self reference
# 	for all the file in the given directory.
# 	
# 	Usage: batch_pick_self.sh input_dir YYYY-MM-DD output_dir
# 
# 	input_dir
# 		The directory that contains the .sgm and .apf files. Both files should exist to be processed correctly.
# 	
# 	YYYY-MM-DD
# 		The date on which the retrieved article are based on.
# 		The temporal expressions in the articles that are closest to this date will be seleceted.
# 	
# 	output_dir
# 		The directory that the best sentences are written as files.
# 	
# 	Output:
# 
# 	Into each file in output_dir, the best sentence for the file is written.
# 	The output files have names of the title of the articles followed by .sentences. e.g.)
# 		81st_Academy_Awards.sentences:
# 		The nominees for the 81st Academy Awards were announced  live on Thursday, January 22, 2009, at 5:38 a.m. PST (13:38 UTC) by Academy of Motion Picture Arts and Sciences president Sid Ganis and Oscar-winning actor Forest Whitaker at the Samuel Goldwyn Theater in the Academy's Beverly Hills headquarters.

if [ "$3" == "" ] || [ "$2" == "" ] || [ "$1" == "" ]
then
    echo "Usage: $0 input_dir YYYY-MM-DD output_dir"
    exit 1
fi

mkdir -p $3

for sgm in `find $1 -name "*.sgm"`
do
	short_sgm=`echo $sgm | perl -lane 's/[^\/]*\///g; s/\.apf$//; s/\.sgm$//; s/\.sentences//; print'`
    if [ -f $sgm.apf ]
    then
	./pick_self.py $2 $sgm $sgm.apf > $3/$short_sgm.sentences

# OBSOLETE. From batch_pick_recent_dates.sh
# Alternative output format:
# 
# Each line contains 2 fields: the title of the article, and the sentence selected from the article, separated by the tab (\t) character.
# The output is written in the standard output.
# 4chan	Boxxy is the online name of a young woman who in January 2009 became the subject of debate on various websites, including 4chan, because of her YouTube videos.
# 81st_Academy_Awards	The nominees for the 81st Academy Awards were announced  live on Thursday, January 22, 2009, at 5:38 a.m. PST (13:38 UTC) by Academy of Motion Picture Arts and Sciences president Sid Ganis and Oscar-winning actor Forest Whitaker at the Samuel Goldwyn Theater in the Academy's Beverly Hills headquarters.
# ...

	#best_sentence=`./pick_recent_date.py $2 $sgm $sgm.apf`
	# echo "$short_sgm $best_sentence"#
	# replace a space with a tab character | perl -lane 's/^(\S+) /\1\t/; print'
    else
	echo "# $sgm.apf does not exist"
    fi
done

