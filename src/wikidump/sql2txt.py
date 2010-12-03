#!/usr/bin/env python
#
# sql2txt.py
#
# Input: page.sql and redirects.sql
# Output: redirects.txt and non_redirects.txt

import sys
import simplejson
import gzip

def read_tuples(line):
    i = 0
    length = len(line)
    bucket = []
    while i < length:
	if line[i] == '(':
	    i += 1
	    l = []
	    s = ''
	    quoted = False
	    escaped = False
	    while True:
		if escaped:
		    s += line[i]
		    escaped = False
		elif line[i] == "'":
		    quoted = not quoted
		elif quoted:
		    if line[i] == '\\':
			escaped = True
		    else:
			s += line[i]
		elif line[i] == ',':
		    l.append(s)
		    s = ''
		elif line[i] == ')':
		    i += 1
		    l.append(s)
		    break
		else:
		    s += line[i]
		i += 1
	    t = tuple(l)
	    bucket.append(t)
	elif line[i] == ',':
	    i += 1
	elif line[i] == ';':
	    break
    return bucket

if len(sys.argv) < 3:
    print "usage: sql2txt [page_file] [redirect_file]"
    sys.exit(0)

page_filename = sys.argv[1]
if page_filename.endswith('.gz'):
	page_file = gzip.open(page_filename, 'r')
else:
	page_file = open(page_filename, 'r')

pages = {}
redirect_pages = {}

PAGE_STARTING = 'INSERT INTO `page` VALUES '
for line in page_file:
    if line.startswith(PAGE_STARTING):
	line = line[len(PAGE_STARTING):-2]
	bucket = read_tuples(line)
	for page in bucket:
	    page_id = int(page[0])
	    page_namespace = int(page[1])
	    page_title = page[2]
	    page_is_redirect = bool(int(page[5]))

	    if page_namespace == 0:
		if not page_is_redirect:
		    pages[page_id] = page_title
		else:
		    redirect_pages[page_id] = page_title

page_file.close()

redirect_filename = sys.argv[2]
if redirect_filename.endswith('.gz'):
	redirect_file = gzip.open(redirect_filename, 'r')
else:
	redirect_file = open(redirect_filename, 'r')

redirects = {}

REDIRECT_STARTING = 'INSERT INTO `redirect` VALUES '
for line in redirect_file:
    if line.startswith(REDIRECT_STARTING):
	line = line[len(REDIRECT_STARTING):-2]
	bucket = read_tuples(line)
	for redirect in bucket:
	    rd_from = int(redirect[0])
	    rd_namespace = int(redirect[1])
	    rd_title = redirect[2]
	    if rd_namespace == 0:
		if rd_from in redirect_pages:
		    page_title = redirect_pages[rd_from]
		    if page_title in redirects:
			print page_title, 'is already in redirects'
		    redirects[page_title] = (rd_title)

redirect_file.close()

non_redirects = open('non_redirects.txt','w')
for page_title in sorted(pages.values()):
    non_redirects.write(page_title + '\n')
non_redirects.close()

redirects_file = open('redirects.txt','w')
for page_title in sorted(redirects.keys()):
    redirects_file.write(page_title + ' ' + redirects[page_title] + '\n')
redirects_file.close()
