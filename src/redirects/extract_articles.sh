#!/bin/bash

if [ "$1" == "" ]; then
	echo "extract_articles.sh DIR" 
	exit 1
fi

ls $1/*.sentences | sed -e 's/\.sentences//' -e 's/^.*\///g'
