#!/usr/bin/env python
"""
redirect_events.py

Read events list and process redirects.
"""

import sys
sys.path.append('/mnt/data/wikitopics/src')
import wiki.utils

if len(sys.argv) != 3:
    print "usage: %s non_redirects.txt event_links" % sys.argv[0]
    sys.exit(1)

wiki.utils.read_non_redirects(sys.argv[1])

invalid_title = 0
all_title = 0

for line in open(sys.argv[2]):
    field = line.strip().split()
    title = wiki.utils.normalize_title(field[2])
    all_title += 1
    if not wiki.utils.is_valid_title(title):
        invalid_title += 1
    else:
        print field[0], field[1], title

if invalid_title > 0:
    sys.stderr.write('invalid title: %3d/%d %6.2f%%\n' % (invalid_title, all_title, float(invalid_title)/float(all_title)*100))
