#!/usr/bin/env python

"""
add_stats.py

open a gzipped wikistats file,
store all wikiview pagecounts for all languages separately.
supports specifying multiple input files on the command line
"""

import os
import sys
import gzip

LANG = ''
FILTER = 0
while len(sys.argv) > 1 and sys.argv[1].startswith('-'):
    if sys.argv[1] == '-l' and len(sys.argv) > 2:
        LANG = sys.argv[2]
        sys.argv[1:3] = []
    elif sys.argv[1] == '-f' and len(sys.argv) > 2:
        FILTER = int(sys.argv[2])
        sys.argv[1:3] = []
    else:
        sys.stderr.write("Unknown switch: " + sys.argv[1] + "\n")
        sys.exit(1)

if len(sys.argv) == 1:
    print "Usage: %s [-f FILTER] pagecount_0 [pagecount_1 ...]" % sys.argv[0]
    exit(1)

lang_counts = {}
counts = None
prev_lang = '';

files = sys.argv[1:]
for filename in files:
    if os.path.exists(filename):
        f = None
        indexError = False
        unicodeError = False
        try:
            f = gzip.open(filename)
            for line in f:
                try:
                    if LANG and not line.startswith(LANG + ' '):
                        continue
                    fields = line.split()
                    lang = fields[0]
                    if lang != prev_lang:
                        counts = lang_counts.setdefault(lang, {})
                        prev_lang = lang
                    title = fields[1]
                    pagecounts = int(fields[2])
                    if pagecounts > FILTER:
                        counts[title] = counts.get(title, 0) + int(fields[2])
                except IndexError:
                    indexError = True
                except UnicodeError:
                    unicodeError = True
        except IOError:
            sys.stderr.write('IOError: ' + filename)
        finally:
            if indexError:
                sys.stderr.write('IndexError: ' + filename)
            if unicodeError:
                sys.stderr.write('UnicodeError: ' + filename)
            if f:
                f.close()

for lang in sorted(lang_counts.keys()):
    counts = lang_counts[lang]
    for title in sorted(counts.keys()):
	print '%s %s %s' % (lang, title, counts[title])
