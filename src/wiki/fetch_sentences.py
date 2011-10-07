#!/usr/bin/env python
#
# fetch_sentences.py
# ------------------
# Fetch wikipedia articles in plain text on a specified date.

import sys
import datetime
from splitting import determine_splitter
import codecs
import re
import os
import utils
import urllib
import time
import wikipydia
import wpTextExtractor

def read_lines_from_file(filename, encoding='utf8'):
	"""																													   
	Reads a file in utf8 encoding into an array																			   
	"""
	lines = []
	input_file = codecs.open(filename, encoding=encoding)
	for line in input_file:
		lines.append(line.rstrip('\n'))
	input_file.close()
	return lines

def write_lines_to_file(output_filename, lines):
	"""																													 \
	Writes a list of lines to file.																					   \
	"""
	output_file = open(output_filename, 'w')
	for line in lines:
		output_file.write(line.encode('UTF-8'))
		output_file.write('\n'.encode('UTF-8'))
	output_file.close()
	return lines

def fetch_articles_on_date(topics, date, lang, output_dir, upperlimit, dryrun, retry=5, wait=5):
	if os.path.exists(output_dir):
		if not os.path.isdir(output_dir):
			sys.stderr.write(output_dir + " is not a directory\n")
			sys.exit(1)
	else:
		os.makedirs(output_dir)

	mark = {}
	success = 0
	articles = {}
	mark = {}
	for article, values in topics.items():
		if success >= upperlimit:
			break
		title = article

		# the file prefix for output files
		file_prefix = urllib.quote(title.replace(' ','_').encode('utf8'), safe="%") # force / to be quoted and % not to be quoted
		if file_prefix.startswith('.'):
			file_prefix = "%2E" + file_prefix[1:]

		# resolve redirects
		if not wikipydia.query_exists(title, lang):
			continue
		title = wikipydia.query_redirects(title, lang).replace(' ','_')

		if title in mark:
			continue
		mark[title] = True

		if dryrun:
			print file_prefix
			success += 1
			continue

		done = False
		no_retry = 0
		while not done and no_retry < retry:
			try:
				revid = values['thenid']
				if revid == 0:
					revid = wikipydia.query_revid_by_date_fallback(title, lang, date)
				wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
				done = True
			except:
				no_retry += 1
				time.sleep(wait)

		sentences, tags, citations = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True, True)
		# substitute angle brackets with html-like character encodings
		#sentences = [re.sub('<', '&lt;', re.sub('>', '&gt;', s)) for s in sentences]
		#sentences.insert(0, urllib.unquote(file_prefix.replace('_',' ')) + '.')
		output_filename = os.path.join(output_dir, file_prefix + '.sentences')
		output = write_lines_to_file(output_filename, sentences)
		output_filename = os.path.join(output_dir, file_prefix + '.tags')
		output = write_lines_to_file(output_filename, tags)
		success += 1

		priorid = values['priorid']
		if priorid == 0:
			priorid = wikipydia.query_revid_by_date_fallback(title, lang, date - datetime.timedelta(days=15))
		articles[title] = {'score': values['score'], 'thenid': revid, 'priorid': priorid}
		sys.stderr.write('.')
	sys.stderr.write('\n')

	if not dryrun:
		if len(articles) > 1 or (len(articles) == 1 and output_dir != '.'):
			write_articles(articles, topics, os.path.join(output_dir, date.strftime('%Y-%m-%d') + '.articles.list'))

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

if __name__=='__main__':
	lang = 'en'
	date = datetime.date.today()
	output_dir = '.'
	upperlimit = 1000
	dryrun = False
	while len(sys.argv) > 1 and sys.argv[1].startswith('-'):
		if len(sys.argv) > 2 and sys.argv[1] == '-l':
			lang = sys.argv[2]
			sys.argv[1:3] = []
		elif len(sys.argv) > 2 and sys.argv[1] == '-d':
			date = utils.convert_date(sys.argv[2])
			sys.argv[1:3] = []
		elif len(sys.argv) > 2 and sys.argv[1] == '-o':
			output_dir = sys.argv[2]
			sys.argv[1:3] = []
		elif len(sys.argv) > 2 and sys.argv[1] == '-u':
			upperlimit = int(sys.argv[2])
			sys.argv[1:3] = []
		elif sys.argv[1] == '--dry-run':
			dryrun = True
			sys.argv[1:2] = []
		else:
			sys.stderr.write("Unknown option: %s\n" % (sys.argv[1]))
			sys.exit(1)
	if len(sys.argv) < 2:
		sys.stderr.write('Usage: ' + sys.argv[0] + ' [--dry-run] [-u upper limit] [-l language] [-d date] [-o output_dir] article_list\n')
		sys.exit(1)

	topics = {}
	for argv in sys.argv[1:]:
		if os.path.isfile(argv):
			lines = read_lines_from_file(argv)
			for line in lines:
				field = dict([(i, f) for i, f in enumerate(line.split())])
				topics[field[0]] = {'score': int(field.get(1, '0')), 'thenid': int(field.get(2, '0')), 'priorid': int(field.get(3, '0'))}
		else:
			sys.stderr.write(argv + ' file not found. looking for Wikipedia page named ' + argv + '...\n')
			topics[argv.decode('utf8')] = {'score': 0, 'thenid': 0, 'priorid': 0}
	fetch_articles_on_date(topics, date, lang, output_dir, upperlimit, dryrun)
