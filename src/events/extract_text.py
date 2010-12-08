#!/usr/bin/env python
#
# extract_text.py
#
# Extract the text describes the Wikipedia current events.
# 
# Usage:
# 	extract_text.py events_json_path
# 
# Input:
# 	events_json_path
# 		the directory that has the events files in JSON.
# 		Each file in the directory has a name such as 'current_events_for_20090101'
# 		and contains only one line in JSON that describes the Wikipedia current events for that day.
# 		e.g.
# [{"text": "*A man is shot and killed at California's Fruitvale BART station by a Bay Area Rapid Transit officer.", "externallinks": {"(Mercury News)": "http://www.mercurynews.com/ci_11369592?source%253Dmost_emailed.26978592730A3B8C7F471EACE0DA4EF2.html"}, "links": {"California": "California", "A man is shot": "BART Police shooting of Oscar Grant", "Bay Area Rapid Transit": "Bay Area Rapid Transit", "Fruitvale BART station": "Fruitvale_(BART_station)"}, "revid": 340308501}, ...]
# 
# Output: the standard output
# 	Each line describes an Wikipedia current events and contains
# 	the date and index of the event and the text that describes the events.
# 	The format is as follows:
# 
# 20090101 0 *A man is shot and killed at California's Fruitvale BART station by a Bay Area Rapid Transit officer.
# 20090101 1 *An Israeli airstrike on the Gaza Strip city of Jabalia kills senior Hamas military commander Nizar Rayan and six members of his family.
# 20090101 2 *At least five people die and more than 50 are injured in serial bombings in Guwahati, India.
# 20090101 3 *Russia's Gazprom halts deliveries of natural gas to Ukraine after negotiations over prices fail.
# ...

import os
import re
import simplejson
import urllib
import sys

if len(sys.argv) < 2:
	print 'Usage: extract_text.py events_json_path'
	sys.exit(1)

events_pattern = re.compile('current_events_for_(\d*)')

events_path = sys.argv[1]
for filename in sorted(os.listdir(events_path)):
    groups = events_pattern.match(filename).groups()
    date = groups[0]
    file = open(os.path.join(events_path, filename), 'r')
    json = simplejson.load(file)
    for i, event in enumerate(json):
	text = event['text']
	if isinstance(text, unicode):
	    print date, i, text.encode('utf-8')
	else:
	    print date, i, text
