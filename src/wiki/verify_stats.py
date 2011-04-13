#!/usr/bin/env python
"""
check if the page title is correctly encoded in utf8
and if every line has four fields each.

you can specify multiple input files in the command line.
"""

import sys
import gzip
import datetime

def read_wikistats(filename):
	if filename.endswith(".gz"):
		file = gzip.open(filename, 'rb')
	else:
		file = open(filename, 'rb')
	#unicodeerror = 0
	try:
		for i, line in enumerate(file):
			field = line.split()
			try:
				page = unicode(field[1], 'utf8')
			except UnicodeDecodeError, error:
				#unicodeerror += 1
				#if unicodeerror <= 1:
					print 'UnicodeDecodeError:', error
					print '%s:%d: %s' % (filename, i+1, line.strip())
					sys.exit(1)
			if len(field) != 4:
				print 'Error: ' + filename + " has a line with less than four fields"
				print '%s:%d: %s' % (filename, i+1, line.strip())
				sys.exit(1)
	except IOError, error:
		print 'IOError:', error
		print 'file:', filename
		sys.exit(1)
	#if unicodeerror > 1:
		#print 'UnicodeDecodeError: ' + filename + ' has ' + str(unicodeerror - 1) + ' more UnicodeDecodeErrors'
		#sys.exit(1)

if len(sys.argv) != 2:
	print "Usage: %s pagecounts_file" % sys.argv[0]
	exit(1)

read_wikistats(sys.argv[1])
