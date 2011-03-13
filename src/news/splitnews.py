#!/usr/bin/env python

import sys
if len(sys.argv) != 3:
    print "Usage: %s input_file output_file_prefix"
    sys.exit(-1)

input_file = open(sys.argv[1])
output_file_prefix = sys.argv[2]
file_number = 0
output_file = None

for line in input_file:
    if not line.strip():
        if output_file:
            output_file.close()
            output_file = None
    else:
        if not output_file:
            file_number += 1
            output_file = open("%s%04d.txt" % (output_file_prefix, file_number),"w")
        output_file.write(line)
if output_file:
    output_file.close()
    output_file = None
