#!/usr/bin/env python
#
# create_links_to_wikiarticles.py
# 
# OBSOLETE
# Create a HTML file to the article revisions of a specified date.
# Do not need any arguments; the path from which the data will be read is hard-wired in the code.

import os
import wikipydia
import datetime
import wikipydia
import yaml

wikitrends_data = '/Users/bahn/workspace/wikitrends/data/'
clustering_path = os.path.join(wikitrends_data, 'clustering')

data = [('pick0127', '0127', 1, 27),
	('pick0210', '0210', 2, 10),
	('pick0419', '0419', 4, 19),
	('pick0512', '0512', 5, 12),
	('pick1012', '1012', 10, 12)]

for one in data:
    filename = os.path.join(clustering_path, one[0])
    dirname = os.path.join(clustering_path, one[1])
    htmlname = os.path.join(clustering_path, 'list' + one[1] + '.html')
    try:
	os.mkdir(dirname)
    except:
	pass
    f = open(filename, 'r')
    fout = open(htmlname, 'w')
    fout.write("""<html>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<head>
<title>Wikipedia articles as of 2009%s</title>
</head>
<body>
""" % (one[1]))
    for line in f:
	line = line.strip()
	json = wikipydia.query_revision_by_date(line, date=datetime.date(2009, one[2], one[3]))
	pages = json['query']['pages']
	if len(pages) > 1:
	    throw
	
	for page in pages:
	    revid = pages[page]['revisions'][0]['revid']
	    fout.write("<a href='http://en.wikipedia.org/w/index.php?title=%s&oldid=%s'>%s</a><br>\n" % (line, revid, line))
    fout.write("""</body>
</html>
""")
