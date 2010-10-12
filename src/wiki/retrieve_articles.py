#!/usr/bin/env python
#
# Retrieves all the wikipedia article for a given set of specific dates.
# Currently the dates are, by default, Jan 27, Feb 10, Apr 19, May 12, and Oct 12.
# Output are five folds:
#   YYYY_MM_DD_revid_Title
#   YYYY_MM_DD_revid_Title.html
#   YYYY_MM_DD_revid_Title.categories
#   YYYY_MM_DD_revid_Title.links
#
# Note that the 

import os
import wikipydia
import datetime
import wikipydia
import yaml

wikitrends_data = '/Users/bahn/workspace/wikitrends/data/'
clustering_path = os.path.join(wikitrends_data, 'clustering')

#data = [('pick0127', '0127', 1, 27),
#	('pick0210', '0210', 2, 10),
#	('pick0419', '0419', 4, 19),
#	('pick0512', '0512', 5, 12),
#	('pick1012', '1012', 10, 12)]

data = [('pick0512', '0512', 5, 12),
	('pick1012', '1012', 10, 12)]

dirname = os.path.join(clustering_path, 'articles')
try:
    os.mkdir(dirname)
except:
    pass

print "Retrieving wikipedia articles..."
print "  retrieved articles will be stored under", dirname

for i, one in enumerate(data):
    filename = os.path.join(clustering_path, one[0])
    file = open(filename, 'r')
    month = one[2]
    day = one[3]
    print "Data", (i+1), ": wikipedia articles in", filename
    for line in file:
	title = line.strip()
	print "  retrieving wikipedia article", title

	# Retrieve the last revision id for the given title
	print "    determining the last revision id for the article..."
	json = wikipydia.query_revision_by_date(title, date=datetime.date(2009, month, day))
	pages = json['query']['pages']
	if len(pages) > 1:
	    throw
	for page in pages:
	    revid = pages[page]['revisions'][0]['revid']
	# Construct base name for the files to be stored
	basename = '2009_%02d_%02d_%d_%s' % (month, day, revid, title)

	# Retrieve the last revision id for the title
	json = wikipydia.query_text_raw(title)
	lastrevid = json['revid']
	basename_lastrev = '2009_%02d_%02d_%d_%s' % (month, day, lastrevid, title)

	# Retrieve raw text and write it to a file
	print "    retrieving raw text into", os.path.join(dirname, basename)
	json = wikipydia.query_text_raw_by_revision(revid)
	text = json['text']
	f = open(os.path.join(dirname, basename), 'w')
	f.write(text.encode('utf-8'))
	f.close()

	# Extracts plain text from the text and store it
	print "    extracting plain text into", os.path.join(dirname, basename + '.txt')
	f = open(os.path.join(dirname, basename + '.txt'), 'w')
	f.write(wikipydia.get_plain_text(text).encode('utf-8'))
	f.close()

	# Retrieve parsed text in html format and write it to a file
	print "    retrieving html text into", os.path.join(dirname, basename + '.html')
	json = wikipydia.query_text_rendered(title, oldid=revid)
	html = json['html']
	f = open(os.path.join(dirname, basename + '.html'), 'w')
	f.write(html.encode('utf-8'))
	f.close()

	# Retrieve the categories for the article and write it to a file.
	# Note that the categories are of the latest revision rather than those of the given revision.
	print "    retrieving categories into", os.path.join(dirname, basename_lastrev + '.categories')
	categories = wikipydia.query_categories(title)
	f = open(os.path.join(dirname, basename_lastrev + '.categories'), 'w')
	f.writelines([category.encode('utf-8') + '\n' for category in categories])
	f.close()

	# Retrieve the links for the article and write it to a file.
	# Note that the links are of the latest revision rather than those of the given revision.
	print "    retrieving links into", os.path.join(dirname, basename_lastrev + '.links')
	links = wikipydia.query_links(title)
	f = open(os.path.join(dirname, basename_lastrev + '.links'), 'w')
	f.writelines([link.encode('utf-8') + '\n' for link in links])
	f.close()
