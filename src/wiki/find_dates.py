#!/usr/bin/env python
import os
import re
mypath = '/Users/bahn/Desktop/wikitopics/2009-01-27'

den = 0
num = 0

def g(dir, filename):
    global den
    global num
    print filename
    datere = re.compile('(January|February|March|April|May|June|July|August|September|October|November|December)( \d+,)? 2009')
    path = os.path.join(dir, filename)
    file = open(path, 'r')
    check = 0
    for line in file:
	line = line.strip()
	if datere.search(line):
	    print line
	    if check == 0:
		num += 1
		check = 1
    print
    den += 1

def myfun(dummy, dir, files):
    for child in files:
        if '.sentences' == os.path.splitext(child)[1] and os.path.isfile(dir+'/'+child):
            g(dir, child)

os.path.walk(mypath, myfun, 3)
print num, den, (float(num)/float(den))
