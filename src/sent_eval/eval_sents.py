#!/usr/bin/env python
#
# eval_sents.py
# -------------
# The script to evaluation sentence selection against gold standard.
# 
# Usage: eval_sents.py test_dir gold_standard_dir
#
# Input:
# 	each file in the test_dir directory only has one line:
# 	its best selection of sentence.
# 	the line has the line number of the selected selected and
# 	the sentence itself, separated by a space.
# 
# 	each file in the gold_standard_dir directory has at least one line.
# 	each line in the files in the same format as those in the test_dir directory.
# 	the first line is the best choice, and the rest of the lines are the secondary choice.
# 
# 	if the line number is -1, it means no sentences are selected.
# 
# Output:
# 	item_counts: The number of the test items.
# 	best_correct: The number of the correct best choice.
# 	best_guess: The number of the lines of the test data, whose line number is not -1.
# 	best_answer: The number of the liens of the gold standard data, whose line number is not -1.
# 	second_correct: The number of the choice that is either the best choice or
# 					one of the secondary choice.
# 	second_guess: Same as best_guess for now.
# 	second_answer: The number of the lines in the gold standard data including the best choice.
# 
# 	Note that even if the best choice are both -1 both in the test data and in the gold standard data,
# 	They do not add up to the number of the correct choice.

import os
import sys

if len(sys.argv) < 3:
	print "Usage: eval_sents.py test_dir gold_standard_dir"
	sys.exit(1)

test_dir = sys.argv[1]
gold_standard_dir = sys.argv[2]

item_counts = 0
best_correct = 0
best_guess = 0
best_answer = 0
second_correct = 0
second_guess = 0
second_answer = 0

for dirpath, dirnames, filenames in os.walk(test_dir):
	rel_dir = dirpath[len(test_dir):]
	if rel_dir.startswith('/'):
		rel_dir = rel_dir[1:]
	for file in filenames:
		if not os.path.isfile(os.path.join(gold_standard_dir, rel_dir, file)):
			continue
		item_counts += 1

		f = open(os.path.join(test_dir, rel_dir, file))
		l = f.readline()
		lineno = l.split(' ', 1)[0]
		if lineno:
			lineno = int(lineno)
		else:
			lineno = -1
		f.close()

		if lineno != -1:
			best_guess += 1
			second_guess += 1
		lineno_guess = lineno
		
		f = open(os.path.join(gold_standard_dir, rel_dir, file))
		l = f.readline()
		lineno = l.split(' ', 1)[0]
		if lineno:
			lineno = int(lineno)
		else:
			lineno = -1
		if lineno != -1:
			best_answer += 1
			second_answer += 1
			if lineno_guess == lineno:
				best_correct += 1
				second_correct += 1

		for l in f:
			lineno = int(l.split(' ', 1)[0])
			if lineno != -1:
				second_answer += 1
				if lineno_guess == lineno:
					second_correct += 1
		f.close()

if item_counts == 0:
	print 'no item evaluated'
	sys.exit(0)
print 'item_counts:', item_counts
print 'a best_correct:', best_correct
print 'b best_guess:', best_guess
print 'c best_answer:', best_answer
p = float(best_correct)/float(best_guess)
r = float(best_correct)/float(best_answer)
f = 2.*p*r / (p+r)
print 'p = a/b =', p
print 'r = a/c =', r
print 'f = 2pr / (p+r) =', f
print 'a second_correct:', second_correct
print 'b second_guess:', second_guess
print 'c second_answer:', second_answer
p = float(second_correct)/float(second_guess)
r = float(second_correct)/float(second_answer)
f = 2.*p*r / (p+r)
print 'p = a/b =', p
print 'r = a/c =', r
print 'f = 2pr / (p+r) =', f
