#!/usr/bin/env python
"""
Extract named entities and their mentions in a Serif output file
"""

import sys
import serifxml
from operator import itemgetter
from collections import defaultdict
import pdb

if __name__ == '__main__':
	if len(sys.argv) != 3:
		print "extract_entities_xml.py TEXT SERIF_XML"
		sys.exit(1)
	doc = serifxml.Document(sys.argv[2])

	m2s = dict([(m, s) for s in doc.sentences for m in s.mention_set]) # mention to sentence
	for entity in doc.entity_set:
		names = [mention.syn_node.text for mention in entity.mentions if mention.mention_type == serifxml.MentionType.name]
		if names:
			namecount = defaultdict(int)
			for name in names:
				namecount[name] += 1
			entity_name = max(namecount, key = lambda x: namecount[x])
		else:
			names = [mention.syn_node.text for mention in entity.mentions]
			entity_name = names[0]

		print '#', entity_name, entity.entity_type, '#'

		for mention in entity.mentions:
			s = m2s[mention]
			mention_name = mention.syn_node.text
			mention_name = mention_name.replace('\n', ' ')
			line = doc.get_original_text_substring(s.start_char, s.end_char).encode('utf8')
# show the position of the mention in the line
			line = line.replace('\n', ' ')
			print '  -', mention.mention_type, mention.entity_subtype, mention_name, ':', line
