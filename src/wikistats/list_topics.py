#!/usr/bin/env python

"""
list_topics.py

Using Trending Topics algorithm,
print the topics for each day.
"""

import sys
import datetime
import os
import gzip
import urllib
from collections import deque
from operator import itemgetter
sys.path.append("/mnt/data/wikitopics/src")
import wiki.utils
sys.path.append("/home/bahn/work/wikipydia")
import wikipydia

def read_wikistats(lang, filename):
	pagecounts = {}
	if not filename:
		return pagecounts
	if filename.endswith('.gz'):
		f = gzip.open(filename)
	else:
		f = open(filename)
	try:
		for line in f:
			try:
				fields = line.strip().split()
				if lang == fields[0]:
					page = fields[1]
					if wiki.utils.is_valid_title(page):
						title = wiki.utils.normalize_title(page)
						if int(fields[2]) > CUT_OFF:
							pagecounts[title] = int(fields[2])
			except (UnicodeError, IndexError):
				sys.stderr.write(str(sys.exc_info()) + "\n")
	except IOError:
		sys.stderr.write(str(sys.exc_info()) + "\n")
	return pagecounts
	
def add_sum(sum_stats, stats):
	for title, count in stats.items():
		sum_stats[title] = sum_stats.get(title, 0) + count

def subtract_sum(sum_stats, stats):
	for title, count in stats.items():
		sum_stats[title] -= count
		#assert sum_stats[title] >= 0
		if sum_stats[title] <= 0:
			del sum_stats[title]

checked = {}
exists = {}
redirects = {}
def get_topics(old_sum, new_sum, limit, lang):
	global checked
	global exists
	stat = {}
	for title, count in new_sum.items():
		diff = count - old_sum.get(title, 0)
		if diff > 0:
			stat[urllib.unquote(title)] = diff
	result = sorted(stat.items(), key=itemgetter(1), reverse=True)
	i = 0
	while i < len(result) and i < limit:
		title = result[i][0]
		pageviews = result[i][1]
		if title not in checked:
			checked[title] = True
			if wikipydia.query_exists(title.decode('utf8'), lang):
				exists[title] = True
				redirects[title] = wikipydia.query_redirects(title.decode('utf8'), lang).encode('utf8')
		if title not in exists:
			del result[i]
		else:
			result[i] = (redirects[title], pageviews)
			i += 1
	if len(result) > limit:
		result[limit:] = []
	return result

def list_topics(lang, window_size, src_dir, trg_dir, start_date, end_date):
	start_date -= datetime.timedelta(days = window_size * 2 - 1)
	date = start_date
	filepath = ''
	filelist = []

	new_period = deque([])
	old_period = deque([])
	new_sum = {}
	old_sum = {}

	while date <= end_date:
		# get prefix for source and target directories
		src_prefix = src_dir
		if os.path.isdir(os.path.join(src_dir, str(date.year))):
			src_prefix = os.path.join(src_dir, str(date.year))
		trg_prefix = trg_dir
		if os.path.basename(trg_dir) != str(date.year):
			trg_prefix = os.path.join(trg_dir, str(date.year))
		if not os.path.exists(trg_prefix):
			os.makedirs(trg_prefix)
		
		# get file list
		if filepath != src_prefix:
			filepath = src_prefix
			if os.path.isdir(filepath):
				filelist = os.listdir(filepath)
			else:
				sys.stderr.write(filepath + " not found\n")
				filelist = ''

		filenames = [name for name in filelist if name.startswith('page') and name.find(date.strftime("%Y%m%d")) != -1]
		if filenames:
			sys.stderr.write(filenames[0] + "\n")
			new_stats = read_wikistats(lang, os.path.join(filepath, filenames[0]))
			new_period.append(new_stats)
			add_sum(new_sum, new_stats)
			if len(new_period) > window_size:
				stats = new_period.popleft()
				subtract_sum(new_sum, stats)
				old_period.append(stats)
				add_sum(old_sum, stats)
				if len(old_period) > window_size:
					stats = old_period.popleft()
					subtract_sum(old_sum, stats)
			if len(old_period) == window_size and len(new_period) == window_size:
				topics = get_topics(old_sum, new_sum, LIST_SIZE, lang)
				out = open(os.path.join(trg_prefix, date.isoformat() + ".topics"), "w")
				for title, count in topics:
					out.write("%s %d\n" % (title, count))
				out.close()

		# increase the date
		date += datetime.timedelta(days = 1)

if __name__ == '__main__':
	WINDOW_SIZE = 15
	LIST_SIZE = 1000
	CUT_OFF = 0
	while len(sys.argv) > 1 and sys.argv[1].startswith("-"):
		if len(sys.argv) > 2 and sys.argv[1] == '-w':
			WINDOW_SIZE = int(sys.argv[2])
			sys.argv[1:3] = []
		elif len(sys.argv) > 2 and sys.argv[1] == '-l':
			LIST_SIZE = int(sys.argv[2])
			sys.argv[1:3] = []
		elif len(sys.argv) > 2 and sys.argv[1] == '-c':
			CUT_OFF = int(sys.argv[2])
			sys.argv[1:3] = []
		else:
			sys.stderr.write("Unknown switch: %s\n", sys.argv[1])
			sys.exit(1)
	if len(sys.argv) != 6:
		print "Usage: %s [-w WINDOW_SIZE] [-l LIST_SIZE] [-c CUT_OFF] LANG SRC_DIR TRG_DIR DATE_FROM DATE_UNTIL" % (sys.argv[0])
		sys.exit(1)

	LANG = sys.argv[1]
	SRC_DIR = sys.argv[2]
	TRG_DIR = sys.argv[3]
	DATE_FROM = wiki.utils.convert_date(sys.argv[4])
	DATE_UNTIL = wiki.utils.convert_date(sys.argv[5])
	list_topics(LANG, WINDOW_SIZE, SRC_DIR, TRG_DIR, DATE_FROM, DATE_UNTIL)
