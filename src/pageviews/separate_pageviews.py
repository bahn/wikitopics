#!/usr/bin/env python

import sys
import urllib
import hashlib
import os
import os.path
#import datetime.date

# the first argument is the name of a text file that contains the title of Wikipedia pages in the list one each line
# the second argument is the file that contains pageviews; the format is "date" "page title" "page view"

titles = {}

if len(sys.argv) > 1:
	output_path = sys.argv[1]
else:
	output_path = 'pageviews'

if len(sys.argv) > 2:
	list_file = sys.argv[2]
	if not os.path.exists(list_file):
		print list_file, 'does not exist'
		sys.exit(1)
	else:
		for lines in open(list_file):
			titles[lines.strip()] = True

if len(sys.argv) > 3:
	date = sys.argv[3]
else:
	#date = datetime.date.today().isoformat()
	date = 'unknown_date'

if not os.path.isdir(output_path):
	try:
		os.makedirs(output_path)
	except:
		sys.exit(1)
assert os.path.isdir(output_path)

def title_to_filename(title):
	# convert the title into one usable as filename
	filename = urllib.quote(title, safe="%") # force / to be quoted and % not to be quoted
	if filename.startswith('.'):
		filename = "%2E" + filename[1:]
	if len(filename) > 128:
		digest = hashlib.sha224(filename).hexdigest()
		digest = urllib.quote(digest, safe="%")
		filename = filename[:128] + digest
	filename = os.path.join(output_path, filename + '_pageviews.txt')
	return filename

def open_and_append(filename):
	firstline = not os.path.exists(filename)
	filehandle = open(filename, 'a')
	if firstline:
		filehandle.write('date\tpageview\n')
	return filehandle

try:
	for line in sys.stdin:
		fields = line.split()
		title = fields[1]
		pageview = fields[2]
		if title in titles:
			del titles[title]
		filehandle = open_and_append(title_to_filename(title))
		filehandle.write(date + '\t' + pageview + '\n')
		filehandle.close()
except:
	pass
finally:
	for title in titles.keys():
		filehandle = open_and_append(title_to_filename(title))
		filehandle.write(date + '\t0\n')
		filehandle.close()
