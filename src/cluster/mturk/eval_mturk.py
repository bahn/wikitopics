#!/usr/bin/env python

import sys
from cluster_mturk import read_mturk_clustering
sys.path.append('../eval')
from clusters import read_clusters

if __name__=='__main__':
    if len(sys.argv) != 3:
	print "Usage: %s MTURK.gz GOLD_CLUSTERING" % sys.argv[0]
	sys.exit(1)
    clustering = read_mturk_clustering(sys.argv[1])
    label = {}
    read_clusters(sys.argv[2], label)
    titles = clustering.articles

    num_all = 0
    num_correct = 0

    max_links = 0
    for links in set(clustering.links.values()):
        if max_links < links:
            max_links = links
    for title in titles:
        for title2 in titles:
            if title != title2:
                num_all += 1
                mturk = clustering.links.get(title + '/' + title2, 0)
                score = float(mturk) / float(max_links)
                if label[title] & label[title2]:
                    num_correct += score
                else:
                    num_correct += 1.0 - score
    if num_all:
        print num_correct / num_all
