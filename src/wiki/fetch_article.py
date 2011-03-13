#!/usr/bin/env python
#
# fetch_article.py
# ----------------
# The script to get the sentences for an article.
# Note that the fetch_sentences.py script gets all the articles
# while this script get only one article.

import fetch_sentences
import datetime
import sys
import re

#lang = 'en'
#fetch_sentences.fetch_articles_on_date(['Lawrence_Kutner'], datetime.date(2010,12,11), lang, '2010-12-11')
#fetch_sentences.fetch_articles_on_date(['2004_Indian_Ocean_earthquake'], datetime.date(2010,12,11), lang, '2010-12-11')
#fetch_sentences.fetch_articles_on_date(['Lawrence_Kutner'], datetime.date(2010,6,22), lang, '2010-06-22')
#fetch_sentences.fetch_articles_on_date(['2004_Indian_Ocean_earthquake'], datetime.date(2010,6,22), lang, '2010-06-22')
#sys.exit(0)

if len(sys.argv) < 2:
	print "Usage: fetch_article article_title [YYYY-MM-DD]"
	sys.exit(1)

title = sys.argv[1]
if len(sys.argv) > 2:
	m = re.match(r'(\d{4})-(\d{2})-(\d{2})', sys.argv[2])
	date = datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
else:
	date = datetime.date.today()
lang = 'en'
fetch_sentences.fetch_articles_on_date([title], date, lang, '.')
