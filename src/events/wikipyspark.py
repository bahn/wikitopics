#!/usr/bin/env python
#
# wikipyspark.py
#
# Using the jQuery Sparklines, draw sparklines for all the current evenets.
# 
# Usage:
# 	./wikipyspark.py [dates] [text] [links] [page_views]
# 	e.g. ./wikipyspark.py data/events/events_date_2009 data/events/events_text_2009 data/events/events_links_2009 data/events/events_page_views_by_date_2009
# 
# Input:
# 	dates
# 		the file that has all the dates 2009. The format is compatible with JSON.
# 		Examples:
# 		["1/1/2009", "1/2/2009", ..., "12/31/2009"]
# 
# 	text
# 		Each line describes an Wikipedia current events and contains
# 		the date and index of the event and the text that describes the events.
# 		The format is as follows:
# 20090101 0 *A man is shot and killed at California's Fruitvale BART station by a Bay Area Rapid Transit officer.
# 20090101 1 *An Israeli airstrike on the Gaza Strip city of Jabalia kills senior Hamas military commander Nizar Rayan and six members of his family.
# 20090101 2 *At least five people die and more than 50 are injured in serial bombings in Guwahati, India.
# 20090101 3 *Russia's Gazprom halts deliveries of natural gas to Ukraine after negotiations over prices fail.
# ...
# 
# 	links
# 		the links from the Wikipedia current events. e.g. data/events/events_links_2009
# 		Each line contains the date and the index of the event (which is reset every day),
# 		and the title of an article linked from the event.
# 		e.g.)
# 20090101 0 BART_Police_shooting_of_Oscar_Grant
# 20090101 0 California
# 20090101 0 Bay_Area_Rapid_Transit
# 20090101 0 Fruitvale_%28BART_station%29
# ...
# 
# 	page_views
# 		this files has the daily page views for all articles in the current events.
# 		e.g.)
# 		["14th_Dalai_Lama", [["12/1/2008", 2112], ..., ["12/31/2009", 1811]]]
    
import sys
import simplejson
import string
import os

class Bullet():
    def __init__(self, text, date):
        self.text = text
        self.date = date
        self.links = []
    def append_link(self, link):
        self.links.append(link)

# Return wiki-titled string.
# Wiki-titling is to make the first letter uppercase.
def wikititle(s):
	return s[0].upper() + s[1:]

warnings = []
def add_warning(str):
    global warnings
    warnings.append(str)

def convert_date(ordinal_date):
    year = int(ordinal_date[0:4])
    month = int(ordinal_date[4:6])
    day = int(ordinal_date[6:8])
    return '%d/%d/%d' % (month, day, year)

def read_dates(dates_filename):
    dates_file = open(dates_filename, 'r')
    dates = simplejson.load(dates_file)
    return dates

def read_texts(texts_filename, dates):
    bullets = {}
    for date in dates:
        bullets[date] = {}
    texts_file = open(texts_filename, 'r')
    for line in texts_file:
        date, index, text = string.split(line, maxsplit=2)
        date = convert_date(date)
        bullets[date][int(index)] = Bullet(text[:-1], date)  # remove the trailing end of line
    return bullets

def read_links(links_filename, bullets):
    links_file = open(links_filename, 'r')
    for line in links_file:
        date, index, link = string.split(line, maxsplit=2)
        date = convert_date(date)
        bullets[date][int(index)].append_link(wikititle(link[:-1])) # remove the trailing end of line
    return bullets

def read_pageviews(filename, dates):
    pageviews = {}
    f = open(filename,'r')
    for line in f:
        json = simplejson.loads(line)
        page = wikititle(json[0])
        counts = json[1]
        pageviews[page] = counts
    return pageviews

def bulletidx(date, index):
    return "%d_%d" % (date2idx[date], index)

def write_for_date(date):
    f = open('wikispark/date_%d.html' % date2idx[date], 'w')
    f.write("""<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>%s</title>
  <!--[if IE]><script language="javascript" type="text/javascript" src="../excanvas.js"></script><![endif]-->
  
  <link rel="stylesheet" type="text/css" href="../jquery.jqplot.css" />
  <link rel="stylesheet" type="text/css" href="examples.css" />
  
  <!-- BEGIN: load jquery -->
  <script language="javascript" type="text/javascript" src="../jquery-1.3.2.min.js"></script>
  <!-- END: load jquery -->
  
  <!-- BEGIN: load jqplot -->
  <script language="javascript" type="text/javascript" src="../jquery.jqplot.js"></script>
  <script language="javascript" type="text/javascript" src="../plugins/jqplot.dateAxisRenderer.js"></script>
  <script language="javascript" type="text/javascript" src="../plugins/jqplot.categoryAxisRenderer.js"></script>
  <!-- END: load jqplot -->
  <style type="text/css" media="screen">
    .jqplot-axis {
      font-size: 0.85em;
    }
    .jqplot-legend {
      font-size: 0.75em;
    }
  </style>
  <script type="text/javascript" language="javascript">
  
  $(document).ready(function(){
""" % date)

    today_links = []
    for index in range(len(bullets[date])):
        bullet = bullets[date][index]
        for link in bullet.links:
            if not link in today_links:
                today_links.append(link)
    
    for link in today_links:
        if not link in pageviews:
            add_warning("the pageview counts for the link %s does not exist" % link)
            continue
        f.write("link%d = %s;\n" % (link2idx[link], simplejson.dumps(pageviews[link])))
        
    f.write('\n')
    for index in range(len(bullets[date])):
        bullet = bullets[date][index]
        definition = "bullet%s = [" % bulletidx(date, index)
        series = "            {label:'%s'},\n" % date

        peak = 0
        for link in bullet.links:
            if not link in pageviews:
                continue
            for d, count in pageviews[link]:
                if count > peak:
                    peak = count
        peak = int((peak + 1) * 1.2)
        
        definition += '[["%s", 0], ["%s", %d], ["%s", 0]]' % (date, date, peak, date)

        for link in bullet.links:
            if not link in pageviews:
                add_warning("the link %s was removed from bullet%s because the pageview counts for it does not exist" % (link, bulletidx(date, index)))
                continue
            definition += ", link%d" % link2idx[link]
            series += "            {label:'%s'},\n" % link
        
        definition += "];\n"
        f.write(definition)
        
        f.write("""plot%s = $.jqplot('chart%s', bullet%s, {
  legend: {show:true, location: 'nw', yoffset: 6},
  axes:{
    xaxis:{
      renderer:$.jqplot.DateAxisRenderer, 
      tickOptions:{
        formatString:'%%m/%%y'}, 
    },
    yaxis:{
    min:0,
    }
  },
  series:[
%s         ]
});

""" % (bulletidx(date, index), bulletidx(date, index), bulletidx(date, index), series)) 
    f.write("""  });
  </script>
  </head>
  <body>
<?php include "nav.inc"; ?>
""")
    nav_str = ''
    if date2idx[date] > 0:
        prev_idx = date2idx[date] - 1
        nav_str += '<a href="date_%d.html">The previous day: %s</a><br>\n' % (prev_idx, dates[prev_idx])
    if date2idx[date] < len(date2idx) - 1:
        next_idx = date2idx[date] + 1
        nav_str += '<a href="date_%d.html">The next day: %s</a><br>\n' % (next_idx, dates[next_idx])
        
    f.write(nav_str)
    for index in range(len(bullets[date])):
        bullet = bullets[date][index]
        text = bullet.text
        f.write('    <p>%s %s %s<br>\n' % (date, index, text))
        for link in bullet.links:
            f.write('    <a href="link_%d.html">%s</a><br>' % (link2idx[link], link))
        f.write('    <div id="chart%s" style="margin-top:20px; margin-left:20px; width:800px; height:400px;"></div></p>' % (bulletidx(date, index)))
        f.write(nav_str)
    f.write("""
  </body>
</html>
""")

def write_for_link(link):
    f = open('wikispark/link_%d.html' % link2idx[link], 'w')
    f.write("""<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>%s</title>
  <!--[if IE]><script language="javascript" type="text/javascript" src="../excanvas.js"></script><![endif]-->
  
  <link rel="stylesheet" type="text/css" href="../jquery.jqplot.css" />
  <link rel="stylesheet" type="text/css" href="examples.css" />
  
  <!-- BEGIN: load jquery -->
  <script language="javascript" type="text/javascript" src="../jquery-1.3.2.min.js"></script>
  <!-- END: load jquery -->
  
  <!-- BEGIN: load jqplot -->
  <script language="javascript" type="text/javascript" src="../jquery.jqplot.js"></script>
  <script language="javascript" type="text/javascript" src="../plugins/jqplot.dateAxisRenderer.js"></script>
  <script language="javascript" type="text/javascript" src="../plugins/jqplot.categoryAxisRenderer.js"></script>
  <!-- END: load jqplot -->
  <style type="text/css" media="screen">
    .jqplot-axis {
      font-size: 0.85em;
    }
    .jqplot-legend {
      font-size: 0.75em;
    }
  </style>
  <script type="text/javascript" language="javascript">
  
  $(document).ready(function(){
""" % link)

    if not link in pageviews:
        add_warning("the pageview counts for the link %s does not exist" % link)
    else:
        f.write("link%d = %s;\n" % (link2idx[link], simplejson.dumps(pageviews[link])))
    f.write('\n')

    definition = "linkevent%d = [[" % (link2idx[link])
    series = "            {label:'Current Events'},\n"
    
    peak = 0    
    if link in pageviews:
        series += "            {label:'%s'},\n" % link
        for d, count in pageviews[link]:
            if count > peak:
                peak = count
    peak = int((peak + 1) * 1.2)

    for pair in link2dates[link]:
        date = pair[0]
        definition += '["%s", 0], ["%s", %d], ["%s", 0], ' % (date, date, peak, date)
    
    definition += ']'
    if link in pageviews:        
        definition += ", link%d" % (link2idx[link])
    definition += "];\n"        
    f.write(definition)
        
    f.write("""linkplot%d = $.jqplot('linkchart%d', linkevent%d, {
  legend: {show:true, location: 'nw', yoffset: 6},
  axes:{
    xaxis:{
      renderer:$.jqplot.DateAxisRenderer, 
      tickOptions:{
        formatString:'%%m/%%y'}, 
    },
    yaxis:{
    min:0,
    }
  },
  series:[
%s         ]
});
  });
""" % (link2idx[link], link2idx[link], link2idx[link], series)) 
    f.write("""
  </script>
  </head>
  <body>
<?php include "nav.inc"; ?>
""")
    
    f.write('    <p>%s<br>\n' % (link))
    for pair in link2dates[link]:
        date = pair[0]
        text = pair[1]
        f.write('    <a href="date_%d.html">%s %s</a><br>\n' % (date2idx[date], date, text))
    f.write('    <div id="linkchart%d" style="margin-top:20px; margin-left:20px; width:800px; height:400px;"></div></p>' % (link2idx[link]))
    f.write("""
  </body>
</html>
""")

def write_index():
    f = open('wikispark/index.html', 'w')
    f.write("""<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">

<html lang="en">
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <title>Wikispark Index</title>
  </head>
  <body>
  
""")
    for i, date in enumerate(dates):
        f.write('<a href="date_%d.html">%s</a><br>\n' % (i, date))
    f.write("""
  </body>
</html>

<!--
Simple statistics

# of link: %d

Warnings

""" % (len(links)))
    for warning in warnings:
        f.write(warning + "\n")
    f.write("-->\n")

# the start of the main
#
# read in the data
if len(sys.argv) < 5:
	sys.stderr.writelines(["usage: wikipyspark [dates] [text] [links] [page_views]\n"])
	sys.exit(1)
else:
    dates = read_dates(sys.argv[1])
    bullets = read_texts(sys.argv[2], dates)
    bullets = read_links(sys.argv[3], bullets)
    pageviews = read_pageviews(sys.argv[4], dates)

# set the maps to facilitate the process.
#
# date2idx: convert date into a serial number
# link2idx: convert each link to a serial number
# links: the list of links, sorted by the link2idx
# link2dates: the list of the dates on which each link appears in the current events

date2idx = {}
for i, date in enumerate(dates):
    date2idx[date] = i
link2idx = {}
links = []
link2dates = {}

for date in dates:
    for index in range(len(bullets[date])):
        bullet = bullets[date][index]
        for link in bullet.links:
            if not link in link2idx:
                link2idx[link] = len(links)
                links.append(link)
            if not link in link2dates:
                link2dates[link] = []
            link2dates[link].append((date, bullet.text))

try:
    os.makedirs("wikispark")
except:
    pass

for date in dates:
    write_for_date(date)
for link in links:
    write_for_link(link)
write_index()

