#!/usr/bin/env python
#
# pick_recent_date.py
#
# Extract date values from a APF file and check its variable formats.
# also needs the corresponding SGM file so it extracts the original string.
#
# pick_recent_date.py [date] [sgm] [apf]

import sys
import re
import bisect
from xml.dom.minidom import parse
import serif
import datetime



def convert_to_date(str):
	pattern = re.compile(r"(\d{4})-(\d{2})-(\d{2})")
	if not pattern.match(str):
		print "invalid format; need iso format:", str
		sys.exit(1)
	else:
		m = pattern.match(str)
		year = m.group(1)
		month = m.group(2)
		day = m.group(3)
		date = datetime.date(int(year), int(month), int(day))
		return date


if __name__=='__main__':
	if len(sys.argv) != 4:
		print "Usage: pick_recent_date.py [date] [sgm] [apf]"
		sys.exit(1)
	date = convert_to_date(sys.argv[1])
	text = serif.read_sgm(sys.argv[2])
	data = serif.read_apf(sys.argv[3])
	btimex = serif.find_best_timex(date, text, data)
	if btimex:
		start, end = text.expand(btimex.start, btimex.end)
		line = serif.resolveCoref(text, data, start, end)
		print line.encode('utf-8')

