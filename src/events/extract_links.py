#!/usr/bin/env python
#
# extract_links.py

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
