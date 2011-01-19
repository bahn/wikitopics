#!/usr/bin/env python
#
# non_parsable.py
# print the name of the file if it is not parsable with Python's xml.dom.minidom module.

from xml.dom.minidom import parse
import sys

file = open(sys.argv[1])
try:
	dom = parse(file)
except:
	print sys.argv[1]
