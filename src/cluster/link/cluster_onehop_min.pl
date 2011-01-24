#!/usr/bin/env perl
#
# cluster_onehop.pl
# -----------------
# The script to cluster articles using the link structure.
# It needs the title file and the links file to be in the same directory.
# You need to make soft links to the files if you do not have them.
# If you do not have the files, try something like this:
# 	$ ln -s ../../data/wikilinks/links-simple-sorted.txt
# 	$ ln -s ../../data/wikilinks/titles-sorted.txt
# 
# Usage: cluster_using_links.pl article_list
# 	article_list
# 		the file that includes the list of articles.

use strict;
use warnings;
my $article_file;
my $title_file;
my $link_file;

my %pagetitle;
my %pageno;

my %new_articles;
my %new_pagenos;
my %edges;
my %next_new_pagenos;

my %mark;

# Print all the nodes in a node's connected component.
# Only count the directly connected articles.
# For example, if some articles are connected by
# an article that are not in cluster, they are not printed.
# They are counted as two hops.

sub visit {
	my ($v) = @_;
	#our %pagetitle;
	#our %mark;
	#our %edges;
	if (!exists $pagetitle{$v} || exists $mark{$v}) {
		return;
	}
	$mark{$v} = 1;
	print "$pagetitle{$v}\n";

	my $u;
	for $u (keys %{ $edges{$v} }) {
		visit($u);
	}
}

sub visit_local {
	my ($v) = @_;
	$mark{$v} = 1;
	print "$pagetitle{$v}\n";

	my $u;
	for $u (keys %{ $edges{$v} }) {
		if ($v==$u || !exists $pagetitle{$u}) {
			next;
		}
		$mark{$u} = 1;
		print "$pagetitle{$u}\n";
	}
}

die "Usage: cluster_using_links.pl article_list" if ($#ARGV == -1);

$article_file = $ARGV[0];
$title_file = 'titles-sorted.txt';
$link_file = 'links-simple-sorted.txt';

%pagetitle = (); # map no to title
%pageno = (); # map title to no

%new_articles = (); # all the articles to cluster. the variable name is misleading.
%new_pagenos = ();
%next_new_pagenos = ();
%edges = ();

open ARTICLE, $article_file or die "failed to open $article_file";
while (<ARTICLE>) {
	chop;
	$new_articles{$_} = 1;
}
close ARTICLE;

open TITLE, $title_file or die "failed to open $title_file";
while (<TITLE>) {
	chop;
	if (exists $new_articles{ $_ }) {
		$pagetitle{ $. } = $_;
		$pageno{ $_ } = $.;
		$new_pagenos{ $. } = 1;
	}
}
close TITLE;

open LINK, $link_file or die "failed to open $link_file";
while (<LINK>) {
	my @f = split/:/;
	if (exists $new_pagenos{ $f[0] }) {
		delete $new_pagenos{ $f[0] };
		$edges{ $f[0] } = {};
		$_ = $f[1];
		chop;
		my @nos = split;
		foreach ( @nos ) {
			$edges{ $f[0] }->{ $_ } = 1;
			if (!exists $edges{ $_ }) {
				$next_new_pagenos{ $_ } = 1;
			}
		}
	}
}
close LINK;

my $v;
my $u;
foreach $v (keys %edges) {
	foreach $u (keys %{ $edges{$v} }) {
		$edges{$u}->{$v} = 1;
	}
}

%mark = ();

my @sorted_title;
@sorted_title = ();
@sorted_title = sort { scalar(keys %{$edges{$a}}) <=> scalar(keys %{$edges{$b}}) } keys %pagetitle;

foreach ( @sorted_title ) {
	if (!exists $mark{$_}) {
		visit_local($_);
		print "\n";
	}
}

if (scalar(keys %pagetitle) != scalar(keys %new_articles)) {
	print "# The following articles are new and not found in the link structure as of 28-01-2009.\n";
	foreach ( keys %new_articles ) {
		if (!exists $pageno{$_}) {
			print "$_\n\n";
			next;
		}
	}
}
