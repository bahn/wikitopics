#!/usr/bin/env python
"""
filter_stats.py

Read daily wikistats and process redirect pages
output the results

Print only existing pages
"""

import sys
import urllib
import gzip
import utils

pagecounts = {}

def read_wikistats(lang, f):
    """
    Read wikistats and process redirect pages
    """
    try:
        for line in f:
            try:
                field = line.split()
                if lang == field[0]:
                    page = field[1]
                    if utils.is_valid_title(page) and utils.is_title_in_ns0(page):
                        if not REDIRECTS:
                            print line,
                        else:
                            title = utils.normalize_title(page)
                            if title:
                                pagecounts[title] = pagecounts.get(title, 0) + int(field[2])
            except UnicodeError:
                sys.stderr.write("UnicodeError: %s" % line)
            except IndexError:
                sys.stderr.write("IndexError: %s" % line)
    except IOError:
        sys.stderr.write("IOError")
    finally:
        if f:
            f.close()

if __name__=="__main__":
    LANG = ''
    REDIRECTS = ''
    ALL_TITLES = ''
    while len(sys.argv) > 1 and sys.argv[1].startswith('-'):
        if sys.argv[1] == '-l' and len(sys.argv) > 2:
            LANG = sys.argv[2]
            sys.argv[1:3] = []
        elif sys.argv[1] == '-r' and len(sys.argv) > 2:
            REDIRECTS = sys.argv[2]
            sys.argv[1:3] = []
        elif sys.argv[1] == '-a' and len(sys.argv) > 2:
            ALL_TITLES = sys.argv[2]
            sys.argv[1:3] = []
        else:
            sys.stderr.write('Unknown switch: ' + sys.argv[1] + '\n')
            sys.exit(1)

    if len(sys.argv) > 2 or not LANG or (not REDIRECTS and not ALL_TITLES):
        print "usage: %s -l lang [-r redirects.txt] [-a all_titles_in_ns0] [pagecounts_file]" % sys.argv[0]
        sys.exit(1)

    if REDIRECTS:
        utils.read_redirects(REDIRECTS)
    if ALL_TITLES:
        utils.read_all_titles_in_ns0(ALL_TITLES)

    if len(sys.argv) == 1:
        read_wikistats(LANG, sys.stdin)
    elif sys.argv[1].endswith('.gz'):
        read_wikistats(LANG, gzip.open(sys.argv[1]))
    else:
        read_wikistats(LANG, open(sys.argv[1]))

    if REDIRECTS:
        for page in sorted(pagecounts.keys()):
            print LANG, page, pagecounts[page]
