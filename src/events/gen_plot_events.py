#!/usr/bin/env python
"""
gen_plot_events.py
------------------
Generate a plot for an event.

Usage:
	gen_plot_events.py bullet_date bullet_index date_from date_until dates links page_views
	e.g. ./gen_plot_events.py 20090120 5 12/1/2008 2/9/2009 data/events/events_date_2009 events_links_2009 events_page_views_by_date_2009

Input:
	bullet_date bullet_index
		The date and bullet index of the event to print.
		In the same format as the text and links file: e.g. 20090101 0.

	date_from
	date_until
		the date period for which print the plots.
		The format is the same as the dates in the dates file: e.g. 1/1/2009 12/31/2009.

	links
		the links from the Wikipedia current events. e.g. data/events/events_links_2009
		Each line contains the date and the index of the event (which is reset every day),
		and the title of an article linked from the event.
		e.g.)
20090101 0 BART_Police_shooting_of_Oscar_Grant
20090101 0 California
20090101 0 Bay_Area_Rapid_Transit
20090101 0 Fruitvale_%28BART_station%29
...

	page_views
		this files has the daily page views for all articles in the current events.
		e.g.)
		["14th_Dalai_Lama", [["12/1/2008", 2112], ..., ["12/31/2009", 1811]]]
"""
	
import sys
import json
import string
import os
import datetime
import time
import urllib
sys.path.append("/mnt/data/wikitopics/src")
import wiki.utils

class Bullet():
	def __init__(self, text, date):
		self.text = text
		self.date = date
		self.links = []
	def append_link(self, link):
		self.links.append(link)

# Return wiki-titled string.
# Wiki-titling is to make the first letter uppercase.
def wikititle(s):
	return s[0].upper() + s[1:]

warnings = []
def add_warning(str):
	global warnings
	warnings.append(str)

def convert_date(date):
	return time.strftime("%m/%d/%Y", time.strptime(date, "%Y%m%d"))

# read the text that describes each event.
# bullets['1/1/2009'][0] = Bullet(text, date)
def read_texts(texts_filename):
	bullets = {}
	texts_file = open(texts_filename, 'r')
	for line in texts_file:
		date, index, text = string.split(line, maxsplit=2)
		date = convert_date(date)
		if not date in bullets:
			bullets[date] = {}
		bullets[date][int(index)] = Bullet(text[:-1], date)  # remove the trailing end of line
	return bullets

# bullets['1/1/2009'][0].links = the list of the links from each event.
def read_links(links_filename, bullets):
	links_file = open(links_filename, 'r')
	for line in links_file:
		date, index, link = string.split(line, maxsplit=2)
		date = convert_date(date)
		bullets[date][int(index)].append_link(wikititle(link[:-1])) # remove the trailing end of line
	return bullets

# pageviews[page]
def read_pageviews(filename):
	pageviews = {}
	f = open(filename,'r')
	for i, line in enumerate(f):
		sys.stderr.write(str(i+1).rjust(4) + "\r")
		j = json.loads(line)
		page = wikititle(j[0])
		counts = j[1]
		pageviews[page] = counts
	return pageviews

# the start of the main
#
# read in the data
if len(sys.argv) < 8:
	sys.stderr.write("Usage: gen_plot_events.py bullet_date bullet_index date_from date_until text links page_views\n")
	sys.exit(1)
else:
	bullet_date = datetime.date(*time.strptime(sys.argv[1], "%Y%m%d")[0:3])
	bullet_index = int(sys.argv[2])
	date_from = datetime.date(*time.strptime(sys.argv[3], "%m/%d/%Y")[0:3])
	date_until = datetime.date(*time.strptime(sys.argv[4], "%m/%d/%Y")[0:3])

	bullets = read_texts(sys.argv[5])
	bullets = read_links(sys.argv[6], bullets)
	pageviews = read_pageviews(sys.argv[7])

bullet = bullets[bullet_date.strftime("%m/%d/%Y")][bullet_index]

plot_file = 'plot' + bullet_date.isoformat() + '-' + str(bullet_index) + '.gp'
f = open(plot_file, 'w')
f.write("set xdata time\n")
f.write('set timefmt "%Y-%m-%d"\n')
f.write('set format x "%b %d"\n')
f.write('set log y\n')
f.write('set xrange ["%s":"%s"]\n' % (date_from.isoformat(), date_until.isoformat()))
f.write('set yrange [1:1e+8]\n')
f.write('set arrow from "%s",1e+8 to "%s",1 nohead\n' % (bullet_date.isoformat(), bullet_date.isoformat()))
f.write('plot')

first_plot = True
for link in bullet.links:
	if link in pageviews:
		if first_plot:
			first_plot = False
		else:
			f.write(', \\\n\t')
		f.write(' "%s" using 1:2 with lines title "%s"' % (link+'.dat', urllib.unquote(link).replace('_',' ')))
f.write('\n')
f.close()

for link in bullet.links:
	if not link in pageviews:
		continue
	f = open(link+'.dat', 'w')
	for pageview in pageviews[link]:
		d = datetime.date(*time.strptime(pageview[0], "%m/%d/%Y")[0:3])
		if date_from <= d and d <= date_until:
			f.write(d.isoformat() + "\t" + str(pageview[1]) + "\n")
	f.close()

