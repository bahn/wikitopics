#!/usr/bin/env python
#
# Retrieves all current events from the Wikipedia portal for a specific year.
# The events are written into a file for each day of that year.
#
# You should manually edit the year into something.
# Currently, the year is set to 2009 so that all the current events of year 2009 are retrieved by default.
import wikipydia
import sys
import simplejson

num_days = [31,28,31,30,31,30,31,31,30,31,30,31]
year = 2009
leap_year = False

if year % 4 == 0:
    if year % 100 == 0:
        if year % 400 == 0:
            leap_year = True
    else:
        leap_year = True
if leap_year:
    num_days[1] = 29

for month in range(1, 13):
    for day in range(1, num_days[month-1]+1):
        events = wikipydia.query_current_events(year, month, day)
        filename = 'current_events_for_%04d%02d%02d' % (year, month, day)
        print filename
        with open ('output/' + filename, 'w') as file:
            file.write(simplejson.dumps(events) + '\n')
