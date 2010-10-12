#!/usr/bin/env python
#
# Converts date formats from 'YYYYMMDD' to 'MM/DD/YYYY'.
# Used to convert 

import simplejson
import sys

for line in sys.stdin:
    json = simplejson.loads(line)
    if len(json[1]) > 0:
	for i, tuple in enumerate(json[1]):
	    date = tuple[0]
	    newdate = str(int(date[4:6])) + "/" + str(int(date[6:8])) + "/" + date[0:4]
	    tuple[0] = newdate
	print simplejson.dumps(json)
