#!/usr/bin/env python
#
# extract_links.py
# ----------------
# WRONG It used urllib.quote_plus to quote the links. It should not have.
# 
# the script to convert the events file into the events links file.
# 
# Usage:
# 	extract_links.py events_json_path
# 
# Input:
# 	events_json_path
# 		the directory that has the events files in JSON.
# 		Each file in the directory has a name such as 'current_events_for_20090101'
# 		and contains only one line in JSON that describes
# 		the Wikipedia current events for that day.
# 		e.g.
# [{"text": "*A man is shot and killed at California's Fruitvale BART station by a Bay Area Rapid Transit officer.", "externallinks": {"(Mercury News)": "http://www.mercurynews.com/ci_11369592?source%253Dmost_emailed.26978592730A3B8C7F471EACE0DA4EF2.html"}, "links": {"California": "California", "A man is shot": "BART Police shooting of Oscar Grant", "Bay Area Rapid Transit": "Bay Area Rapid Transit", "Fruitvale BART station": "Fruitvale_(BART_station)"}, "revid": 340308501}, ...]
# 
# Output: the standard output
# 	Each line describes a Wikipedia article linked from an event and contains
# 	the date and index of the event and the title of a Wikipedia article.
# 	The format is as follows:
# 
# 20090101 0 BART_Police_shooting_of_Oscar_Grant
# 20090101 0 California
# 20090101 0 Bay_Area_Rapid_Transit
# 20090101 0 Fruitvale_%28BART_station%29
# ...

import os
import re
import simplejson
import urllib
import sys

if len(sys.argv) < 2:
	print 'Usage: extract_links.py events_json_path'
	sys.exit(1)

events_pattern = re.compile('current_events_for_(\d*)')
events_path = sys.argv[1]

for filename in sorted(os.listdir(events_path)):
    groups = events_pattern.match(filename).groups()
    date = groups[0]
    file = open(os.path.join(events_path, filename), 'r')
    json = simplejson.load(file)
    for i, event in enumerate(json):
	links = event['links']
	for value in links.values():
	    print date, i, urllib.quote(value.replace(' ','_').encode('utf-8'))
