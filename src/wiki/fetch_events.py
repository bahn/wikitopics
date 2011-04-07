#!/usr/bin/env python
"""
fetch_events.py

Retrieves all current events for a specific year.
The events are written into a file for each day of that year.

You should manually edit the year into something.
Currently, the year is set to 2009 so that all the current events of year 2009 are retrieved by default.
"""
import sys
import simplejson
import time
import datetime
import os
from exceptions import ValueError
import utils
import wikipydia

DRYRUN = False
OUTPUT_DIR = '.'

while len(sys.argv) > 1 and sys.argv[1].startswith('-'):
	if len(sys.argv) > 1 and sys.argv[1] == "--dry-run":
		DRYRUN = True
		del sys.argv[1]
	elif len(sys.argv) > 2 and sys.argv[1] == '-o':
		OUTPUT_DIR = sys.argv[2]
		sys.argv[1:3] = []
	else:
		sys.stderr.write('Unknown switch: ' + sys.argv[1] + '\n')
		sys.exit(1)

if len(sys.argv) != 3:
    sys.stderr.write("Usage: %s [--dry-run] [-o OUTPUT_DIR] START_DATE END_DATE\n" % sys.argv[0])
    sys.exit(1)

start_date = utils.convert_date(sys.argv[1])
end_date = utils.convert_date(sys.argv[2])
if start_date > end_date:
    sys.stderr.write("START_DATE is later than END_DATE\n")
    sys.exit(1)

if os.path.exists(OUTPUT_DIR):
    if not os.path.isdir(OUTPUT_DIR):
        sys.stderr.write(OUTPUT_DIR + " is not a directory.\n")
        sys.exit(1)
else:
    os.makedirs(OUTPUT_DIR)

date = start_date
while date <= end_date:
    events = wikipydia.query_current_events(date)
    if events:
        filename = date.isoformat() + ".events"
        if DRYRUN:
            print filename
            for event in events:
                print event["text"].encode('utf8').replace('*','\t')
        else:
            with open (os.path.join(OUTPUT_DIR, filename), 'w') as f:
                f.write(simplejson.dumps(events) + '\n')
    date += datetime.timedelta(days=1)
