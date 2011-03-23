#!/usr/bin/env python
"""
Read clusters from a plain text file
"""

import sys
import unicodedata

def read_clusters(filename, bag):
    f = open(filename, 'r')
    numClusters = 0
    numInstances = 0
    for line in f:
        if (line.find('#') != -1): # eliminates comments
            line = line[:line.find('#')].strip()
        line = unicodedata.normalize("NFC", line.decode('utf8'))
        tokens = line.split(None, 1)
        if len(tokens) == 0:
            if numInstances:
                numClusters += 1
                numInstances = 0
        else:
            topic = tokens[0].strip()
            bag.setdefault(topic, set()).add(numClusters)
            numInstances += 1
    if numInstances:
        numClusters += 1
        numInstances = 0
    return numClusters
