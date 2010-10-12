#!/usr/bin/env python
import os
import re
import simplejson
import urllib

events_pattern = re.compile('current_events_for_(\d*)')

events_path = '../data/current_events'
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
