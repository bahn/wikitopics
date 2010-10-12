#!/usr/bin/env python
import sys
import simplejson

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
page_file = open(page_filename, 'r')

pages = {}
redirects = {}

PAGE_STARTING = 'INSERT INTO `page` VALUES '
for line in page_file:
    if line.startswith(PAGE_STARTING):
	line = line[len(PAGE_STARTING):-2]
	bucket = read_tuples(line)
	for page in bucket:
	    page_id = int(page[0])
	    page_namespace = int(page[1])
	    page_title = page[2]
	    page_is_redirect = page[5]

	    if page_namespace == 0:
		if not page_is_redirect:
		    pages[page_id] = page_title
		else:
		    redirects[page_id] = page_title

page_file.close()

redirect_filename = sys.argv[2]
redirect_file = open(redirect_filename, 'r')

REDIRECT_STARTING = 'INSERT INTO `redirect` VALUES '
for line in redirect_file:
    if line.startswith(REDIRECT_STARTING):
	line = line[len(REDIRECT_STARTING):-2]
	bucket = read_tuples(line)
	for redirect in bucket:
	    rd_from = redirect[0]
	    rd_namespace = redirect[1]
	    rd_title = redirect[2]
	    if rd_namespace == 0:
		if rd_from in redirects:
		    page_title = redirects[rd_from]
		    redirects[rd_from] = (page_title, rd_title)

redirect_file.close()

non_redirects = open('non_redirects.txt','w')
for page_title in sort(pages.values()):
    non_redirects.write(page_title + '\n')
non_redirects.close()

redirects_file = open('redirects.txt','w')
for redirect in redirects:
    redirects_file.write(redirect[0] + ' ' + redirect[1] + '\n')
redirects_file.close()
