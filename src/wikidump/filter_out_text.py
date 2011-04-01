#!/usr/bin/env python
"""
filter_out_text.py

filter out text fields (those contents that were actually changed)
from the edit logs.

The file name of the edit logs is in the form of
enwiki-20100130-pages-meta-history.xml.gz
"""
import sys

flag = True
for s in sys.stdin.readlines():
	s = s[:-1]
	s2 = s.strip()
	if s2[0:5] == '<text':
		print s
		flag = False
	elif s2[-7:] == '</text>':
		print '</text>'
		flag = True
	elif flag:
		print s
