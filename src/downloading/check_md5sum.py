#!/usr/bin/env python

import sys
import os.path
import hashlib

if len(sys.argv) < 4:
	print os.path.basename(sys.argv[0]), 'md5sums.txt basename filepath'

md5sum_filename = sys.argv[1]
filename = sys.argv[2]
filepath = sys.argv[3]

md5sums = {}
for line in open(md5sum_filename):
	fields = line.split()
	assert len(fields) == 2
	md5sums[fields[1]] = fields[0]

if filename not in md5sums:
	print filename, 'is not in the file list; exiting successfully...'
	sys.exit(0)

contents = open(filepath, 'rb').read()
md5sum = hashlib.md5(contents).hexdigest()

if md5sum != md5sums[filename]:
	print filename, 'failed the checksum test'
	sys.exit(1)
