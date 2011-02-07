#!/usr/bin/env python

import sys

lines = sys.stdin.readlines()
for i in range(0,25):
    shfile = open('make_daily_part%d.sh' % i, 'w')
    shfile.writelines(lines[ i*13 : i*13+13 ])
    shfile.close()

