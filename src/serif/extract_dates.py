#!/usr/bin/env python
#
# extract_dates.py
#
# Extracts the sentences that have temporal expressions
# by looking at the corresponding APF file.
#
# extract_dates.py [sgm] [apf]


import serif
import sys


def check_apf(text, timexList):
    for timex in timexList:
		line, substr = text.substring(timex.start, timex.end)
		#print (u"VAL=%s STR=%s LINE=%s" % (timex.val, substr, line)).encode('utf-8')
		print substr.encode('utf-8') + '\t' + line.encode('utf-8')


if __name__ == '__main__':
    if len(sys.argv) != 3:
		print "Usage: extract_dates.py [sgm] [apf]"
		sys.exit(1)
    text = serif.read_sgm(sys.argv[1])
    timexList = serif.read_apf(sys.argv[2])
    check_apf(text, timexList)
