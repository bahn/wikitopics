#!/usr/bin/env python
import sys
import re
import datetime
import urllib
import os
import wikipydia
import utils
import traceback

def read_topics(filename, lang, date, topics, articles, redirects, failed):
	try:
		f = open(filename, 'r')
		for line in f:
			fields = line.split()
			title = fields[0].decode('utf8')
			pageviews = int(fields[1]) if len(fields) > 1 else 0

			# set failed
			topics[title] = pageviews
			if not wikipydia.query_exists(title, lang):
				failed.append(title)
				continue

			try:
				# set redirects
				r = wikipydia.query_redirects(title, lang).replace(' ','_')
				if title != r:
					title = r
				thenid = wikipydia.query_revid_by_date_fallback(title, lang, date)
				priorid = wikipydia.query_revid_by_date_fallback(title, lang, date - datetime.timedelta(days=15))

				if title != r:
					redirects[title] = r
				# set articles
				if title not in articles:
					articles[title] = {'score': 0}
				articles[title]['score'] += pageviews
				articles[title]['thenid'] = thenid
				articles[title]['priorid'] = priorid
			except:
				sys.stderr.write('Failed while checking the title: ' + title + '\n')
				sys.stderr.flush()
				traceback.print_exc(file=sys.stderr)
				sys.stderr.flush()
	finally:
		if f:
			f.close()

# TODO This method is copied from redirects/extract_redirects.py
# Need to merge
def write_redirects(redirects, topics, filename):
	if not redirects:
		return
	f = open(filename, 'w')
	for t in sorted(redirects.keys()):
		r = redirects[t]
		if t != r:
			f.write(t.encode('utf8') + ' ' + r.encode('utf8') + ' ' + str(topics.get(t, 0)) + '\n')
	f.close()

# TODO This method is copied from redirects/extract_redirects.py
# Need to merge
def write_articles(articles, topics, filename):
	if not articles:
		return
	f = open(filename, 'w')
	for a in sorted(articles.keys(), key=lambda t: articles[t]['score'], reverse=True):
		v = articles[a]
		f.write(a.encode('utf8') + ' ' + str(v['score']) + ' ' + str(v['thenid']) + ' ' + str(v['priorid']) + '\n')
	f.close()

# TODO This method is copied from redirects/extract_redirects.py
# Need to merge
def write_failed(failed, topics, filename):
	if not failed:
		return
	f = open(filename, 'w')
	for t in failed:
		f.write(t.encode('utf8') + ' ' + str(topics.get(t, 0)) + '\n')
	f.close()

if __name__=='__main__':
	if len(sys.argv) != 7:
		sys.stderr.write('Usage: %s LANGUAGE YYYY-MM-DD TOPIC REDIRECTS_OUT ARTICLES_OUT FAILED_OUT\n' % sys.argv[0])
		sys.exit(1)
	lang = sys.argv[1]
	date = utils.convert_date(sys.argv[2])
	articles = {}
	redirects = {}
	topics = {}
	failed = []
	read_topics(sys.argv[3], lang, date, topics, articles, redirects, failed)
	write_redirects(redirects, topics, sys.argv[4])
	write_articles(articles, topics, sys.argv[5])
	write_failed(failed, topics, sys.argv[6])
