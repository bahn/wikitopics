#!/bin/env python

import sys
import urllib
import hashlib
import os
import os.path

# the first argument is the name of a text file that contains the title of Wikipedia pages in the list one each line
# the second argument is the file that contains pageviews; the format is "date" "page title" "page view"

if not os.path.isdir('pageviews'):
	try:
		os.makedirs('pageviews')
	except:
		sys.exit(-1)
assert os.path.isdir('pageviews')

files = {}

try:
	for line in sys.stdin:
		fields = line.split()
		date = fields[0]
		title = fields[1]
		pageview = fields[2]
		if title not in files:
			# convert the title into one usable as filename
			filename = urllib.quote(title.encode('utf8'), safe="%") # force / to be quoted and % not to be quoted
			if filename.startswith('.'):
				filename = "%2E" + filename[1:]
			if len(filename) > 128:
				digest = hashlib.sha224(filename).hexdigest()
				digest = urllib.quote(digest, safe="%")
				filename = filename[:128] + digest
			filename = 'pageviews/' + filename + '_pageviews.txt'
			firstline = not os.path.exists(filename)
			files[title] = open(filename, 'a')
			if firstline:
				files[title].write('date\tpageview\n')
		files[title].write(date + '\t' + pageview + '\n')
except:
	pass
finally:
	for filehandle in files.values():
			filehandle.close()
