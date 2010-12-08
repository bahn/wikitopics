#!/usr/bin/env python
#
# fetch_sentences.py
#
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

import manage
import sys
import datetime
import wikipydia
import wpTextExtractor
from wt_articles.splitting import determine_splitter
import codecs
import re
import os

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
	"""                                                                                                                     \
	Writes a list of lines to file.                                                                                       \
	"""
	output_file = open(output_filename, 'w')
	for line in lines:
		output_file.write(line.encode('UTF-8'))
		output_file.write('\n'.encode('UTF-8'))
	output_file.close()
	return lines

def fetch_articles_on_date(topics, date, lang, dir):
	for article in topics:
		revid = wikipydia.query_revid_by_date(article, lang, date)
		wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
		sentences, tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
		# substitute angle brackets with html-like character encodings
		sentences = [re.sub('<', '&lt;', re.sub('>', '&gt;', s)) for s in sentences]
		output_filename = os.path.join(dir, article + '.sentences')
		output = write_lines_to_file(output_filename, sentences)

if __name__=='__main__':
	if len(sys.argv) < 4:
		print "Usage: fetch_sentences [path/to/file/containing/list/of/articles] [YYYY-MM-DD] [/path/to/store/sentences/files/]"
		#fetch_articles_on_date(['Barack_Obama'], datetime.date(2009, 1, 27), 'en', '.')
		sys.exit(1)
	topics = read_lines_from_file(sys.argv[1])
	m = re.match(r'(\d{4})-(\d{2})-(\d{2})', sys.argv[2])
	date = datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
	lang = 'en'
	try:
		os.makedirs(sys.argv[3])
	except OSError:
		pass
	fetch_articles_on_date(topics, date, lang, sys.argv[3])

