#!/usr/bin/env python
#
# retrieve_year_events.py
# -----------------------
# Retrieves all current events for a specific year.
# The events are written into a file for each day of that year.
#
# You should manually edit the year into something.
# Currently, the year is set to 2009 so that all the current events of year 2009 are retrieved by default.
import wikipydia
import sys
import simplejson
import time
import datetime
import os
from exceptions import ValueError

if len(sys.argv) != 3:
    print "Usage: %s start_date end_date" % sys.argv[0]
    sys.exit(-1)

def convert_date(date):
    formats = ["%Y%m%d", "%Y-%m-%d", "%m/%d/%Y"]
    for i, format in enumerate(formats):
        try:
            date = datetime.date(*time.strptime(date, format)[0:3])
            return date
        except:
            pass
    raise ValueError("time data '%s' does not match any of the time formats" % date)

start_date = convert_date(sys.argv[1])
end_date = convert_date(sys.argv[2])

try:
    os.makedirs('output')
except:
    pass

date = start_date
while True:
    events = wikipydia.query_current_events(date)
    if events:
        filename = 'current_events_for_' + date.strftime("%Y%m%d")
        with open ('output/' + filename, 'w') as file:
            file.write(simplejson.dumps(events) + '\n')
    if date == end_date:
        break
    date += datetime.timedelta(days=1)
