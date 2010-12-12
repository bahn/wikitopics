#!/usr/bin/env python
#
# extract_entities.py
# -------------------
# Extracts the named entities and their mentions
# by looking at the corresponding APF file.
#
# extract_entities.py [sgm] [apf]

import serif
import sys


def check_apf(text, data):
    for entity in data.entityList:
		if entity.name:
			print '#', text.substr(entity.name.start, entity.name.end).encode('utf8')
		else:
			print '#', str(entity).encode('utf8')
		
		for mention in entity.mentions:
			substr = text.substr(mention.start, mention.end)
			print substr.encode('utf8')
#			line = text.expandstr(mention.start, mention.end)
#			print (substr + " in " + line).encode('utf-8')


if __name__ == '__main__':
    if len(sys.argv) != 3:
		print "Usage: extract_dates.py [sgm] [apf]"
		sys.exit(1)
    text = serif.read_sgm(sys.argv[1])
    data = serif.read_apf(text, sys.argv[2])
    check_apf(text, data)
