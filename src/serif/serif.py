#!/usr/bin/env python
#
# serif.py
#
# Basic module to read SGM and APF file format
# to extract date forms from them



import sys
import re
import bisect
from xml.dom.minidom import parse



class Text:
    def __init__(self):
	self.lines = []
	self.offsets = []
    def find(self, offset):
	index = bisect.bisect(self.offsets, offset)
	return index
    def substring(self, off_start, off_end):
	line_start = self.find(off_start)
	line_end = self.find(off_end)
	if line_start == line_end:
	    line = self.lines[line_start]
	    if line_start > 0:
		off_start -= self.offsets[line_start-1]
		off_end -= self.offsets[line_start-1]
	    return line, line[off_start:off_end+1]
	else:
	    print off_start, line_start, self.lines[line_start], self.offsets[line_start]
	    print off_end, line_end, self.lines[line_end], self.offsets[line_end]
	    return None, None



class Timex:
    def __init__(self, val, start, end):
	self.val = val
	self.start = start
	self.end = end



def read_sgm(filename):
# Read sgm file formats
# into:
    tag_re = re.compile("<[^>]*>")
    file = open(filename, 'r')
    data = Text()
    offset = 0
    for line in file:
	line = tag_re.sub('', line.decode('utf-8'))
	data.lines.append(line.strip())
	offset += len(line)
	data.offsets.append(offset)
    return data



def read_apf(filename):
    file = open(filename, 'r')
    dom = parse(file)
    data = []
    for source_file in dom.getElementsByTagName('source_file'):
	for document in source_file.getElementsByTagName('document'):
	    for timex2 in document.getElementsByTagName('timex2'):
		for timex2_mention in timex2.getElementsByTagName('timex2_mention'):
		    for extent in timex2_mention.getElementsByTagName('extent'):
			for charseq in extent.getElementsByTagName('charseq'):
			    if charseq.hasAttribute('START') and charseq.hasAttribute('END'):
				val = timex2.getAttribute('VAL')
				start = int(charseq.getAttribute('START'))
				end = int(charseq.getAttribute('END'))
				timex = Timex(val, start, end)
				data.append(timex)
    return data
