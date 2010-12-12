#!/usr/bin/env python
#
# number_sents.py
# ---------------
# The script to put a number to each line in the file.
# The sentence number 1 is the first sentence of the article.
#
# Usage: number_sents sentences_file_dir source_article_dir output_dir
#	sentences_file_dir
#		the directory in which the files with selected sentences are located.
#	source_article_dir
#		the directory in which the articles are located.
#	output_dir
#		The directory into which the output files are written.

import sys
import os

if len(sys.argv) < 4:
	print "Usage: number_sents sentences_file_dir source_article_dir output_dir"
	print "sentences_file_dir"
	print "	the directory in which the files with selected sentences are located."
	print "source_article_dir"
	print "	the directory in which the articles are located."
	print "output_dir"
	print "	The directory into which the output files are written."
	sys.exit(1)

sent_dir = sys.argv[1]
source_dir = sys.argv[2]
out_dir = sys.argv[3]

source_files = os.listdir(source_dir)
sent_files = os.listdir(sent_dir)

try:
	os.makedirs(out_dir)
except:
	pass

for file in sent_files:
	if not os.path.isfile(os.path.join(sent_dir, file)):
		continue
	if not file in source_files:
		print '#', file, 'not found'
		continue
	print '#', file
	f = open(os.path.join(source_dir, file), 'r')
	lines = [l.strip() for l in f]
	f.close()

	lines_output = []

	f = open(os.path.join(sent_dir, file), 'r')
	for sent in f:
		line = sent.strip()
		try:
			i = lines.index(line)
			lines_output.append('%d %s' % (i+1, sent))
		except:
			lines_output.append('-1 %s' % (sent))
	f.close()

	f = open(os.path.join(out_dir, file), 'w')
	f.writelines(lines_output)
	f.close()
