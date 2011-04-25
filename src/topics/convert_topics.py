#!/usr/bin/env python
import sys
import re
import datetime
import urllib
import os
import wikipydia

def convert_topics(filename, lang):
	date = None
	topics_re = re.compile(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})\.topics$')
	m = topics_re.match(os.path.basename(filename))
	if m:
		date = datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))

	lineno = 0
	try:
		f = open(filename, 'r')
		topic_line_re1 = re.compile("^(.+) ([0-9]+)$")
		topic_line_re2 = re.compile("^([^\t]+)\t([0-9]+)$")
		print "<table>";
		print "<tr><th>Rank</th><th>Titles and links</th><th>Trending score</th></tr>";
		for line in f:
			lineno += 1
			line = line.rstrip('\n')
			m = topic_line_re1.match(line)
			if m:
				title = m.group(1)
				pageviews = int(m.group(2))
			else:
				m = topic_line_re2.match(line)
				if m:
					title = m.group(1)
					pageviews = int(m.group(2))
				else:
					title = line
					pageviews = None
			title = title.decode('utf8')
			if not wikipydia.query_exists(title, lang):
				continue
			title = wikipydia.query_redirects(title, lang)
			title = title.encode('utf8')
			escaped_title = urllib.quote(title.replace(' ','_'), safe="%") # force / to be quoted and % not to be quoted
			print '<tr><td>%d</td><td><a href="http://%s.wikipedia.org/wiki/%s" target="view">%s</a>' % (lineno, lang, escaped_title, title),

			if date:
				thenid = str(wikipydia.query_revid_by_date_fallback(title, lang, date))
				priorid = str(wikipydia.query_revid_by_date_fallback(title, lang, date - datetime.timedelta(days=15)))
				print ' <a href="http://' + lang + '.wikipedia.org/w/index.php?oldid=' + thenid + '" target="viewthen">[then]</a>',
				if priorid == "0":
					print ' [prior]'
					print ' [diff]',
				else:
					print ' <a href="http://' + lang + '.wikipedia.org/w/index.php?oldid=' + priorid + '" target="viewprior">[prior]</a>',
					print ' <a href="http://' + lang + '.wikipedia.org/w/index.php?diff=' + thenid + '&oldid=' + priorid + '" target="viewdiff">[diff]</a>'
			if lang != 'en':
				print ' <a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fwiki%2F' + escaped_title + '" target="translate">[now:translate]</a>',
				if date:
					print ' <a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?oldid=' + thenid + '" target="translatethen">[then:translate]</a>',
					if priorid == "0":
						print ' [prior:translate]'
						print ' [diff:translate]'
					else:
						print ' <a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?oldid=' + priorid + '" target="translateprior">[prior:translate]</a>',
						print ' <a href="http://translate.google.com/translate?hl=en&sl=' + lang + '&tl=en&u=http%3A%2F%2F' + lang + '.wikipedia.org%2Fw%2Findex.php?diff=' + thenid + '&oldid=' + priorid + '" target="translatediff">[diff:translate]</a>',
			if pageviews:
				print "</td><td>%d" % (pageviews),
			print "</td></tr>";
		print "</table>";
	finally:
		if f:
			f.close()

if __name__=='__main__':
	lang = 'en'
	while len(sys.argv) > 1 and sys.argv[1].startswith('-'):
		if len(sys.argv) > 2 and sys.argv[1] == '-l':
			lang = sys.argv[2]
			sys.argv[1:3] = []
		else:
			sys.stderr.write('Unknown switch: %s\n' % sys.argv[1])
			sys.exit(1)
	if len(sys.argv) != 2:
		sys.stderr.write('Usage: %s [-l LANG] FILE\n' % sys.argv[0])
		sys.exit(1)
	filename = sys.argv[1]
	convert_topics(filename, lang)

