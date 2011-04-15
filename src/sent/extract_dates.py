#!/usr/bin/env python
#
# extract_dates.py
# ----------------
# Extracts the sentences that have temporal expressions
# by looking at the corresponding APF file.
#
# Usage: extract_dates.py [sgm] [apf]

import serif
import sys


def check_apf(text, data):
    for timex in data.timexList:
		substr = text.substr(timex.start, timex.end)
		start, end = text.expand(timex.start, timex.end)
		line = text.substr(start, end)
		out = line[:timex.start - start] + '[' + substr + ']' + line[timex.end - start + 1:]
		#print (u"VAL=%s STR=%s LINE=%s" % (timex.val, substr, line)).encode('utf-8')
		#print substr.encode('utf-8') + '\t"' + line.encode('utf-8') + '"'
		substr = substr.replace('\n', ' ')
		out = out.replace('\n', ' ')
		print ('  - %s "%s" : %s' % (str(timex), substr, out)).encode('utf8')


if __name__ == '__main__':
    if len(sys.argv) != 3:
		print "Usage: extract_dates.py [sgm] [apf]"
		sys.exit(1)
    text = serif.read_sgm(sys.argv[1])
    data = serif.read_apf(text, sys.argv[2])
    check_apf(text, data)
