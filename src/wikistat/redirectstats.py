#!/usr/bin/env python

"""
redirectstats.py

read daily wikistats and process redirect pages
output the results
"""

import gzip
import sys
import re
import urllib

# Taken from trendingtopics scripts.
# Check out http://github.com/datawrangling/trendingtopics

# Extract titles
wikistats_regex = re.compile('(.*) (.*) ([0-9].*)')

# Excludes pages outside of namespace 0 (ns0)
namespace_titles_regex = re.compile('(Media|Special' +
'|Talk|User|User_talk|Project|Project_talk|File' +
'|File_talk|MediaWiki|MediaWiki_talk|Template' +
'|Template_talk|Help|Help_talk|Category' +
'|Category_talk|Portal|Wikipedia|Wikipedia_talk|P|N)\:(.*)')

# More exclusion
image_file_regex = re.compile('(.*)\.(jpg|gif|png|JPG|GIF|PNG|txt|ico)$')

# Exclude Mediawiki boilerplate
blacklist = [
'404_error/',
'Main_Page',
'Hypertext_Transfer_Protocol',
'Favicon.ico',
'Search',
'index.html',
'Wiki'
]

def clean_anchors(page):
    # pages like Facebook#Website really are "Facebook",
    # ignore/strip anything starting at # from pagename
    anchor = page.find('#')
    if anchor > -1:
        page = page[0:anchor]
    return page

def is_valid_title(title):
    is_outside_namespace_zero = namespace_titles_regex.match(title)
    if is_outside_namespace_zero is not None:
        return False
    is_image_file = image_file_regex.match(title)
    if is_image_file:
        return False    
    has_spaces = title.find(' ')
    if has_spaces > -1:
        return False
    if title in blacklist:
        return False     
    return True    

non_redirects = {}
redirects = {}
pagecounts = {}
pagebytes = {}

def read_non_redirects(filename):
    f = open(filename, 'r')
    for line in f:
        non_redirects[unicode(line.strip(), 'utf8')] = 1

def read_redirects(filename):
    f = open(filename, 'r')
    for line in f:
        fields = unicode(line.strip(), 'utf8').split()
        redirects[fields[0]] = fields[1]

def read_wikistats(filename):
    file = gzip.open(filename, 'rb')
    for line in file:
        field = line.split()
        lang = field[0]
        if lang == 'en':
            page = unicode(field[1], 'utf8')
            if is_valid_title(page):
                title = clean_anchors(page)
                title = title[0].upper() + title[1:]
                if len(title) > 0 and title[0] != '#':
                    org_title = title
                    while title in redirects:
                        title = redirects[title]
                        if title == org_title:
                            sys.stderr.write(org_title + ' has a circular redirection\n')
                            break
                    if title in non_redirects:
                        counts = int(field[2])
                        bytes = int(field[3])
                        pagecounts[title] = pagecounts.get(title, 0) + counts
                        pagebytes[title] = bytes

if len(sys.argv) != 4:
    print "usage: redirectstats.py non_redirects.txt redirects.txt pagecounts_file"
    sys.exit(1)

read_non_redirects(sys.argv[1])
read_redirects(sys.argv[2])
read_wikistats(sys.argv[3])

sys.stderr.write(sys.argv[3] + '\n')
for title in sorted(pagecounts.keys()):
    if pagecounts[title] != 0:
        print 'en', title.encode('utf8'), pagecounts[title], pagebytes[title]
