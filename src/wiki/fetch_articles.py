#!/usr/bin/env python
#
# fetch_articles.py
# ----------------
# The script to get the sentences for articles.

import fetch_sentences
import datetime
import sys
import codecs
import re

if len(sys.argv) < 2:
	print "Usage: fetch_articles article_list [YYYY-MM-DD]"
	sys.exit(1)

titles = [line.strip() for line in codecs.open(sys.argv[1], "r", "utf8")]

if len(sys.argv) > 2:
	m = re.match(r'(\d{4})-(\d{2})-(\d{2})', sys.argv[2])
	date = datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
else:
	date = datetime.date.today()
	
lang = 'en'
fetch_sentences.fetch_articles_on_date(titles, date, lang, date.isoformat())
