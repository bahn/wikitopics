#!/usr/bin/env python
import gzip
import sys

if len(sys.argv) < 2:
	sys.exit(1)
f = gzip.open(sys.argv[1],'r')

for line in f:
	if len(line) > 100:
		print line[0:100]
		print line[-100:-2]
		break
