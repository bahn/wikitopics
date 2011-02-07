#!/usr/bin/env python

import os
import fnmatch


script_name = './aggregate_pagecounts.py'

monthset = set([])
for dirpath,dirnames,filenames in os.walk('.'):
    dateset = set([])
    if len(filenames)>0:
	for filename in filenames:
	    if fnmatch.fnmatch(filename, 'pagecounts-*-*.gz'):
		dateset.add(filename[11:19])
		monthset.add(filename[11:17])
	for date in sorted(dateset):
	    print script_name, os.path.join(dirpath, 'pagecounts-' + date + '-*.gz'), '| gzip -c - > daily/pagecounts-' + date + '.gz'
for month in sorted(monthset):
    print script_name, 'daily/pagecounts-' + month + '*.gz | gzip -c - > monthly/pagecounts-' + month + '.gz'
