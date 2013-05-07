#!/usr/bin/env python

import sys
import datetime
import time
import json

if len(sys.argv) != 3:
    print "Usage: get_pop_scores.py article_list pageviews"
    sys.exit(-1)

pageviews = {}
for i, line in enumerate(open(sys.argv[2], "r")):
    line = line.strip()
    pageview = json.loads(line)
    sys.stderr.write("\r%d" % i)
    sys.stderr.flush()
    if pageview[1]:
        pageviews[pageview[0]] = dict([ (datetime.date(*time.strptime(date, "%m/%d/%Y")[0:3]), view) for date, view in pageview[1] ])
sys.stderr.write("\n")

for line in open(sys.argv[1], "r"):
    line = line.strip()
    field = line.split()
    date = datetime.date(*time.strptime(field[0], "%Y%m%d")[0:3])
    title = unicode(field[2], "utf8")
    pv = pageviews.get(title, {})
    prev_sum = 0
    for offset in range(15, 30):
        d = date - datetime.timedelta(days=offset)
        prev_sum += pv.get(d, 0)
    cur_sum = 0
    for offset in range(0, 15):
        d = date - datetime.timedelta(days=offset)
        cur_sum += pv.get(d, 0)
    print title.encode('utf8'), date, cur_sum - prev_sum, prev_sum, cur_sum
