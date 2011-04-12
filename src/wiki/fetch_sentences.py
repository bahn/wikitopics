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
		if not wikipydia.query_exists(title, lang):
			continue
		title = wikipydia.query_redirects(title, lang)
		org_title = title
		revid = wikipydia.query_revid_by_date(title, lang, date, time="235959", direction="older")
		while not revid:
			# the page was moved later
			revid = wikipydia.query_revid_by_date(title, lang, date, time="235959", direction='newer')
			redirects = wikipydia.query_text_raw_by_revid(revid, lang)['text']
			if not redirects.lower().startswith('#redirect [[') or not redirects.endswith(']]'):
				sys.stderr.write(org_title.encode('utf8') + ' did not exist on ' + date.isoformat() + '\n')
				break
			title = redirects[12:-2]
			sys.stderr.write('falling back to ' + title.encode('utf8') + '...\n')
			revid = wikipydia.query_revid_by_date(title, lang, date, time="235959", direction="older")
		wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
		sentences, tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
		# substitute angle brackets with html-like character encodings
		sentences = [re.sub('<', '&lt;', re.sub('>', '&gt;', s)) for s in sentences]
		#sentences.insert(0, org_title)
		org_title = urllib.quote(org_title.replace(' ','_').encode('utf8'), safe="%") # force / to be quoted and % not to be quoted
		output_filename = os.path.join(output_dir, org_title + '.article')
		output = write_lines_to_file(output_filename, sentences)
		output_filename = os.path.join(output_dir, org_title + '.tags')
		output = write_lines_to_file(output_filename, tags)
		output_filename = os.path.join(output_dir, org_title + '.sentences')
		output = write_lines_to_file(output_filename, [sent for sent, tag in zip(sentences, tags) if tag == 'Sentence' or tag == 'LastSentence'])

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
		sys.stderr.write('Usage: ' + sys.argv[0] + ' [-l language] [-d date] [-o output_dir] article_list\n')
		sys.exit(1)

	if os.path.isfile(sys.argv[1]):
		topics = read_lines_from_file(sys.argv[1])
		topic_line_re = [re.compile(pattern) for pattern in ["^(.+) [0-9]+$", "^([^\t]+)\t[0-9]+$", "^[0-9]+ [0-9]+ (.+)$"]]
		for i, topic in enumerate(topics):
			for regex in topic_line_re:
				m = regex.match(topic)
				if m:
					topics[i] = m.group(1)
					break
	else:
		sys.stderr.write(sys.argv[1] + ' file not found. looking for Wikipedia page named ' + sys.argv[1] + '...\n')
		topics = [sys.argv[1]]
	fetch_articles_on_date(topics, date, lang, output_dir)
