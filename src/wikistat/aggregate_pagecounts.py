#!/usr/bin/env python
# open a gzipped wikistats file,
# store all wikiview pagecounts for all languages separately.
# supports specifying multiple input files on the command line


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
    try:
	f = gzip.open(filename)
	content = f.read()
    except IOError:
	l = open("aggregation.log", "a+")
	l.write('%s raised an IOError while being opened\n' % filename)
	continue

    lines = content.splitlines()
    for line in lines:
	fields = line.split()
	if len(fields) < 3:
	    l = open("aggregatoin.log", "a+")
	    l.write('%s has fields less than three\n' % filename)
	    break

	l = fields[0]
	if l != prev_lang:
	    if l in lang_counts:
		counts = lang_counts[l]
	    else:
		counts = {}
		lang_counts[l] = counts
	    prev_lang = l

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
