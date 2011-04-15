#!/usr/bin/env python
#
# eval_sents.py
# -------------
# The script to evaluation sentence selection against gold standard.
# 
# Usage: eval_sents.py test_dir gold_dir
#
# Input:
#     each file in the test_dir directory only has one line:
#     its best selection of sentence.
#     the line has the line number of the selected selected and
#     the sentence itself, separated by a space.
# 
#     each file in the gold_dir directory has at least one line.
#     each line in the files in the same format as those in the test_dir directory.
#     the first line is the best choice, and the rest of the lines are the secondary choice.
# 
#     if the line number is -1, it means no sentences are selected.
# 
# Output:
#     item_counts: The number of the test items.
#     best_correct: The number of the correct best choice.
#     best_guess: The number of the lines of the test data, whose line number is not -1.
#     best_answer: The number of the liens of the gold standard data, whose line number is not -1.
#     second_correct: The number of the choice that is either the best choice or
#                     one of the secondary choice.
#     second_guess: Same as best_guess for now.
#     second_answer: The number of the lines in the gold standard data including the best choice.
# 
#     Note that even if the best choice are both -1 both in the test data and in the gold standard data,
#     They do not add up to the number of the correct choice.

import os
import sys
import re

if len(sys.argv) < 3:
    print "Usage: eval_sents.py test_dir gold_dir"
    sys.exit(1)

test_dir = sys.argv[1]
gold_dir = sys.argv[2]

item_counts = 0

test_best = 0
test_second = 0

gold_best = 0
gold_second = 0

best_tp = 0
second_tp = 0

def read_file(filename):
    lineno_set = set()
    lineno = -1
    file = open(filename)
    line = file.readline()
    field = line.split(' ', 1)[0]
    if field and int(field) != -1:
        lineno = int(field)
        lineno_set.add(lineno)
    for line in file:
        field = line.split(' ', 1)[0]
        if field and int(field) != -1:
            lineno_set.add(int(field))
    file.close()
    return lineno, lineno_set

for dirpath, dirnames, filenames in os.walk(test_dir):
    rel_dir = dirpath[len(test_dir):]
    if rel_dir.startswith('/'):
        rel_dir = rel_dir[1:]
    for file in filenames:
        if file == '.DS_Store':
            continue
        if not os.path.isfile(os.path.join(gold_dir, rel_dir, file)):
            continue
        #print '#', file
        item_counts += 1

        test_lineno, test_set = read_file(os.path.join(test_dir, rel_dir, file))
        gold_lineno, gold_set = read_file(os.path.join(gold_dir, rel_dir, file))

        if test_lineno != -1:
            test_best += 1
            if test_lineno == gold_lineno:
                best_tp += 1
        if len(test_set) > 0:
            test_second += 1
        if gold_lineno != -1:
            gold_best += 1
        if len(gold_set) > 0:
            gold_second += 1
        if len(test_set & gold_set) > 0:
            second_tp += 1

# Print the differences
#        if lineno_guess != lineno:
#            print '#', rel_dir, file
#            print os.path.basename(test_dir), ':', line_guess.strip()
#            print os.path.basename(gold_dir), ':', line_gold.strip()
#            print

def get_data_set(dirname):
	regexes = [ r'([^/]+)/[a-z]+/[0-9]+$', r'([^/]+)/[0-9]+$', r'([^/]+)$' ]
	for regex in regexes:
		m = re.search(regex, dirname)
		if m:
			return m.group(1)
	return os.path.basename(dirname)

print get_data_set(test_dir), 'evaluated against', get_data_set(gold_dir)
print
if item_counts == 0:
    print 'no item evaluated'
    sys.exit(0)
print 'item_counts:', item_counts
print 'a best_tp:', best_tp
print 'b test_best:', test_best
print 'c gold_best:', gold_best
p = float(best_tp)/float(test_best)
r = float(best_tp)/float(gold_best)
f = 2.*p*r / (p+r)
print 'p = a/b = %.3f' % p
print 'r = a/c = %.3f' % r
print 'f = 2pr / (p+r) = %.3f' % f
print
print 'a second_tp:', second_tp
print 'b test_second:', test_second
print 'c gold_second:', gold_second
p = float(second_tp)/float(test_second)
r = float(second_tp)/float(gold_second)
f = 2.*p*r / (p+r)
print 'p = a/b = %.3f' % p
print 'r = a/c = %.3f' % r
print 'f = 2pr / (p+r) = %.3f' % f
