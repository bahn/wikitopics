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

sys.path.append("..")
import wiki.utils

if len(sys.argv) == 1:
    print "Usage: %s pagecount_0 [pagecount_1 ...]" % sys.argv[0]
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
                    fields = line.split()
                    lang = fields[0]
                    if lang != prev_lang:
                        counts = lang_counts.setdefault(lang, {})
                        prev_lang = lang
                    title = fields[1]
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
