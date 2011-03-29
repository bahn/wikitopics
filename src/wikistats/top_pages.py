#!/usr/bin/env python
# open a gzipped wikistats file,
# print out 100 most-viewed pages
# supports specifying multiple input files on the command line

import sys
import gzip

top_what = 1000

if len(sys.argv) == 1:
    print "try %s filename" % sys.argv[0]
    exit(0)

def print_out_most_viewed(lang, counts):
    values = sorted(counts.values(), reverse=True)
    if len(values) > top_what:
	values = values[0:top_what]
    min_value = values[-1]
    rank = {}
    for i in range(0, min(len(values), top_what)):
	v = values[i]
	if not v in rank:
	    rank[v] = i+1
    top_list = []
    for key in counts.keys():
	if counts[key] >= min_value:
	    top_list.append((rank[counts[key]], key, counts[key]))
    top_list.sort()
    for rank, key, count in top_list:
	print lang, rank, key, count
    sys.stdout.flush()

files = sys.argv[1:]
for filename in files:
    f = gzip.open(filename)
    content = f.read()
    lines = content.splitlines()
    language = ''
    counts = {}
    for line in lines:
	fields = line.split()
	l = fields[0]
	if l != language:
	    if len(counts) > 0:
		print_out_most_viewed(language, counts)
	    language = l
	    counts = {}
	counts[fields[1]] = int(fields[2])
    if len(counts) > 0:
	print_out_most_viewed(language, counts)
