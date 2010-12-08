#!/usr/bin/env python
#
# pickup.py
#
# Get ten examples of unmatched articles (two-way).
#
# Usage:
#		 pickup.py events_file trends_file window_size'
#		 e.g. src/events/pickup.py data/events/events_links_2009 data/topics/topics_2009 3
# 
# Input:
#		 events_link
#				 the links from the Wikipedia current events. e.g. data/events/events_links_2009
#				 Each line contains the date and the index of the event (which is reset every day),
#				 and the title of an article linked from the event.
#				 e.g.
# 20090101 0 BART_Police_shooting_of_Oscar_Grant
# 20090101 0 California
# 20090101 0 Bay_Area_Rapid_Transit
# 20090101 0 Fruitvale_%28BART_station%29
# ...
# 
#		 trends
#				 the file that has the list of the automatically selected Wikipedia articles.
#				 e.g. data/topics/topics_2009
#				 The name of each file of the daily page views are written in a line
#				 followed by the selected articles, one in a line.
#				 The format:
# pagecounts-20090101.gz		13226
# Boxing_Day		477075
# Eartha_Kitt		370776
# Hanukkah		350016
# Gaza_Strip		347104
# ...
# 
#		 window_size
#				 the window size with which the selected articles are evaluated
#				 against the articles linked from the Wikipedia current events.
# 
# Output:
#		 the standard output.

import sys
import random

if len(sys.argv) < 3:
	print 'usage: pickup.py events_file trends_file window_size'
	sys.exit(0)

events_filename = sys.argv[1]
trends_filename = sys.argv[2]

total_bullets = 0
total_gold = 0

bullets = {}
events = {}
events_file = open(events_filename)
for line in events_file:
	column = line.split()
	title = column[2]
	bullet = column[1]
	date = column[0]
	if not date in events:
		events[date] = []
		bullets[date] = {}
	events[date].append(title)
	if not bullet in bullets[date]:
		bullets[date][bullet] = []
		total_bullets += 1
	bullets[date][bullet].append(title) 
	total_gold += 1

dates = []

total_topics = 0
trends = {}
trends_file = open(trends_filename)
date = ''
for line in trends_file:
	column = line.split()
	title = column[0]
	if title.startswith('pagecounts'):
		date = title.split('-')[1].split('.')[0]
		dates.append(date)
		if not date in events:
			events[date] = []
		if not date in bullets:
			bullets[date] = []
		if not date in trends:
			trends[date] = [] 
	elif date:
		trends[date].append(title)
		total_topics += 1
		
date = '20091015'
dates.append(date)
events[date] = []
bullets[date] = []
trends[date] = []
dates.sort()

slack = 0
if len(sys.argv) == 4:
	slack = int(sys.argv[3])

true_positives = 0
beforehands = 0
exactday = 0
afterwards = 0

false_positives = []
false_negatives = []

for i, date in enumerate(dates):
	for trend in trends[date]:
		for j in range(-slack, slack+1):
			k = i + j
			if k >= 0 and k < len(dates):
				lookup_date = dates[k]
				if trend in events[lookup_date]:
					true_positives += 1
					break
		else:
			#if date == '20090127' or date == '20090210' or date == '20090419' or date == '20090512' or date == '20091012':
			false_positives.append(date + ' ' + trend)
		for j in range(-slack, 0):
			k = i + j
			if k >= 0 and k < len(dates):
				lookup_date = dates[k]
				if trend in events[lookup_date]:
					beforehands += 1
					break
		if trend in events[date]:
			exactday += 1
		for j in range(1, slack+1):
			k = i + j
			if k >= 0 and k < len(dates):
				lookup_date = dates[k]
				if trend in events[lookup_date]:
					afterwards += 1
					break

checked_bullets = 0
for i, date in enumerate(dates):
	for bullet in bullets[date]:
		found = False
		for title in bullets[date][bullet]:
			for j in range(-slack, slack+1):
				k = i + j
				if k >= 0 and k < len(dates):
					lookup_date = dates[k]
					if title in trends[lookup_date]:
						checked_bullets += 1
						found = True
						break
			if found:
				break

for i, date in enumerate(dates):
	for bullet in bullets[date]:
		for title in bullets[date][bullet]:
			for j in range(-slack, slack+1):
				k = i + j
				if k >= 0 and k < len(dates):
					lookup_date = dates[k]
					if title in trends[lookup_date]:
						break
			else:
				#if date == '20090127' or date == '20090210' or date == '20090419' or date == '20090512' or date == '20091012':
				false_negatives.append(date + ' ' + title)

print "true_positives:", true_positives
print "total_gold:", total_gold
print "total_topics:", total_topics
print
print "beforehands:", beforehands
print "exactday:", exactday
print "afterwards:", afterwards
print
print "checked_bullets:", checked_bullets
print "total_bullets:", total_bullets
print
random.shuffle(false_positives)
print "false_positives:", len(false_positives)
for i, title in enumerate(false_positives):
	print i, title
	if i > 10:
		break
print
random.shuffle(false_negatives)
print "false_negatives:", len(false_negatives)
for i, title in enumerate(false_negatives):
	print i, title
	if i > 10:
		break

