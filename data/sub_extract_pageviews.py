#!/bin/env python

import sys
import urllib

# the first argument is the name of a text file that contains the title of Wikipedia pages in the list one each line
# the second argument is the file that contains pageviews; the format is "date" "page title" "page view"

date = sys.argv[1]

titles = []
last_title = ''
printed = {}

for title in open(sys.argv[2]):
	title = title.strip()
	if title > last_title:
		last_title = title
	titles.append(title)

try:
	for line in sys.stdin:
		fields = line.split()
		title = fields[1]
		if title in titles:
			print date, title, fields[2]
			printed[title] = True
		elif title > last_title:
			for title in titles:
				if title not in printed:
					print date, title, 0
			break
except:
	pass
finally:
	sys.stdout.flush()
