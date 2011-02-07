#!/usr/bin/env python
"""
check if the page title is correctly encoded in utf8
and if every line has four fields each.

you can specify multiple input files in the command line.
"""

import sys
import gzip

def read_wikistats(filename):
    file = gzip.open(filename, 'rb')
    unicodeerror = 0
    try:
        for i, line in enumerate(file):
            field = line.split()
            try:
                page = unicode(field[1], 'utf8')
            except UnicodeDecodeError, error:
                unicodeerror += 1
                if unicodeerror <= 1:
                    print 'UnicodeDecodeError:', error
                    print '%s:%d: %s' % (filename, i+1, line.strip())
            if len(field) != 4:
                print 'Error: ' + filename + " has a line with less than four fields"
                print '%s:%d: %s' % (filename, i+1, line.strip())
    except IOError, error:
        print 'IOError:', error
        print 'file:', filename
    if unicodeerror > 1:
        print 'UnicodeDecodeError: ' + filename + ' has ' + str(unicodeerror - 1) + ' more UnicodeDecodeErrors'

if len(sys.argv) < 2:
    print "Usage: %s pagecounts_0 [pagecounts_1 ...]" % sys.argv[0]
    exit(-1)

files = sys.argv[1:]
for filename in files:
    read_wikistats(filename)
