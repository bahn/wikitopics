#!/usr/bin/env python
#
# cluster_mturk.py
#
# Read the mechanical turk result in csv format
# and build clusters

import sys
import xml
import csv
import gzip
import re

def unicode_csv_reader(unicode_csv_data, dialect=csv.excel, **kwargs):
	# Borrowed from Python v.2.6.5 Documentation >> ... >> 13.1 csv
	# csv.py doesn't do Unicode; encode temporarily as UTF-8:
	csv_reader = csv.reader(unicode_csv_data,
							dialect=dialect, **kwargs)
	for row in csv_reader:
		# decode UTF-8 back to Unicode, cell by cell:
		yield [unicode(cell, 'utf-8') for cell in row]


class MturkClustering:
	def __init__(self):
		self.articles = []
		self.links = {}
		self.visited = {}
	def printConnectedComponents(self, threshold):
		self.visited = {}
		for article in self.articles:
			self.visited[article] = False
		for article in self.articles:
			if not self.visited[article]:
				self.visit(article, threshold)
				print
	def visit(self, v, threshold):
		self.visited[v] = True
		print v.encode('utf-8')
		for u in self.articles:
			if self.visited[u]:
				continue
			key = v+'/'+u
			if key in self.links and self.links[key] >= threshold:
				self.visit(u, threshold)
	def printInCsv(self, file):
		r = re.compile(r',')
		sub = '&#44;'
		max_links = 0
		for link in self.links.values():
			if max_links < link:
				max_links = link
		file.write('Topic')
		for v in self.articles:
			file.write(','+r.sub(sub, v).encode('utf-8'))
		file.write('\n')
		for v in self.articles:
			file.write(r.sub(sub, v).encode('utf-8'))
			for u in self.articles:
				if v == u:
					file.write(','+str(max_links))
				else:
					key = v+'/'+u
					if key not in self.links:
						file.write(',0')
					else:
						file.write(','+str(self.links[v+'/'+u]))
			file.write('\n')
	def printInMallet(self, file):
		max_links = 0
		for link in self.links.values():
			if max_links < link:
				max_links = link
		for v in self.articles:
			file.write(v.encode('utf-8') + '\t\t')
			for u in self.articles:
				if v == u:
					for i in range(3):
						file.write(u.encode('utf-8') + ' ')
				else:
					key = v+'/'+u
					if key in self.links:
						file.write(u.encode('utf-8') + ' ')
			file.write('\n')



def read_mturk_clustering(csv_filename):
	# e.g. ',' (comma)
	re1 = re.compile(r'&#44;')
	file = gzip.open(csv_filename, 'r')
	data = unicode_csv_reader(file)
	row = data.next()
	headers = [col for col in row]
	articles_1 = [headers.index('Input.article_1_%d' % i) for i in range(20)]
	articles_2 = [headers.index('Input.article_2_%d' % i) for i in range(20)]
	relateds = [headers.index('Answer.related_%d' % i) for i in range(20)]
	articles = {}
	links = {}
	for row in data:
		for i in range(20):
			article_1 = row[articles_1[i]]
			article_2 = row[articles_2[i]]
			related = row[relateds[i]]
			if not article_1 or not article_2:
				break

			# normalize strings
			article_1 = re1.sub(r',', article_1)
			article_2 = re1.sub(r',', article_2)

			if article_1 not in articles:
				articles[article_1] = 1
			if article_2 not in articles:
				articles[article_2] = 1
			if related == 'yes':
				key = article_1+'/'+article_2
				key2 = article_2+'/'+article_1
				if key not in links:
					links[key] = 1
				else:
					links[key] += 1
				if key2 not in links:
					links[key2] = 1
				else:
					links[key2] += 1
	clustering = MturkClustering()
	clustering.articles = articles.keys()
	clustering.articles.sort()
	clustering.links = links
	return clustering



if __name__=='__main__':
	if len(sys.argv) != 3 or int(sys.argv[2])<1 or int(sys.argv[2])>3:
		print "Usage: cluster_mturk.py /path/to/csv/file [threshold]"
		sys.exit(1)
	clustering = read_mturk_clustering(sys.argv[1])
	clustering.printConnectedComponents(int(sys.argv[2]))
