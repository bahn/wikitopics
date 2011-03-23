#!/usr/bin/env python
# eval.py
# -------
# the clustering evaluation script that use multiplicity B-cubed for overlapping clusters.
# 
# Usage:
# 	./eval.py gold_standard test_set
# 		gold_standard and test_set are both cluster files.
# 		The B-cubed scores are evaluated for test_set against gold_standard.
# 		The scores are commutative, which means you will get the same scores
# 		if you exchange the test set and the gold standard.
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
from clusters import read_clusters

if len(sys.argv) != 3:
    print "Usage: %s GOLD TEST" % sys.argv[0]
    print "Given:", ' '.join(sys.argv)
    sys.exit(1)

gold_file = sys.argv[1]
clustering = sys.argv[2]

label = {}
cluster = {}

print "gold standard:", gold_file
print "clustering:", clustering
print "clusters of gold standard:", read_clusters(gold_file, label)
print "clusters of test set:", read_clusters(clustering, cluster)

for key in label.keys():
    if not key in cluster:
        print key, 'is missing in cluster'
        sys.exit(1)

for key in cluster.keys():
    if not key in label:
        print key, 'is missing in label'
        sys.exit(1)

precision = 0.0
recall = 0.0
noprecision = 0
norecall = 0

keys = cluster.keys()
for i, e in enumerate(keys):
    mulprec = 0.0
    mulrec = 0.0
    nomulprec = 0
    nomulrec = 0
    for i2, e2 in enumerate(keys):
        if e == e2:
            continue
        labelintersection = len(label[e] & label[e2])
        clusterintersection = len(cluster[e] & cluster[e2])
        less = min(labelintersection, clusterintersection)
        if clusterintersection > 0:
            mulprec += float(less) / float(clusterintersection)
            nomulprec += 1
        if labelintersection > 0:
            mulrec += float(less) / float(labelintersection)
            nomulrec += 1
    if nomulprec > 0:
        precision += mulprec / float(nomulprec)
        noprecision += 1
    if nomulrec > 0:
        recall += mulrec / float(nomulrec)
        norecall += 1
if noprecision > 0:
    precision /= float(noprecision)
if norecall > 0:
    recall /= float(norecall)
#print nomulprec, nomulrec, noprecision, norecall

fscore = 0.0
if precision + recall > 0.0:
    fscore = 2*precision*recall / (precision + recall)
print "Multiplicity BCubed precision: %.4f" % (precision)
print "Multiplicity BCubed recall:    %.4f" % (recall)
print "Multiplicity BCubed F-score:   %.4f" % (fscore)
