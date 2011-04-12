#!/usr/bin/env python
#
# pick_from_clusters.py
#
# Pick the best sentence that describes each cluster, that contains the most recent detes.
#
# pick_from_clusters.py [YYYY-MM-DD] [/path/to/cluster/file] [/path/to/apf/directory/]

import os
import sys
import re
import bisect
from xml.dom.minidom import parse
import serif
import datetime

def read_clusters(file):
	clusters = []
	cluster = []
	for line in file:
		if (line.find('#') != -1): # eliminates comments
			line = line[:line.find('#')].strip()
		tokens = line.split(None, 1)
		if not tokens:
			if cluster:
				clusters.append(cluster)
				cluster = []
		else:
			topic = tokens[0].strip()
			cluster.append(topic)
	if cluster:
		clusters.append(cluster)
	return clusters



if __name__=='__main__':
	if len(sys.argv) != 4:
		print "Usage: pick_recent_date.py [YYYY-MM-DD] [/path/to/cluster/file] [/path/to/apf/directory/]"
		sys.exit(1)
	date = serif.convert_to_date(sys.argv[1])
	clusters = read_clusters(open(sys.argv[2], 'r'))
	path = sys.argv[3]
	for cluster in clusters:
		btimex = None
		for article in cluster:
			article = article.decode('utf-8')
			try:
				text = serif.read_sgm(os.path.join(path, article + '.sentences.sgm'))
				data = serif.read_apf(os.path.join(path, article + '.sentences.sgm.apf'))
				old_btimex = btimex
				btimex = serif.find_best_timex(date, text, data, btimex)
				if btimex != old_btimex:
					start, end = text.expand(btimex.start, btimex.end)
					line = serif.resolveCoref(text, data, start, end)
				print article.encode('utf-8')
			except IOError:
				print article.encode('utf-8') + ' # exempted due to error. check if the apf file exists.'
		if btimex and line:
			print line.encode('utf-8')
		print

