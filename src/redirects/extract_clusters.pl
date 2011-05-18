#!/usr/bin/env perl

while (<>) {
	if (/http:\/\/([a-z]+)\.wikipedia\.org\/wiki\/([^\"]+)\" target=\"view\">([^<]+)[^\d]+(\d+)/) {
		$lang = $1;
		$escaped_title = $2;
		$title = $3;
		$score = $4;
	} elsif (/View Then/) {
		/oldid=(\d+)/;
		$thenid = $1;
	} elsif (/View Prior/) {
		/oldid=(\d+)/;
		$priorid = $1;
		$title =~ s/ +$//;
		$title =~ s/ /_/g;
		print "$lang $title $score $thenid $priorid\n";
	}
}
