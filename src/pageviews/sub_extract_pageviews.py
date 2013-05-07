#!/usr/bin/env python

import sys
import urllib
import os.path

# the first argument is the name of a text file that contains the title of Wikipedia pages in the list one each line
# the second argument is the file that contains pageviews; the format is "date" "page title" "page view"

if len(sys.argv) < 2:
	print 'usage:', os.path.basename(sys.argv[0]), 'LIST_FILE'
	sys.exit(1)

list_file = sys.argv[1]
if not os.path.exists(list_file):
	print list_file, 'does not exit. failing...'
	sys.exit(1)

titles = []
last_title = ""

for title in open(list_file):
	title = title.strip()
	if title > last_title:
		last_title = title
	titles.append(title)

try:
	for line in sys.stdin:
		fields = line.split()
		if len(fields) > 2:
			title = fields[1]
			if title in titles:
				sys.stdout.write(line)
			elif title > last_title:
				break
except:
	pass
finally:
	sys.stdout.flush()
