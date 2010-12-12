#!/usr/bin/env python
#
# check_wikitext.py
# -----------------
# OBSOLETE
# Retrieve a Wiki-markup text and check all kinds of tags that it provides.

import manage
import sys
import datetime
import wikipydia
import wpTextExtractor
from wt_articles.splitting import determine_splitter
import codecs
import re

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

#topics = read_lines_from_file('/Users/bahn/work/wikitopics/data/clustering/pick/pick0127')
date = datetime.date(2009, 10, 12)
lang = 'en'

sentences,tags = wpTextExtractor.wiki2sentences("<!-- See  -->\n<!-- PLEASE DO NOT CHANGE OBAMA'S NAME -->", determine_splitter(lang), True)
for s in sentences:
	print s
sys.exit(0)

#topics = ['Inauguration_of_Barack_Obama', 'Bill_Clinton', 'Black_Saturday_bushfires', 'Estradiol','Emma_Frost','Influenza','James','Brett_Favre']
topics = ['Barack_Obama']
shown = {}
shown2 = {}
shown3 = {}
for article in topics:
	revid = wikipydia.query_revid_by_date(article, lang, date)
	print revid
	wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
	sentences,tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
	wikimarkup = '\n'.join(sentences)
	print wikimarkup.encode('utf-8')

	while True:
		m = re.search(r'{{[^{}]*}}', wikimarkup)
		if not m:
			break
		ss = m.start() - 100
		if ss < 0:
			ss = 0
		ee = m.end() + 100
		if ee > len(wikimarkup):
			ee = len(wikimarkup)
		#print wikimarkup[ss:m.start()], m.group(), wikimarkup[m.end():ee]
		s = m.group()
		tag = s[2:-2].strip()
		if tag.find('|') != -1:
			tag = tag[:tag.find('|')].strip()
		#if tag == 'date':
			#print tag.encode('utf-8')
		if tag not in shown:
			print '{{'+tag.encode('utf-8')+'}}'
			#print tag.encode('utf-8'), s.encode('utf-8').split('\n')[0]
			shown[tag] = True
		#print s.encode('unicode-escape')
		#print s , '====='
		#print wikimarkup[ss:m.start()] , '-----' , wikimarkup[m.end():ee]
		wikimarkup = wikimarkup[:m.start()] + wikimarkup[m.end():]
	
	while True:
		m = re.search(r'{[^{}]*}', wikimarkup)
		if not m:
			break
		ss = m.start() - 100
		if ss < 0:
			ss = 0
		ee = m.end() + 100
		if ee > len(wikimarkup):
			ee = len(wikimarkup)
		#print wikimarkup[ss:m.start()], m.group(), wikimarkup[m.end():ee]
		s = m.group()
		tag = s[1:-1].strip()
		if tag.find('|') != -1:
			tag = tag[:tag.find('|')].strip()
		if tag not in shown2:
			print s.encode('utf-8')
			#print s.encode('unicode-escape')
			#print tag.encode('utf-8')
			#print tag.encode('utf-8'), s.encode('utf-8').split('\n')[0]
			shown2[tag] = True
		#print s , '====='
		#print wikimarkup[ss:m.start()] , '-----' , wikimarkup[m.end():ee]
		wikimarkup = wikimarkup[:m.start()] + wikimarkup[m.end():]

	while True:
		m = re.search('<!--.*?-->', wikimarkup)
		if not m:
			break
		ss = m.start() - 100
		if ss < 0:
			ss = 0
		ee = m.end() + 100
		if ee > len(wikimarkup):
			ee = len(wikimarkup)
		#print wikimarkup[ss:m.start()], m.group(), wikimarkup[m.end():ee]
		s = m.group()
		print s.encode('unicode-escape')
		#print s , '====='
		#print wikimarkup[ss:m.start()] , '-----' , wikimarkup[m.end():ee]
		wikimarkup = wikimarkup[:m.start()] + wikimarkup[m.end():]

	#print wikimarkup.encode('utf-8')
	
	while True:
		#m = re.search('<(\"[^\"]*?\"|\'[^\']*?\'|[^<>])*?>', wikimarkup)
		m = re.search(r'<[^<>]*?>', wikimarkup)
		if not m:
			break
		ss = m.start() - 100
		if ss < 0:
			ss = 0
		ee = m.end() + 100
		if ee > len(wikimarkup):
			ee = len(wikimarkup)
		#print wikimarkup[ss:m.start()], m.group(), wikimarkup[m.end():ee]
		s = m.group()
		tag = s[1:-1]
		if tag.find(' ') != -1:
			tag = tag[:tag.find(' ')]
		if tag not in shown3:
			#print tag.encode('utf-8')
			print tag.encode('utf-8'), s.encode('utf-8').split('\n')[0]
			shown3[tag] = True
		#print s.encode('unicode-escape')
		#print s , '====='
		#print wikimarkup[ss:m.start()] , '-----' , wikimarkup[m.end():ee]
		#print wikimarkup[ss:ee]
		wikimarkup = wikimarkup[:m.start()] + wikimarkup[m.end():]

	#print wikimarkup.encode('utf-8')

	while True:
		#m = re.search('<(\"[^\"]*?\"|\'[^\']*?\'|[^<>])*?>', wikimarkup)
		m = re.search(r'<', wikimarkup)
		if not m:
			break
		ss = m.start() - 100
		if ss < 0:
			ss = 0
		ee = m.end() + 100
		if ee > len(wikimarkup):
			ee = len(wikimarkup)
		#print wikimarkup[ss:m.start()], m.group(), wikimarkup[m.end():ee]
		s = m.group()
		#tag = s[1:-1]
		#if tag.find(' ') != -1:
			#tag = tag[:tag.find(' ')]
		#if tag not in shown3:
			#print tag.encode('utf-8')
			#print tag.encode('utf-8'), s.encode('utf-8').split('\n')[0]
			#shown3[tag] = True
		print 'angle bracket:', s.encode('unicode-escape')
		#print s , '====='
		#print wikimarkup[ss:m.start()] , '-----' , wikimarkup[m.end():ee]
		print wikimarkup[ss:ee].encode('utf-8')
		wikimarkup = wikimarkup[:m.start()] + wikimarkup[m.end():]

	#print wikimarkup.encode('utf-8')

	#sentences,tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
	#output_filename = '/Users/bahn/Desktop/wikitopics/' + date.isoformat() + '/' + article + '.sentences'
	#output = write_lines_to_file(output_filename, sentences)

# article = 'Inauguration_of_Barack_Obama'
# revid = wikipydia.query_revid_by_date(article, lang, date)
# wikimarkup = wikipydia.query_text_raw_by_revid(revid, lang)['text']
# sentences,tags = wpTextExtractor.wiki2sentences(wikimarkup, determine_splitter(lang), True)
# output_filename = '/Users/bahn/Desktop/wikitopics/' + date.isoformat() + '/' + article + '.sentences'
# output = write_lines_to_file(output_filename, sentences)
