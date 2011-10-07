#!/usr/bin/env python

import os
import os.path
import sys
from datetime import date
from datetime import timedelta
from bisect import bisect_left
import urllib

def check_first(first, datestr):
	if first:
		print
		print datestr
		return False
	return False
wikitopics = os.environ['WIKITOPICS']

if not wikitopics:
	sys.stderr.write('The environment variable WIKITOPICS is not defined.\n')
	sys.exit(1)

firstday = date(2011, 9, 14)
today = date.today()

lang = 'en'
day = firstday
while day <= today:
	datestr = day.isoformat()

	articles_list_filename = os.path.join(wikitopics, 'data', 'articles', lang, str(day.year), datestr, datestr + ".articles.list")
	articles = []
	if os.path.isfile(articles_list_filename):
		for line in open(articles_list_filename, 'r'):
			fields = line.strip().split()
			article = urllib.quote(fields[0], safe="%")
			if article.startswith('.'):
				article = "%2E" + article[1:]
			articles.append(article)
		articles.sort()

	files = []
	files.append(os.path.join(wikitopics, 'data', 'topics', lang, str(day.year), datestr + ".articles.list"))
	files.append(os.path.join(wikitopics, 'data', 'topics', lang, str(day.year), datestr + ".topics"))
	files.append(os.path.join(wikitopics, 'data', 'articles', lang, str(day.year), datestr, datestr + ".articles.list"))
	files.append(os.path.join(wikitopics, 'data', 'clusters', 'kmeans', lang, str(day.year), datestr + ".clusters"))
	files.append(os.path.join(wikitopics, 'data', 'html', lang, str(day.year), datestr + ".clusters.html"))

	first = True
	for filename in files:
		if not os.path.isfile(filename):
			first = check_first(first, datestr)
			print filename, 'not found'
	if articles:
		article_dir = os.path.join(wikitopics, 'data', 'articles', lang, str(day.year), datestr)
		list_dir = os.listdir(article_dir)
		if not list_dir: 
			first = check_first(first, datestr)
			print article_dir, 'empty'
		elif 2 * len(articles) + 1 != len(list_dir):
			first = check_first(first, datestr)
			list_dir.sort()
			print article_dir, 'lacks', (2 * len(articles) + 1 - len(list_dir)), 'files'
			no_not_found = 0
			for article in articles:
				filename = article + '.sentences'
				i = bisect_left(list_dir, filename)
				if i >= len(list_dir) or list_dir[i] != filename:
					print filename, 'not found'
					no_not_found += 1
				filename = article + '.tags'
				i = bisect_left(list_dir, filename)
				if i >= len(list_dir) or list_dir[i] != filename:
					print filename, 'not found'
					no_not_found += 1
				if no_not_found >= 10:
					print '...'
					break
			extra_found = 0
			for filename in list_dir:
				if filename == datestr + '.articles.list':
					continue
				if filename.endswith('.sentences'):
					article = filename[:-10]
				elif filename.endswith('.tags'):
					article = filename[:-5]
				else:
					article = filename
				i = bisect_left(articles, article)
				if i >= len(articles) or articles[i] != article:
					print filename, 'found does not match'
		else:
			serif_dir = os.path.join(wikitopics, 'data', 'serif', lang, str(day.year), datestr, 'output')
			list_dir = os.listdir(serif_dir)
			if not list_dir:
				first = check_first(first, datestr)
				print serif_dir, 'empty'
			elif len(articles) != len(list_dir):
				first = check_first(first, datestr)
				list_dir.sort()
				print serif_dir, 'lacks', (len(articles) - len(list_dir)), 'files'
				no_not_found = 0
				for article in articles:
					filename = article + '.xml.xml'
					i = bisect_left(list_dir, filename)
					if i >= len(list_dir) or list_dir[i] != filename:
						print filename, 'not found'
						no_not_found += 1
					if no_not_found >= 5:
						print '...'
						break
			else:
				files = []
				files.append(os.path.join(wikitopics, 'data', 'sentences', 'first', lang, str(day.year), datestr, article + ".sentences"))
				files.append(os.path.join(wikitopics, 'data', 'sentences', 'recent', lang, str(day.year), datestr, article + ".sentences"))
				files.append(os.path.join(wikitopics, 'data', 'sentences', 'self', lang, str(day.year), datestr, article + ".sentences"))
				for filename in files:
					if not os.path.isfile(filename):
						first = check_first(first, datestr)
						print filename, 'not found'
	
	day += timedelta(days = 1)
