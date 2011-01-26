#!/usr/bin/env python
#
# mturk2csv.py
#
# Read the mechanical turk result in csv format
# and convert it to adjacency matrix
# where each element repressents links.

import sys
from cluster_mturk import read_mturk_clustering


if __name__=='__main__':
    if len(sys.argv) != 2:
	print "Usage: cluster_mturk.py /path/to/csv/file"
	sys.exit(1)
    clustering = read_mturk_clustering(sys.argv[1])
    clustering.printInCsv(sys.stdout)
