#!/usr/bin/env python
#
# Append specific dates to the page views statistics.
#
# Input:
#    events_date_2009
#    events_page_views_2009
# Output:
#    events_page_views_by_date_2009

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
