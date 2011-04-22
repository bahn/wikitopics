Wednesday, December 1st, 2010. Rearrange the data directory structure. Made a directory called data and put all the wikistats file into the wikistats directory under data (data/wikistats). The data moved include Amazon Public Wikipedia Traffic Statistics Dataset, the files received from Shutz, and the files downloaded from Mituzas's archive. Details are explained in data/wikistats/README.

Accidentally deleted the README file from Amazon public dataset. The text file included the format of the dataset, and the original announcement by Tomas Mituzas. Probably the file is available for retrieving at AWS.

Bugs
----
The topic for 2009-10-23 has a decrease in pageviews:
    IPsec 2009-10-23 -473592 494507 20915

Topics
------

Note that the pagecounts data for October 15th, 2009 (pagecounts-20091015.gz) is not included in this dataset.

Wikistats file
==============

These data are originally publicized by Domas Mituzas.
Refer to http://dom.as/2007/12/10/wikipedia-page-counters/.

These are the files that are downloaded from http://dammit.lt/wikistats/archive
/2009/10-12
/2010/01-11

These are the files that are downloaded from http://lausanne.isb-sib.ch/~schutz/wikistats/some_files (now not available)
Note that projectcounts files are not included.

/2007/12
/2008/01-10
/2009/05-09

These are the files that are downloaded from Amazon Wikipedia Traffic Statistics Dataset.
Refer to http://aws.amazon.com/datasets/2596?_encoding=UTF8&jiveRedirect=1.

/2008/10-12
/2009/01-04

Errors in stats
---------------
There are some files that are seemingly cut in the middle of file transfer.
However, those files are the same as the original stats that Frédéric Schütz and Tomas Mituzas have.
These files are located in the separate directory (data/wikistats/archive/errors) to facilitate script running; The bad stats tend to crash scripts!

Some basic stuff about the data:
--------------------------------

The data are in very trivial format, which is projectname, pagename, pageviews, and bytes (of the article).

If there are two hourly statistics for the same hour, only 1 minute apart:
they are duplicates.

2009/05/pagecounts-20090511-070001.gz 2009/05/pagecounts-20090511-070000.gz are almost the same, but still different

Redundant files:
gunzip -c 2009/05/pagecounts-20090512-000000.gz > fred
gunzip -c 2009/05/pagecounts-20090512-010000.gz > foo
gunzip -c 2009/05/pagecounts-20090512-010001.gz > bar
gunzip -c 2009/05/pagecounts-20090512-020000.gz > baz
diff foo bar > qux
Turned out foo has a field that does not appear in fred bar and baz, which supports bar missing somethings.
Turned out foo and bar mostly overlap, which means one of them should be discarded.
Turned out foo's field has the page view equal to or greater than that of bar's field.


Redirects
=========

extracting redirects data from wikidump.
this work was done on July 9, 2010.

There are many redirection pages in Wikipedia. In Wikistats files, each record has pagetitle as it was input by the user whether there is a typo or a redirection.

To correctly get the page views for each Wikipedia article, one needs to adjust the wikistats using the redirects data. Redirects page in Wikipedia are the pages that automatically redirect users to another Wikipedia page. There could be more than one-step redirects: one redirect page links to another redirect page, which in turn links to another redirect page, and repeat so until a redirect page links to a non-redirect page.

Wikimedia dumps the whole Wikipedia database periodically, and the database includes information about the title pages, and the redirect pages. The goal is to process this database in SQL formrat to produce the list of redirect pages and non-redirect pages in plain text.

Scripts
=======
sql2txt.py
    the main script to produce database dumps to generate redirect data.
cut.py
    a tentative script to cut the database dump files easy to see.

Usage
=====
sql2txt.py [page db dump] [redirect db dump]

Output files
============
redirects.txt
    contains the redirect pages one in a line, followed by the target page.
non_redirects.txt
    contains the list of non-redirect pages one in a line.

These files were put at the same place as the input files. (data/wikidump/enwiki-20100622)

Notes
=====
Note that the Wikipedia database dumps are now available in gzipped sql format. The script are feeded with ungzipped plain text files in SQL. Later, the script was changed to deal with gzipped files on December 1st, 2010. However, it was not test on the real gzipped input files yet. It is expected that the script takes much more time to process the gzipped files than it would take to process ungzipped files.

