#!/usr/bin/env python
#
# mturk2mallet.py
#
# Read the mechanical turk result in csv format
# print it in mallet compatible format

import sys
from cluster_mturk import read_mturk_clustering


if __name__=='__main__':
    if len(sys.argv) != 2:
	print "Usage: cluster_mturk.py /path/to/csv/file"
	sys.exit(1)
    clustering = read_mturk_clustering(sys.argv[1])
    clustering.printInMallet(sys.stdout)
