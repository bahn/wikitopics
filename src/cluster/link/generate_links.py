#!/usr/bin/env python

from wikipydia import query_links
import sys

if len(sys.argv) != 2:
    print "Usage: generate_links article_list"
    sys.exit(1)
    
titles_file = open(sys.argv[1], "r")
titles = dict([ (line.strip(), i) for i, line in enumerate(titles_file) ])

edges = {}
num = 0
for title, i in titles.items():
    num += 1
    sys.stderr.write("# %s %d/%d\r" % (title, num, len(titles)))
    links = query_links(title)
    for link in links:
        link = link.replace(' ', '_')
        if len(link) >= 1:
            link = link[:1].upper() + link[1:]
        if link in titles:
            j = titles[link]
            edges.setdefault(i, []).append(j)

sys.stderr.write("\n")
for i, links in edges.items():
    sys.stdout.write("%d:" % (i+1))
    for j in links:
        sys.stdout.write(" %d" % (j+1))
    sys.stdout.write("\n")
