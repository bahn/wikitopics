#!/usr/bin/env python

import urllib
import sys
import os
import codecs
import re
import wikipydia
import datetime

def read_topics(topic_file, topics):
	#print "read_topics: " + topic_file
	f = codecs.open(topic_file, "rt", "utf-8")
	for line in f:
		fields = line.split()
		title = fields[0]
		score = int(fields[1])
		if len(fields) >= 3:
			thenid = fields[2]
		else:
			thenid = str(wikipydia.query_revid_by_date_fallback(page, lang, date))
		if len(fields) >= 4:
			priorid = fields[3]
		else:
			priorid = str(wikipydia.query_revid_by_date_fallback(page, lang, date - datetime.timedelta(days=15)))

		topics[title] = {'score': score, 'thenid': thenid, 'priorid': priorid}
	
def print_cluster(cluster, sentence_dirs, topics, lang):
	if not cluster:
		return
	
	cluster_title = ", ".join([t.replace('_',' ') for t in cluster])
	sum_scores = sum([topics[t]['score'] for t in cluster])

	print '<h3><a href="#">' + cluster_title.encode('utf-8') + '<span class="score">' + str(sum_scores) + '</span></a></h3>'
	print '<div>'
	print '\t<table>'
	print '\t\t<tr><th>Article</th>'
	for folder in sentence_dirs:
		s = re.search(r'\/sentences\/([^\/]+)\/', folder)
		scheme = s.group(1)
		print '\t\t\t<th>' + scheme[0].upper() + scheme[1:] + '</th>'
	print '\t\t</tr>'
	for page in cluster:
		utf_title = page.replace('_',' ').encode('utf8')

		encoded = urllib.quote(page.encode('utf8'), safe='%')
		if encoded[0] == '.':
			encoded = '%2E' + encoded[1:]

		score = topics[page]['score']
		thenid = topics[page]['thenid']
		priorid = topics[page]['priorid']

		print '\t\t<tr><td><a href="http://' + lang + '.wikipedia.org/wiki/' + encoded + '" target="view">' + utf_title + '<span class="score">' + str(score) + '</span></a>'
		print '\t\t\t<ul class="subnav">'
		print '\t\t\t\t<li><a href="http://' + lang + '.wikipedia.org/wiki/' + encoded + '" target="view">View Now</a></li>'
		if thenid:
			print '\t\t\t\t<li><a href="http://' + lang + '.wikipedia.org/w/index.php?oldid=' + thenid + '" target="viewthen">View Then</a></li>'
		else:
			print '\t\t\t\t<li>View Then</a></li>'
		if priorid: # assuming if priorid exists then thenid also exists
			print '\t\t\t\t<li><a href="http://' + lang + '.wikipedia.org/w/index.php?oldid=' + priorid + '" target="viewprior">View Prior</a></li>'
			print '\t\t\t\t<li><a href="http://' + lang + '.wikipedia.org/w/index.php?diff=' + thenid + '&oldid=' + priorid + '" target="viewdiff">View Diff</a></li>'
		else:
			print '\t\t\t\t<li>View Prior</li>'
			print '\t\t\t\t<li>View Diff</li>'
		if lang != 'en':
			print '\t\t\t<a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fwiki%2F' + encoded + '" target= "translate">Translate Now</a></li>'
			if thenid:
				print '\t\t\t\t<li><a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?oldid=' + thenid + '" target="translatethen">Translate Then</a></li>'
			else:
				print '\t\t\t\t<li>Translate Then</a></li>'
			if priorid: # assuming if priorid exists then thenid also exists
				print '\t\t\t\t<li><a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?oldid=' + priorid + '" target="translateprior">Translate Prior</a></li>'
				print '\t\t\t\t<li><a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?diff=' + thenid + '&oldid=' + priorid + '" target="translatediff">Translate Diff</a></li>'
			else:
				print '\t\t\t\t<li>Translate Prior</li>'
				print '\t\t\t\t<li>Translate Diff</li>'
		print '\t\t\t</ul>'
		print '\t\t\t<span class="more">more<span/></td>'

		for folder in sentence_dirs:
			s = re.search(r'\/sentences\/([^\/]+)\/', folder)
			scheme = s.group(1)
			print '\t\t\t<td class="sent"><!--' + scheme[0].upper() + scheme[1:] + '-->'
			filepath = os.path.join(folder, encoded + '.sentences')
			if os.path.isfile(filepath): # if the file exists
				f = codecs.open(filepath, 'rt', 'utf-8')
				for line in f:
					if line.find(' ') != -1:
						line = line[line.find(' ') + 1:].strip()
					print '\t\t\t\t' + line.encode('utf8') + '<br>'
				f.close()
			print '\t\t\t</td>'
		print '\t\t</tr>'
	print '\t</table>'
	print '</div>'

if __name__=='__main__':
# read trending score from the topics file
	topics = {}

	lang = 'en' # default language
	while (sys.argv[1] == '-t' or sys.argv[1] == '-l') and len(sys.argv) > 2:
		if sys.argv[1] == '-t':
			read_topics(sys.argv[2], topics)
		elif sys.argv[1] == '-l':
			lang = sys.argv[2]
		sys.argv[1:3] = []

	if len(sys.argv) < 2:
		sys.stderr.write("convert_cluster.py [-t topics_file] cluster_file [sentence_dir1 [sentence_dir2] ...]\n")
		sys.exit(1)

	cluster_file = sys.argv[1]
	sentence_dirs = []

	for folder in sys.argv[2:]:
		if not os.path.isdir(folder):
			sys.stderr.write(folder + " not found\n")
		else:
			sentence_dirs.append(folder)

	clusters = []
	cluster = []
	f = codecs.open(cluster_file, "rt", "utf-8")
	for line in f:
		if line.find('#') != -1:
			line = line[:line.find('#')]
		line = line.strip()
		if not line: # if a blank line
			if cluster:
				clusters.append(cluster)
				cluster = []
		else:
			cluster.append(line)
	if cluster:
		clusters.append(cluster)
	f.close()

	clusters.sort(key=lambda c: sum([topics[t]['score'] for t in c]), reverse=True)

	for cluster in clusters:
		cluster.sort(key=lambda t: topics[t]['score'], reverse=True)
		print_cluster(cluster, sentence_dirs, topics, lang)
