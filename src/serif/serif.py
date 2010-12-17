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
import datetime


class Text:
	def __init__(self):
		self.text = ''
		self.offsets = [0]
	def __init__(self, file):
		self.text = unicode(file.read(), 'utf-8')
		self.text = re.sub("<[^>]*?>", '', self.text)
		self.offsets = [0]
		offset = 0
		for line in self.text.split('\n'):
			offset += 1 + len(line)
			self.offsets.append(offset)
	def find(self, offset):
		line = bisect.bisect(self.offsets, offset)
		return line
	def substr(self, start, end):
		return self.text[start:end+1]
	def expand(self, start, end):
		startline = self.find(start)
		endline = self.find(end)
		return (self.offsets[startline-1], self.offsets[endline]-2)
	def expandstr(self, start, end):
		start, end = self.expand(start, end)
		return self.substr(start, end)


class Analysis:
	def __init__(self, text, file):
		self.timexList = []
		self.entityList = []
		dom = parse(file)
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
									self.timexList.append(timex)
				for entity_elem in document.getElementsByTagName('entity'):
					entity = Entity(text, entity_elem.getAttribute('TYPE'), entity_elem.getAttribute('SUBTYPE'))
					self.entityList.append(entity)
					for entity_mention in entity_elem.getElementsByTagName('entity_mention'):
						start = 0
						end = 0
						for extent in entity_mention.getElementsByTagName('extent'):
							for charseq in extent.getElementsByTagName('charseq'):
								if charseq.hasAttribute('START') and charseq.hasAttribute('END'):
									start = int(charseq.getAttribute('START'))
									end = int(charseq.getAttribute('END'))
						for head in entity_mention.getElementsByTagName('head'):
							for charseq in head.getElementsByTagName('charseq'):
								if charseq.hasAttribute('START') and charseq.hasAttribute('END'):
									headstart = int(charseq.getAttribute('START'))
									headend = int(charseq.getAttribute('END'))
									mention = EntityMention(entity_mention.getAttribute('TYPE'), start, end, headstart, headend)
									entity.add_mention(mention)


class Timex:
	def __init__(self, val, start, end):
		self.val = val
		self.start = start
		self.end = end
	def __str__(self):
		if self.val:
			return self.val
		else:
			return "<NONE>"


class Entity:
	def __init__(self, text, type, subtype):
		self.type = type
		self.subtype = subtype
		self.name = ''
		self.mentions = []
		self.updated = False
		self.text = text # for the time being, it assumed all mentions share a single text (source article).
	def add_mention(self, mention):
		if mention not in self.mentions:
			self.mentions.append(mention)
			self.name = '<UPDATED>'
			self.updated = True
	def update_name(self):
		if not self.updated:
			return
		namecounts = {}
		for mention in self.mentions:
			#if mention.type == 'NAM':
			name = self.text.substr(mention.start, mention.end)
			if name in namecounts:
				namecounts[name] += 1
			else:
				namecounts[name] = 1
		maxcount = 0
		for name in namecounts.keys():
			if namecounts[name] > maxcount:
				maxcount = namecounts[name]
				self.name = name
		self.updated = False
	def __str__(self):
		self.update_name()
		if self.name:
			return self.name.encode('utf8')
		else:
			return 'Anonymous entity (' +  self.type + '-' + self.subtype + ')'


class EntityMention:
	def __init__(self, type, start, end, headstart, headend):
		self.type = type
		self.start = start
		self.end = end
		self.headstart = headstart
		self.headend = headend
	def set_entity(self, entity):
		entity.add_mention(self)
	def __str__(self):
		return '%s' % (self.type)
		


def read_sgm(filename):
	file = open(filename, 'r')
	return Text(file)


def read_apf(text, filename):
	file = open(filename, 'r')
	return Analysis(text, file)



def convert_to_date(str):
	pattern = re.compile(r"(\d{4})-(\d{2})-(\d{2})")
	if not pattern.match(str):
		print "invalid format; need iso format:", str
		sys.exit(1)
	else:
		m = pattern.match(str)
		year = m.group(1)
		month = m.group(2)
		day = m.group(3)
		date = datetime.date(int(year), int(month), int(day))
		return date


def delta_date_timex(date, timex):
	## We only consider the following date formats.
	## YYYY-MM-DD (time ignored if attached)
	## YYYY-MM
	## YYYY-SS
	## XXXX-MM-DD
	## XXXX-MM
	## XXXX-SS
	## YYYY
	## YYY
	## YY

	# date possible followed by time. e.g. 2009-01-27T05:00:00, XXXX-08-27, XXXX-12-24TEV.
	re1 = re.compile("^(\d{4}|XXXX)-(\d{2})-(\d{2})(T(\d{2}:\d{2}:\d{2}|\d{2}:\d{2}|EV))?$")
	# month or season. e.g. 2009-01. 2008-SU.
	re2 = re.compile("^(\d{4}|XXXX)-(\d{2}|SP|SU|FA|WI)$")
	# year, century, or decades. e.g. 2009, 199, 16(i.e. the 17th century).
	re3 = re.compile("^(\d{2,4})$")

	if re1.match(timex.val):
		m = re1.match(timex.val)
		year = m.group(1)
		month = m.group(2)
		day = m.group(3)
		if year == 'XXXX':
			return abs(date - datetime.date(date.year, int(month), int(day))) + datetime.timedelta(days=366 + 3660)
		else:
			return abs(date - datetime.date(int(year), int(month), int(day)))
	elif re2.match(timex.val):
		m = re2.match(timex.val)
		year = m.group(1)
		month = m.group(2)
		if year == 'XXXX':
			if month == 'SP':
				return max(abs(date - datetime.date(date.year, 3, 20)), abs(date - datetime.date(date.year, 6, 21))) + datetime.timedelta(days=18+366+3660)
			elif month == 'SU':
				return max(abs(date - datetime.date(date.year, 3, 20)), abs(date - datetime.date(date.year, 6, 21))) + datetime.timedelta(days=18+366+3660)
			elif month == 'FA':
				return max(abs(date - datetime.date(date.year, 9, 22)), abs(date - datetime.date(date.year, 12, 22))) + datetime.timedelta(days=18+366+3660)
			elif month == 'WI':
				return min(max(abs(date - datetime.date(date.year, 12, 21)), abs(date - datetime.date(date.year+1, 3, 21))) + datetime.timedelta(days=18+366+3660),
						 max(abs(date - datetime.date(date.year-1, 12, 21)), abs(date - datetime.date(date.year, 3, 21))) + datetime.timedelta(days=18+366+3660))
			else:
				return abs(date - datetime.date(date.year, int(month), date.day)) + datetime.timedelta(days=31+366+3660)
		else:
			if month == 'SP':
				return max(abs(date - datetime.date(int(year), 3, 20)), abs(date - datetime.date(int(year), 6, 21))) + datetime.timedelta(days=18)
			elif month == 'SU':
				return max(abs(date - datetime.date(int(year), 6, 20)), abs(date - datetime.date(int(year), 9, 23))) + datetime.timedelta(days=18)
			elif month == 'FA':
				return max(abs(date - datetime.date(int(year), 9, 22)), abs(date - datetime.date(int(year), 12, 22))) + datetime.timedelta(days=18)
			elif month == 'WI':
				return min(max(abs(date - datetime.date(int(year), 12, 21)), abs(date - datetime.date(int(year)+1, 3, 21))) + datetime.timedelta(days=18),
						 max(abs(date - datetime.date(int(year)-1, 12, 21)), abs(date - datetime.date(int(year), 3, 21))) + datetime.timedelta(days=18))
			else:
				return abs(date - datetime.date(int(year), int(month), date.day)) + datetime.timedelta(days=31)
	elif re3.match(timex.val):
		m = re3.match(timex.val)
		year = m.group(1)
		if len(year) == 2:
			return datetime.timedelta(days=abs(int(date.year / 100) - int(year))*36500+36600)
		elif len(year) == 3:
			return datetime.timedelta(days=abs(int(date.year / 10) - int(year))*3650+3660)
		elif len(year) == 4:
			return datetime.timedelta(days=abs(date.year - int(year))*365+366)
	return None


def find_best_timex(date, text, data, btimex = None):
	# the best one
	if not btimex:
		btdelta = None
	else:
		btdelta = delta_date_timex(date, btimex)

	for timex in data.timexList:
		#print timex.val
		tdelta = delta_date_timex(date, timex)
		# tdelta could be zero, which means the best date possible
		if tdelta != None:
			#print timex.val, 'accepted'
			if not btimex:
				btimex = timex
				btdelta = tdelta
			elif tdelta < btdelta:
				btimex = timex
				btdelta = tdelta
	return btimex

# The function to pick the sentence with the most recent date
# and a self reference.
# Originally copied from find_best_timex().
def pick_self(date, text, data, btimex = None):
	# make a map to store if the line has a self reference.
	if not data.entityList:
		return btimex

	line_self = {}
	self_entity = data.entityList[0]
	for mention in self_entity.mentions:
		line = text.find(mention.start)
		line_self[line] = True

	# the best one
	if not btimex:
		btdelta = None
	else:
		btdelta = delta_date_timex(date, btimex)
	
	for timex in data.timexList:
		# ignore if the date is from a line without a self reference.
		line = text.find(timex.start)
		if not line in line_self:
			continue

		#print timex.val
		tdelta = delta_date_timex(date, timex)
		# tdelta could be zero, which means the best date possible
		if tdelta != None:
			#print timex.val, 'accepted'
			if not btimex:
				btimex = timex
				btdelta = tdelta
			elif tdelta < btdelta:
				btimex = timex
				btdelta = tdelta
	return btimex

# Resolve coreference.
# Replace pronouns in the text with its most frequent proper name.
def resolveCoref(text, data, start, end):
	# boundaries: Boundaries for the pronouns.
	# The first, third, fifth, ..., intervals represent the remaining text,
	# and the others the text to be replaced by proper names.
	boundaries = [start, end+1]
	# substs: The text to replace pronouns with.
	# Each element in this list is a 3-tuple: (start, end, name)
	# which means the text from start to end to be replaced with name.
	substs = []
	# loop through all entities in the given SERIF output.
	for entity in data.entityList:
		if entity.type != 'PER' or not entity.name:
			continue
		for mention in entity.mentions:
			if mention.type == 'PRO':
				# Find pronouns in the given text
				if start <= mention.start and mention.end <= end:
					substr = text.substr(mention.start, mention.end)
					# Find the text to replace the pronoun with and
					# append it to the substs list.
					if substr == 'he' or substr == 'He' or substr == 'she' or substr == 'She':
						entity.update_name()
						boundaries.extend([mention.start, mention.end+1])
						substs.append((mention.start, mention.end+1, entity.name))
					elif substr == 'his' or substr == 'His' or substr == 'her' or substr == 'Her':
						entity.update_name()
						boundaries.extend([mention.start, mention.end+1])
						substs.append((mention.start, mention.end+1, entity.name + "'s"))
	# Substitute each pronoun by its proper name
	boundaries.sort()
	s = ''
	for i in range(len(boundaries)-1):
		start = boundaries[i]
		end = boundaries[i+1]
		if start != end:
			for subst in substs:
				a, b, c = subst
				if start == a and end == b:
					s += c
					break
			else:
				s += text.substr(start, end-1)
	return s

