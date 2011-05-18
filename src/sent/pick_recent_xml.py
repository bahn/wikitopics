#!/usr/bin/env python
"""
Print the sentence with the most recent date
"""

import sys
import re
import bisect
from xml.dom.minidom import parse
import datetime
import serifxml
import serifutils
sys.path.append('/home/hltcoe/bahn/wikitopics/src/wiki')
import utils

if __name__=='__main__':
	if len(sys.argv) != 4:
		print "pick_recent_xml.py DATE TEXT SERIF_XML"
		sys.exit(1)
	doc = serifxml.Document(sys.argv[3])
	date = utils.convert_date(sys.argv[1])

	s2ln = dict([(s, i) for i, s in enumerate(doc.sentences)])
	vm2s = dict([(v, s) for s in doc.sentences for v in s.value_mention_set]) # value_mention to sentence
	timex_values = [v for v in doc.value_set if v.value_type == 'TIMEX2.TIME' and v.timex_val]

	if timex_values:
		best_timex = min(timex_values, key=lambda v: serifutils.delta_date_timex(date, v.timex_val))
		s = vm2s[best_timex.value_mention]
		print s2ln[s], doc.get_original_text_substring(s.start_char, s.end_char).encode('utf8')
