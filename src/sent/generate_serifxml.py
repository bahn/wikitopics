#!/usr/bin/env python
"""
Generate a Serif-style xml file from a raw input text
"""

import os
import sys

def write_serifxml(filename):
	try:
		sentences = []
		f = open(filename, 'r')
		offset = 0
		for line in f:
			length = len(line.decode('utf8'))
			sentences.append((offset, offset + length-2))
			offset += length
		print '<?xml version="1.0" encoding="UTF-8" ?>'
		print '<SerifXML version="1">'
		print '<Document docid="doc-0" language="English">'
		print '<OriginalText href="file://' + os.path.abspath(filename) + '"/>'
		print '<Regions>'
		print '  <Region char_offsets="0:' + str(offset - 1) + '" tag="TEXT" id="the-only-region"/>'
		print '</Regions>'
		print '<Sentences>'
		for sentence in sentences:
			print '  <Sentence char_offsets="%d:%d" region_id="the-only-region"/>' % sentence
		print '</Sentences>'
		print '</Document>'
		print '</SerifXML>'
	finally:
		if f:
			f.close()
	

if __name__=="__main__":
	if len(sys.argv) != 2:
		sys.stderr.write("generate_serifxml.py raw_text.file\n");
		sys.exit(1)
	
	write_serifxml(sys.argv[1])
