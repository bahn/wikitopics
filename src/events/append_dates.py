#!/usr/bin/env python
#
# The script to change the format of the daily page views of the Wikipedia articles.
# 
# Input:
#    events_date_2009
# 	the file that has all the dates 2009. The format is compatible with JSON.
# 	Examples:
# 	["1/1/2009", "1/2/2009", ..., "12/31/2009"]
# 
#    events_page_views_2009
# 	this files has the daily page views for all articles in the current events.
# 
# 	The format of the file:
# 	14th_Dalai_Lama: 125 112 97 111 ... 1219
# 
# Output:
#    events_page_views_by_date_2009
# 	this file has the same data as the input file, but in a different format:
# 	["14th_Dalai_Lama", [["12/1/2008", 2112], ..., ["12/31/2009", 1811]]]

import simplejson
import sys

dates = simplejson.load(open('events_date_2009','r'))
f = open('events_page_views_2009','r')

for line in f:
    tokens = line.split()
    sys.stdout.write('["' + tokens[0][:-1] + '", [')
    for i, date in enumerate(dates):
	sys.stdout.write('["' + date + '", ' + tokens[i+1] + ']')
	if i < len(dates) - 1:
	    sys.stdout.write(', ')
    sys.stdout.write(']]\n')
