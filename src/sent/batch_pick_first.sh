#!/usr/bin/env bash
#
# batch_pick_first.sh
# --------------------------
# Print the first sentence in the articles under the given directory.
# Note that the directory that contains the source articles should be given.
# Used as baseline.
# 
# Usage: batch_pick_first source_dir output_dir
# 
# source_dir
# 	The directory that contains the source articles (the .sentences files).
# 
# output_dir
# 	The directory that the best sentences are written as files.
# 
# Output:
# 
# Into each file in output_dir, the best sentence for the file is written.
# The output files have names of the title of the articles followed by .sentences. e.g.)
# 	81st_Academy_Awards.sentences:
# 	The nominees for the 81st Academy Awards were announced  live on Thursday, January 22, 2009, at 5:38 a.m. PST (13:38 UTC) by Academy of Motion Picture Arts and Sciences president Sid Ganis and Oscar-winning actor Forest Whitaker at the Samuel Goldwyn Theater in the Academy's Beverly Hills headquarters.

if [ "$2" == "" ] || [ "$1" == "" ]
then
    echo "Usage: $0 input_dir output_dir"
    exit 1
fi

mkdir -p $2

for source in `find $1 -name "*.sentences"`
do
	short_source=`echo $source | perl -lane 's/[^\/]*\///g; print'`
	head -1 $source > $2/$short_source
done

