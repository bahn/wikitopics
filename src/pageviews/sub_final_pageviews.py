#!/usr/bin/env python
import sys
import os
import os.path
import datetime

if len(sys.argv) != 4:
	print "usage: " + os.path.basename(sys.argv[0]) + " RAW_FILE HOURLY_PATH DAILY_PATH"
	sys.exit(1)

raw_filename = sys.argv[1]
hourly_path = sys.argv[2]
daily_path = sys.argv[3]

if os.path.exists(hourly_path) and not os.path.isdir(hourly_path):
	print hourly_path + " is not a directory."
	sys.exit(1)

if os.path.exists(daily_path) and not os.path.isdir(daily_path):
	print daily_path + " is not a directory."
	sys.exit(1)

if not os.path.exists(hourly_path):
	try:
		os.makedirs(hourly_path)
	except:
		print "failed to create the directory " + hourly_path
		sys.exit(1)

if not os.path.exists(daily_path):
	try:
		os.makedirs(daily_path)
	except:
		print "failed to create the directory " + daily_path
		sys.exit(1)

basename = os.path.basename(raw_filename)
hourly_filename = os.path.join(hourly_path, basename)
daily_filename = os.path.join(daily_path, basename)

try:
	hourly_file = open(hourly_filename, 'w')
except:
	print "failed writing", hourly_filename
	sys.exit(1)

try:
	daily_file = open(daily_filename, 'w')
except:
	print "failed writing", daily_filename
	sys.exit(1)

last_org_time = datetime.timedelta(0)
last_new_time = datetime.timedelta(0)

print_org_time = datetime.date(1,1,1)
print_new_time = datetime.date(1,1,1)
last_print_new_time = 0
print_pageviews = 0

cur_pageviews = 0

started = False

last_date = 0
last_print_date = 0
last_day_pageviews = 0

def print_hourly_pageviews():
	global hourly_file
	global print_org_time
	global print_pageviews
	global last_print_new_time

# print dates in-between
	if last_print_new_time:
		time = last_print_new_time + datetime.timedelta(hours=1)
		while time < print_new_time:
			hourly_file.write(time.strftime("%Y%m%d-%H%M%S") + "\t0\n")
			time += datetime.timedelta(hours=1)
	hourly_file.write(print_org_time.strftime("%Y%m%d-%H%M%S") + "\t" + str(print_pageviews) + "\n")
	last_print_new_time = print_new_time

def print_daily_pageviews():
	global daily_file
	global last_date
	global last_print_date
	global last_day_pageviews

	if last_print_date:
		d = last_print_date + datetime.timedelta(days=1)
		while d < last_date:
			daily_file.write(d.strftime("%Y%m%d") + "\t0\n")
			d += datetime.timedelta(days=1)
	daily_file.write(last_date.strftime("%Y%m%d") + "\t" + str(last_day_pageviews) + "\n")
	last_print_date = last_date

def update_daily_pageviews():
	global last_date
	global last_day_pageviews
	global print_new_time
	global print_pageviews

	t = print_new_time
	cur_date = datetime.date(t.year, t.month, t.day)
	if last_date == cur_date:
		last_day_pageviews += print_pageviews
	else:
		if last_date:
			print_daily_pageviews()
		last_date = cur_date
		last_day_pageviews = print_pageviews

try:
	for line in open(raw_filename):
		if line.startswith('date'):
			continue
		fields = line.split()

# extract the fields
		org_time = datetime.datetime.strptime(fields[0], "%Y%m%d-%H%M%S")
		try:
			pageviews = int(fields[1])
		except:
			print "ignored line: ", line,
			continue

# standardize the timestamp
		new_time = org_time
		if new_time.second != 0:
			if new_time.second < 30:
				new_time -= datetime.timedelta(seconds = new_time.second)
			else:
				new_time += datetime.timedelta(seconds = 60 - new_time.second)
		if new_time.minute != 0:
			if new_time.minute < 30:
				new_time -= datetime.timedelta(minutes = new_time.minute)
			else:
				new_time += datetime.timedelta(minutes = 60 - new_time.minute)
		
		if print_new_time != new_time:
			if started:
				print_hourly_pageviews()
				update_daily_pageviews()
			print_org_time = org_time
			print_new_time = new_time
			print_pageviews = pageviews
			started = True
		else:
			if print_org_time == org_time:
				print_pageviews += pageviews
			else:
				if last_org_time == org_time:
					cur_pageviews += pageviews
				else:
					cur_pageviews = pageviews
				if cur_pageviews > print_pageviews:
					print_pageviews = cur_pageviews
					print_org_time = org_time
					print_new_time = new_time

		last_org_time = org_time
		last_new_time = new_time

	if started:
		print_hourly_pageviews()
		print_daily_pageviews()

except IOError, e:
	if e.errno == errno.EPIPE:
		pass
	else:
		raise

except KeyboardInterrupt:
	pass
