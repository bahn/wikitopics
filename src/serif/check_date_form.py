#!/usr/bin/env python
#
# check_date_form.py
#
# Extract date values from a APF file and check its variable formats.
# also needs the corresponding SGM file so it extracts the original string.
#
# extract_dates.py [sgm] [apf]



import sys
import re
import bisect
import serif
from xml.dom.minidom import parse



def check_date_form(data, text):
    # date possible followed by time. e.g. 2009-01-27T05:00:00, XXXX-08-27, XXXX-12-24TEV.
    re1 = re.compile("^(\d{4}|XXXX)-(\d{2})-(\d{2})(T(\d{2}:\d{2}:\d{2}|\d{2}:\d{2}|EV))?$")
    # month or season. e.g. 2009-01. 2008-SU.
    re2 = re.compile("^(\d{4}|XXXX)-(\d{2}|SP|SU|FA|WI)$")
    # year, century, or decades. e.g. 2009, 199, 16(i.e. the 17th century).
    re3 = re.compile("^(\d{2,4})$")
    # time. e.g. T01:00:00.
    re4 = re.compile("^(T(\d{2}:\d{2}:\d{2}|\d{2}:\d{2}|EV))?$")
    # relative date. e.g. P1Y, P3M, P22D
    re5 = re.compile("^(P)(\d+|X+)(Y|M|D|W)$")
    # relative time. e.g. PT3H
    re7 = re.compile("^(PT)(\d+|X+)(H)$")
    # general reference for present, past, or future. e.g. PRESENT_REF, PAST_REF, FUTURE_REF.
    re6 = re.compile("^(PRESENT_REF|PAST_REF|FUTURE_REF)$")
    year = ''
    month = ''
    day = ''
    for timex in data:
	value = timex.val
	if re1.match(value):
	    m = re1.match(value)
	    year = m.group(1)
	    month = m.group(2)
	    day = m.group(3)
	elif re2.match(value):
	    m = re2.match(value)
	    year = m.group(1)
	    month = m.group(2)
	elif re3.match(value):
	    m = re3.match(value)
	    year = m.group(1)
	elif re4.match(value):
	    pass
	elif re5.match(value):
	    pass
	elif re7.match(value):
	    pass
	elif re6.match(value):
	    pass
	else:
	    line, substr = text.substring(timex.start, timex.end)
	    print "value mismatch:", value.encode('utf-8'), substr.encode('utf-8'), line.encode('utf-8')
	    continue
	if year and year != "XXXX":
	    if int(year) < 1 or int(year) > 2199:
		print "illegal year:", value
	if month and month != "XX" and month != "SP" and month != "SU" and month != "FA" and month != "WI":
	    if int(month) < 1 or int(month) > 12:
		print "illegal month:", value
	if day and day != "XX":
	    if int(day) < 1 or int(day) > 31:
		print "illegal day:", value



if __name__=='__main__':
	if len(sys.argv) != 3:
		print "Usage: check_date_form.py [sgm] [apf]"
		sys.exit(1)
	text = serif.read_sgm(sys.argv[1])
	timexList = serif.read_apf(sys.argv[2])
	check_date_form(timexList, text)

