#!/usr/bin/env perl

use List::Util 'shuffle';

$no_articles = 10;

for ($i=0; $i<$no_articles; $i++) {
	print "article$i,trending_score$i,";
}
print "\n";

@articles = ();

sub print_articles {
	@articles = shuffle(@articles);
	while ($#articles >= 0) {
		for ($i=0; $i<$no_articles && $#articles>=0; $i++) {
			print "$articles[0],";
			shift @articles;
		}
		print "\n";
	}
}

while (<>) {
	chomp;
	s/,/&#44;/g;
	s/ /,/;
	s/&/&amp;/g;
	s/^>/&gt;/g;
	s/^</&lt;/g;
	s/"/&quot;/g;
	s/'/&#39;/g;
	s/_/ /g;
	push @articles, $_;
}

@articles = shuffle(@articles);
print_articles;
