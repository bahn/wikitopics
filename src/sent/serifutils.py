"""
Utility functions for Serif
"""

import re
import datetime

def delta_date_timex(date, timex_val):
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

	if re1.match(timex_val):
		m = re1.match(timex_val)
		year = m.group(1)
		month = m.group(2)
		day = m.group(3)
		if year == 'XXXX':
			try:
				return abs(date - datetime.date(date.year, int(month), int(day))) + datetime.timedelta(days=366 + 3660)
			except ValueError:
				return abs(date - datetime.date(date.year, int(month), 28)) + datetime.timedelta(days=int(day) - 28 + 366 + 3660)
		else:
			return abs(date - datetime.date(int(year), int(month), int(day)))
	elif re2.match(timex_val):
		m = re2.match(timex_val)
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
				try:
					return abs(date - datetime.date(date.year, int(month), date.day)) + datetime.timedelta(days=31+366+3660)
				except ValueError:
					return abs(date - datetime.date(date.year, int(month), 28)) + datetime.timedelta(days=date.day-28 + 31+366+3660)
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
				try:
					return abs(date - datetime.date(int(year), int(month), date.day)) + datetime.timedelta(days=31)
				except ValueError:
					return abs(date - datetime.date(int(year), int(month), 28)) + datetime.timedelta(days=date.day-28 + 31)
	elif re3.match(timex_val):
		m = re3.match(timex_val)
		year = m.group(1)
		if len(year) == 2:
			return datetime.timedelta(days=abs(int(date.year / 100) - int(year))*36500+36600)
		elif len(year) == 3:
			return datetime.timedelta(days=abs(int(date.year / 10) - int(year))*3650+3660)
		elif len(year) == 4:
			return datetime.timedelta(days=abs(date.year - int(year))*365+366)
	return datetime.timedelta(days=365*9999)

def print_line(doc, value_mention):
	offset = 0
	for lineno, line in enumerate(doc.original_text.contents.splitlines()):
		offset += len(line) + 1
		if value_mention.end_char <= offset:
			print lineno, line
			break

