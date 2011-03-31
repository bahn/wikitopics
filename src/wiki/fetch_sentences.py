#!/usr/bin/env python
#
# fetch_sentences.py
# ------------------
# Fetch wikipedia articles in plain text on a specified date.
# It needs wiktrans to have been installed because it heavily uses
# its sentence splitting module.
#
# After you activate the virtual environments for wikitrans (e.g. by workon wt.dev)
# you need to set the environment variable PYTHONPATH to the root directory
# of the wikitrans project.
# For example, the command for my environment is as below.
# export PYTHONPATH=/Users/bahn/Desktop/wikitrans-system/wikitrans/wt-app/
#
# The above path is for this module to import the manage module that resides
# in the manage.py file under the specified directory.
# The manage module in turn sets all necessary environment variables.

#import manage
import sys
import datetime
#from wt_articles.splitting import determine_splitter
from splitting import determine_splitter
import codecs
import re
import os
import utils
import urllib
try:
	import wikipydia
	import wpTextExtractor
except:
	sys.path.append('/home/bahn/work/wikipydia')
	sys.path.append('/home/bahn/work/wpTextExtractor')
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

def fetch_articles_on_date(topics, date, lang, output_dir):
	if os.path.exists(output_dir):
		if not os.path.isdir(output_dir):
			sys.stderr.write(output_dir + " is not a directory\n")
			sys.exit(1)
	else:
		os.makedirs(output_dir)

	for article in topics:
		title = article
		if not wikipydia.query_exists(title):
			continue
		title = wikipydia.query_redirects(title)
		while True:
			revid = wikipydia.query_revid_by_date(title, lang, date)
			wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
			# legacy code. redirects should have been processed by wikipydia.query_redirects.
			if wikimarkup.lower().startswith('#redirect [['):
				title = wikimarkup[12:-2]
			else:
				break
		sentences, tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
		# substitute angle brackets with html-like character encodings
		sentences = [re.sub('<', '&lt;', re.sub('>', '&gt;', s)) for s in sentences]
		title = urllib.quote(title.replace(' ','_').encode('utf8'))
		output_filename = os.path.join(output_dir, title + '.sentences')
		output = write_lines_to_file(output_filename, sentences)

if __name__=='__main__':
	lang = 'en'
	date = datetime.date.today()
	output_dir = '.'
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
		else:
			sys.stderr.write("Unknown option: %s\n" % (sys.argv[1]))
			sys.exit(1)
	if len(sys.argv) < 2:
		sys.stderr.write('Usage: %s [-l language] [-d date] [-o output_dir] article_list\n')
		sys.exit(1)

	if os.path.isfile(sys.argv[1]):
		topics = read_lines_from_file(sys.argv[1])
	else:
		topics = [sys.argv[1]]
	for i, topic in enumerate(topics):
		pos = topic.find(' ')
		if pos == -1:
			pos = topic.find('\t')
		if pos != -1:
			topics[i] = topic[:pos]
	fetch_articles_on_date(topics, date, lang, output_dir)
