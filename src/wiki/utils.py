#!/usr/bin/env python
"""
utils.py

Taken from trendingtopics scripts.
Check out http://github.com/datawrangling/trendingtopics
"""
import gzip
import sys
import re
import urllib
import unicodedata

from htmlentitydefs import name2codepoint
name2codepoint['#39'] = 39

def unescape(s):
    "unescape HTML code refs; c.f. http://wiki.python.org/moin/EscapingHtml"
    return re.sub('&(%s);' % '|'.join(name2codepoint),
                  lambda m: unichr(name2codepoint[m.group(1)]), s)

# Extract titles
wikistats_regex = re.compile('(.*) (.*) ([0-9].*)')

# Excludes pages outside of namespace 0 (ns0)
namespace_titles_regex = re.compile('(Media|Special' +
'|Talk|User|User_talk|Project|Project_talk|File' +
'|File_talk|MediaWiki|MediaWiki_talk|Template' +
'|Template_talk|Help|Help_talk|Category' +
'|Category_talk|Portal|Wikipedia|Wikipedia_talk|P|N)\:(.*)')

# More exclusion
image_file_regex = re.compile('(.*)\.(jpg|gif|png|JPG|GIF|PNG|txt|ico)$')

# Exclude Mediawiki boilerplate
blacklist = [
#'404_error/',
'Main_Page',
#'Hypertext_Transfer_Protocol',
#'Favicon.ico',
#'Search',
#'index.html',
#'Wiki'
]

def clean_anchors(page):
    # pages like Facebook#Website really are "Facebook",
    # ignore/strip anything starting at # from pagename
    anchor = page.find('#')
    if anchor > -1:
        page = page[0:anchor]
    return page

def is_valid_title(title):
    """
    Get a title and return if it is a valid title for a Wikipedia page
    """
    if not title:
        False
    is_outside_namespace_zero = namespace_titles_regex.match(title)
    if is_outside_namespace_zero:
        return False
    is_image_file = image_file_regex.match(title)
    if is_image_file:
        return False    
    has_spaces = title.find(' ')
    if has_spaces > -1:
        return False
    if title in blacklist:
        return False
    return True

def normalize_title(title):
    """
    Get a title and return its normalized form
    """
    if not is_valid_title(title):
        return title
    title = urllib.unquote(title).strip().replace(' ','_').strip('_')
    title = clean_anchors(title)
    # cleaning achors should be placed after unquoting,
    # because #s (anchor) are sometimes quoted as %23.
    title = title.decode('utf8')
    title = unicodedata.normalize("NFC", title)
    title = title[0].upper() + title[1:]
    title = title.encode('utf8')
    title = urllib.quote(title)
    # title is converted into url-quoted NFC form
    if not redirects:
        return title
    flag = {}
    while title in redirects:
        title = redirects[title]
        if title in flag:
            return title
        flag[title] = True
    return title

def is_title_in_ns0(title):
    """
    Return if the given title is in ns0.
    Return is_valid_title(title) if it can't be known.
    """
    if not all_titles:
        return is_valid_title(title)
    title = urllib.quote(get_nfc(title))
    return title in all_titles

non_redirects = {}
redirects = {}
all_titles = {}

def get_nfc(string):
    return unicodedata.normalize("NFC",string.decode('utf8')).encode('utf8')

def read_non_redirects(filename):
    f = open(filename, 'r')
    for line in f:
        title = urllib.quote(get_nfc(line.strip()))
        non_redirects[title] = True

def read_redirects(filename):
    f = open(filename, 'r')
    for line in f:
        fields = line.strip().split()
        redirect_from = urllib.quote(get_nfc(fields[0]))
        redirect_to = urllib.quote(get_nfc(fields[1]))
        if redirect_from != redirect_to and redirects.get(redirect_to, '') != redirect_from:
            redirects[redirect_from] = redirect_to

def read_all_titles_in_ns0(filename):
    f = open(filename, 'r')
    for line in f:
        title = urllib.quote(get_nfc(line.strip()))
        all_titles[title] = True
