#!/usr/bin/env python
"""
Print the sentence with the most recent date with self reference
"""

import sys
import re
import bisect
from xml.dom.minidom import parse
import datetime
import serifxml
import serifutils
sys.path.append('../wiki')
import utils

if __name__=='__main__':
	if len(sys.argv) != 4:
		print "pick_self2.py DATE TEXT SERIF_XML"
		sys.exit(1)
	doc = serifxml.Document(sys.argv[3])
	date = utils.convert_date(sys.argv[1])

	vm2s = dict([(v, s) for s in doc.sentences for v in s.value_mention_set]) # value_mention to sentence
	vm2v = dict([(v.value_mention, v) for v in doc.value_set]) # value_mention to value
	m2s = dict([(m, s) for s in doc.sentences for m in s.mention_set]) # mention to sentence
	m2e = dict([(m, e) for e in doc.entity_set for m in e.mentions]) # mention to entity
	first_sentences = [s for s in doc.sentences if s.start_char == 0]
	first_entities = set([m2e[m] for s in first_sentences for m in s.mention_set if m in m2e])
	candidate_sentences = set([m2s[m] for e in first_entities for m in e.mentions])

	timex_values = set([v for v in doc.value_set if v.value_type == 'TIMEX2.TIME' and v.timex_val and vm2s[v.value_mention] in candidate_sentences])
	if not timex_values:
		timex_values = set([v for v in doc.value_set if v.value_type == 'TIMEX2.TIME' and v.timex_val]) # fallback

	best_timex = min(timex_values, key=lambda v: serifutils.delta_date_timex(date, v.timex_val))
	s2ln = dict([(s, i) for i, s in enumerate(doc.sentences)])
	s = vm2s[best_timex.value_mention]
	print s2ln[s], doc.get_original_text_substring(s.start_char, s.end_char)
