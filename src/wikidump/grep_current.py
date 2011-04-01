#!/usr/bin/env python
"""
grep_current.py
version 0.1

the filename of edit logs are in the form of
enwiki-20100130-pages-meta-history.xml.gz

grep {{current}} tags from wiki edit log
and print them out in a yaml format

one thing I assumed is a {{current}} tag always 
appear at the same line as the <text> tag when
an article starts

updates

version 0.1: put a version according to Chris' request
             print the tag recognized for each record
"""

import sys
if len(sys.argv) == 1:
    f = sys.stdin
else:
    f = open(sys.argv[1],'r')

page_on = False
revision_on = False
text_on = False
current_on = False
recent_on = False
has_current = False
has_recent = False
current_tag = ''
recent_tag = ''

page_title = ''
page_namespace = None
revision_id = ''
revision_stamp = ''

namespace = {"Media":-2,
    "Special":-1,
    "Talk":1,
    "User":2,
    "User talk":3,
    "Wikipedia":4,
    "Wikipedia talk":5,
    "File":6,
    "File talk":7,
    "MediaWiki":8,
    "MediaWiki talk":9,
    "Template":10,
    "Template talk":11,
    "Help":12,
    "Help talk":13,
    "Category":14,
    "Category talk":15,
    "Portal":100,
    "Portal talk":101,
    "Book":108,
    "Book talk":109}

for line in f:
    line = line.rstrip('\n')
    if text_on:
	line = line.lower()
	if line.find('{{current') != -1:
	    has_current = True
	    left = line.find('{{current')
	    right = line.find('}}', left+9)+2
	    current_tag = line[left:right]
	if line.find('{{recent') != -1:
	    has_recent = True
	    left = line.find('{{recent')
	    right = line.find('}}', left+8)+2
	    current_tag = line[left:right]
	if line[-7:] == '</text>':
	    text_on = False
    elif not page_on:
	if line[2:8] == '<page>':
	    page_on = True
	    current_on = False
	    recent_on = False
    elif not revision_on:
	if line[-7:] == '</page>':
	    page_on = False
	elif line[4:14] == '<revision>':
	    revision_on = True
	    has_current = False
	    has_recent = False
	    current_tag = ''
	    recent_tag = ''
	elif line[4:11] == '<title>':
	    page_title = line[11:-8]
    else:
	if line[-11:] == '</revision>':
	    revision_on = False
	    if has_current != current_on or has_recent != recent_on:
		current_on = has_current
		recent_on = has_recent
		if page_namespace is None:
		    page_namespace = 0
		    for v in namespace.keys():
			if len(page_title) > len(v) and page_title[len(v)] == ':' and page_title[0:len(v)] == v:
			    page_namespace = namespace[v]
		print '- title     :', page_title
		print '  namespace :', page_namespace
		print '  current   :', current_on
		if current_tag:
		    print '  ctag      :', current_tag
		print '  recent    :', recent_on
		if recent_tag:
		    print '  rtag      :', recent_tag
		print '  revid     :', revision_id
		print '  timestamp :', revision_stamp
	elif line[6:12] == '<text ':
	    text_on = True
	    line = line.lower()
	    if line.find('{{current') != -1:
		has_current = True
		left = line.find('{{current')
		right = line.find('}}', left+9)+2
		current_tag = line[left:right]
	    if line.find('{{recent') != -1:
		has_recent = True
		left = line.find('{{recent')
		right = line.find('}}', left+8)+2
		current_tag = line[left:right]
	elif line[6:10] == '<id>':
	    revision_id = line[10:-5]
	elif line[6:17] == '<timestamp>':
	    revision_stamp = line[17:-12]
