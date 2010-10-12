f = open('enwiki-20100622-redirect.sql','r')

for line in f:
	if len(line) > 100:
		print line[0:100]
		print line[-100:-2]
		break
