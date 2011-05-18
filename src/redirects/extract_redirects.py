#!/usr/bin/env python
"""
Extract redirects
"""
import sys
import urllib
import wikipydia
import os
import collections

lang = ''

def read_topics(topics, filename):
	if not os.path.exists(filename):
		return
	f = open(filename, 'r')
	for l in f:
		fields = l.strip().split()
		topics[fields[0].decode('utf8')] = int(fields[1])
	f.close()

def read_html(revids, filename):
	if not os.path.exists(filename):
		return
	global lang
	print filename
	f = open(filename, 'r')
	for l in f:
		fields = dict([(i, field) for i, field in enumerate(l.strip().split())])
		if not lang:
			lang = fields[0]
		else:
			assert lang == fields[0]
		revids[fields[1].decode('utf8')] = {'score': int(fields[2]), 'thenid': int(fields[3]), 'priorid': int(fields.get(4,0))}
	f.close()

def read_articles_list(articles, filename):
	if not os.path.exists(filename):
		return
	f = open(filename, 'r')
	for l in f:
		title = urllib.unquote(l.strip())
		articles[title.decode('utf8')] = {'score': 0, 'thenid': 0, 'priorid': 0}
	f.close()

# TODO This method is copied to wiki/check_revision.py
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

# TODO This method is copied to wiki/check_revision.py, wiki/fetch_sentences.py
# Need to merge
def write_articles(articles, topics, filename):
	if not articles:
		return
	f = open(filename, 'w')
	for a in sorted(articles.keys(), key=lambda t: articles[t]['score'], reverse=True):
		v = articles[a]
		f.write(a.encode('utf8') + ' ' + str(v['score']) + ' ' + str(v['thenid']) + ' ' + str(v['priorid']) + '\n')
	f.close()

# TODO This method is copied to wiki/check_revision.py
# Need to merge
def write_failed(failed, topics, filename):
	if not failed:
		return
	f = open(filename, 'w')
	for t in failed:
		f.write(t.encode('utf8') + ' ' + str(topics.get(t, 0)) + '\n')
	f.close()

if __name__=='__main__':
	if len(sys.argv) != 9:
		sys.stderr.write("extract_redirects.py topics topic_html clusters_html fetched_articles_list articles_redirects_out articles_resolved_out articles_fetched_out failed_out\n")
		sys.exit(1)

	topics = {}
	topics_html = {}
	clusters_html = {}
	articles = {}

	read_topics(topics, sys.argv[1])
	read_html(topics_html, sys.argv[2])
	read_html(clusters_html, sys.argv[3])
	read_articles_list(articles, sys.argv[4])

	to_resolve = []
	to_resolve.extend([t for t in topics.keys() if t not in articles]) # from topics
	to_resolve.extend([t for t in topics_html.keys() if t not in articles]) # from topics_html
	to_resolve.extend([c for c in clusters_html.keys() if c not in articles]) # from clusters_html
	to_resolve = list(set(to_resolve)) # remove duplicates

	# filter pages that do not exist
	existing = dict([(t, 1) for t in to_resolve if wikipydia.query_exists(t)])
	failed = [t for t in to_resolve if t not in existing] # non-existing pages
	to_resolve = [t for t in to_resolve if t in existing] # only existing pages
	
	# filter pages whose redirects exist in articles
	redirects = dict([(t, wikipydia.query_redirects(t).replace(' ','_')) for t in to_resolve])
	to_resolve = [t for t in to_resolve if t in articles]

	# at least one of the pages in the article list now redirects to a different page
	if to_resolve:
		a2r = [(a, wikipydia.query_redirects(a).replace(' ','_')) for a in articles]
		r2a = dict([(r, a) for a, r in a2r if a != r]) # pages that have a changed redirect page
		to_update = dict([(t, r2a[t]) for t in to_resolve if t in r2a])
		redirects.update(to_update)

		to_resolve = [t for t in to_resolve if t not in to_update]
		if to_resolve:
			print "Still pages that failed:", to_resolve
			print "(Should not exist at this stage)"
		failed.extend(to_resolve)
	
	# articles resolved for revision ids, whether the text was not fetched or not
	articles_resolved = dict([(redirects.get(t, None) or t, v) for t, v in topics_html.items()]) # resolve redirects for topics_html
	articles_resolved.update(dict([(redirects.get(t, None) or t, v) for t, v in clusters_html.items()])) # resolve redirects for clusters_html
	for a in articles_resolved:
		articles_resolved[a]['score'] = 0 # initialize scores

	# sum up the trending scores
	for t, v in topics.items():
		t = redirects.get(t, None) or t # resolve redirects
		if t in articles_resolved:
			articles_resolved[t]['score'] += v

	# update fetched articles
	articles.update(dict([(a, articles_resolved[a]) for a in articles]))

	write_redirects(redirects, topics, sys.argv[5])
	write_articles(articles_resolved, topics, sys.argv[6])
	write_articles(articles, topics, sys.argv[7])
	write_failed(failed, topics, sys.argv[8])
