#!/usr/bin/env python
#
#
# cluster_using_links.py
# ======================
# 
# Cluster articles using the link structure.
#

import sys
links = {}
f = open(sys.argv[1], 'r')
for l in f:
	fields = l.split(":")
	links[int(fields[0])] = fields[1]
	print fields[0], fields[1],
