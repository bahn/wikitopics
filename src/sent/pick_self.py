#!/usr/bin/env python
#
# pick_self.py
# ------------
# 	Pick the best sentence with the self reference in the given file.
#	If there is no such sentence, it just picks the sentence with the most recent date.
# 	Called by batch_pick_self.sh.
# 
# 	Usage: pick_self.py date sgm apf
# 
# 	date
# 		the date
# 
# 	sgm
# 		the sgm file
# 	
# 	apf
# 		the apf file
# 
# Output: Written into the standard output.
# 	The line number of the selected sentence and the sentence separated by a space.

import sys
import re
import bisect
from xml.dom.minidom import parse
import serif
import datetime

if __name__=='__main__':
	if len(sys.argv) != 4:
		print "Usage: pick_self.py date text apf"
		sys.exit(1)
	date = serif.convert_to_date(sys.argv[1])
	text = serif.read_sgm(sys.argv[2])
	data = serif.read_apf(text, sys.argv[3])
	btimex = serif.pick_self(date, text, data)
	if not btimex:
		btimex = serif.find_best_timex(date, text, data)
	if btimex:
		start, end = text.expand(btimex.start, btimex.end)
		line = serif.resolveCoref(text, data, start, end)
		print text.find(start), line.encode('utf-8')

