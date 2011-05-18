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
import wikipydia

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

redirects = {}
assumed_same = set(label.keys()) & set(cluster.keys())
to_lookup = set(label.keys()) ^ set(cluster.keys())

while to_lookup: # if there are missing keys, try to find redirects
	key = to_lookup.pop()
	title = wikipydia.query_redirects(key).replace(' ','_')
	redirects[key] = title
	if title in assumed_same:
		assumed_same.remove(title)
		to_lookup.add(title)

# update the data with the redirects
redirects.update(dict([(key, key) for key in assumed_same]))
label = dict([(redirects[key], values) for key, values in label.items()])
cluster = dict([(redirects[key], values) for key, values in cluster.items()])

# check there are still missing keys
missing = set(label.keys()) ^ set(cluster.keys())
if missing:
	sys.stderr.write('Following keys are missing:\n')
	for key in missing:
		sys.stderr.write(key + '\n')
	sys.exit(1)
	
precision = 0.0
recall = 0.0
noprecision = 0
norecall = 0

# one version
#pairs = [(key1, key2) for key1 in label.keys() for key2 in cluster.keys() if key1 != key2]
#li = [len(label[key1] & label[key2]) for key1, key2 in pairs] # label intersections
#ci = [len(cluster[key1] & cluster[key2]) for key1, key2 in pairs] #cluster intersections
#pair_precision = [min(nl, nc) / float(nc) for nl, nc in zip(li, ci) if nc != 0]
#pair_recall = [min(nl, nc) / float(nl) for nl, nc in zip(li, ci) if nl != 0]
#precision = sum(pair_precision) / len(pair_precision) if pair_precision else 1.0
#recall = sum(pair_recall) / len(pair_recall) if pair_recall else 1.0

# another version
keys = label.keys()
row_precision = []
row_recall = []
for key1 in keys:
	cols = [key2 for key2 in keys if key2 != key1]
	li = [len(label[key1] & label[key2]) for key2 in cols]
	ci = [len(cluster[key1] & cluster[key2]) for key2 in cols]
	col_precision = [min(nl, nc) / float(nc) for nl, nc in zip(li, ci) if nc != 0]
	col_recall = [min(nl, nc) / float(nl) for nl, nc in zip(li, ci) if nl != 0]
	if col_precision:
		row_precision.append( sum(col_precision) / len(col_precision) )
	if col_recall:
		row_recall.append( sum(col_recall) / len(col_recall) )
precision = sum(row_precision) / len(row_precision) if row_precision else 1.0
recall = sum(row_recall) / len(row_recall) if row_recall else 1.0

# determine f-score
fscore = 2*precision*recall / (precision + recall) if precision + recall else 1.0

print "Multiplicity BCubed precision: %.4f" % (precision)
print "Multiplicity BCubed recall:    %.4f" % (recall)
print "Multiplicity BCubed F-score:   %.4f" % (fscore)
