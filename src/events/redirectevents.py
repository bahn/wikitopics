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

from htmlentitydefs import name2codepoint
name2codepoint['#39'] = 39

def unescape(s):
    "unescape HTML code refs; c.f. http://wiki.python.org/moin/EscapingHtml"
    return re.sub('&(%s);' % '|'.join(name2codepoint),
                  lambda m: unichr(name2codepoint[m.group(1)]), s)

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

def normalize_title(title):
    """
    gets title in byte string,
    returns title in Unicode.
    """
    first_title = title
    title = title.strip().strip('_')
    if not is_valid_title(title):
        pass
        #sys.stderr.write(title + '\n')
        #sys.stderr.write(title + ' is not valid title\n')
    while True:
	org_title = title
	title = urllib.unquote(title)
	if org_title == title:
	    break
    # cleaning achors should be placed after unquoting,
    # because #s (anchor) are sometimes quoted as %23.
    title = clean_anchors(title)
    if title:
        title = unicode(title, 'utf8')
        title = unescape(title)
	title = title[0].upper() + title[1:]
    org_title = title
    while title in redirects:
	title = redirects[title]
	if title == org_title:
            sys.stderr.write(title.encode('utf8') + '\n')
#	    sys.stderr.write(org_title + ' has a circular redirection\n')
	    break
#    if title not in non_redirects:
#	sys.stderr.write((title + ' normalized from ' + first_title + ' but not found in non-redirects\n').encode('utf8'))
#    if title not in non_redirects:
#        sys.stderr.write(title.encode('utf8') + '\n')
    return title


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

if len(sys.argv) != 4:
    print "usage: redirectstats.py non_redirects.txt redirects.txt event_links"
    sys.exit(1)

read_non_redirects(sys.argv[1])
read_redirects(sys.argv[2])

invalid_title = 0
missing_title = 0
all_title = 0

for line in open(sys.argv[3]):
    field = line.strip().split()
    title = normalize_title(field[2])
    all_title += 1
    if not is_valid_title(title):
        invalid_title += 1
    elif title not in non_redirects:
        missing_title += 1
    else:
        print field[0], field[1], title.encode('utf8')

sys.stderr.write('invalid title: %3d/%d %6.2f%%\n' % (invalid_title, all_title, float(invalid_title)/float(all_title)*100))
sys.stderr.write('missing title: %3d/%d %6.2f%%\n' % (missing_title, all_title, float(missing_title)/float(all_title)*100))

