#!/usr/bin/env python
# verify_pagecounts.py
#      (originally from aggregate_pagecounts.py)
#
# open a gzipped wikistats file,
# store all wikiview pagecounts for all languages separately.
# supports specifying multiple input files on the command line
#
# this script performs an additional check to see if every line has four fields each.

import sys
import gzip

#language = 'en'

if len(sys.argv) == 1:
    print "try %s filename" % sys.argv[0]
    exit(0)

lang_counts = {}
counts = {}
prev_lang = '';

files = sys.argv[1:]
for filename in files:
    f = gzip.open(filename)
    content = f.read()
    lines = content.splitlines()
    for line in lines:
	fields = line.split()
	l = fields[0]
	if l != prev_lang:
	    if l in lang_counts:
		counts = lang_counts[l]
	    else:
		counts = {}
		lang_counts[l] = counts
	    prev_lang = l

	if len(fields) != 4:
	    print filename
	    print line
	    print fields

	k = fields[1]
	v = int(fields[2])
	if k in counts:
	    counts[k] += v
	else:
	    counts[k] = v
    f.close()

for lang in sorted(lang_counts.keys()):
    counts = lang_counts[lang]
    for k in sorted(counts.keys()):
	print '%s %s %s' % (lang, k, counts[k])
