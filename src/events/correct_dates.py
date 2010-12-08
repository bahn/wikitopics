#!/usr/bin/env python
#
# correct_dates.py
#
# The script to change the date format of daily page views from 'YYYYMMDD' to 'MM/DD/YYYY'
#
# Input: the standard input
#	["14th_Dalai_Lama", [["20081201", 2112], ..., ["20091231", 1811]]]
# 
# Output: the standard output
#	["14th_Dalai_Lama", [["12/1/2008", 2112], ..., ["12/31/2009", 1811]]]

import simplejson
import sys

for line in sys.stdin:
	json = simplejson.loads(line)
	if len(json[1]) > 0:
		for i, tuple in enumerate(json[1]):
			date = tuple[0]
			newdate = str(int(date[4:6])) + "/" + str(int(date[6:8])) + "/" + date[0:4]
			tuple[0] = newdate
		print simplejson.dumps(json)
