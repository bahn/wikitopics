#!/usr/bin/env python
# see_info.py
# -----------
# Show basic info of a clustering.
# 
# Usage:
# 	./see_info.py clustering_file
# 
# Input:
# 	cluster files has the following format.
# 
# 	The title of an article is listed per line, and each cluster is divided by a blank line.
# 	The first article of each cluster may be the centroid article of the cluster.
# 	Comments followed by a hash (#) sign are allowed either at the beginning or end of a line.
# 
# 	An example cluster file follows:
# 	# Excitement about the upcoming superbowl.  Played on February 1, 2009.
# 	Super_Bowl_XLIII
# 	Super_Bowl
# 	Arizona_Cardinals
# 	Kurt_Warner
# 
# 	# The US airways flight that ditched into the Hudson, with no casualties 
# 	US_Airways_Flight_1549
# 	Chesley_Sullenberger
# 	Hudson_River
# 	Airbus_A320_family

import sys

if len(sys.argv) != 2:
    print "Usage: %s CLUSTERING" % sys.argv[0]
    print "Given:", ' '.join(sys.argv)
    sys.exit(1)

clustering = sys.argv[1]
cluster = {}

def read_clusters(filename, bag):
    f = open(filename, 'r')
    numClusters = 0
    numInstances = 0
    for line in f:
        if (line.find('#') != -1): # eliminates comments
            line = line[:line.find('#')].strip()
        tokens = line.split(None, 1)
        if len(tokens) == 0:
            if numInstances:
                numClusters += 1
                numInstances = 0
        else:
            topic = tokens[0].strip()
            if not topic in bag:
                bag[topic] = set()
            bag[topic].add(numClusters)
            numInstances += 1
    if numInstances:
        numClusters += 1
        numInstances = 0
    return numClusters
    
print "clustering:", clustering
print "# of clusters:", read_clusters(clustering, cluster)
