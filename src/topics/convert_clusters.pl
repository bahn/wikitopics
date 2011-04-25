#!/usr/bin/env perl

use URI::Escape;

die "convert_clusters.pl CLUSTER_FILE [SENTENCE_DIR1 [SENTENCE_DIR2] ...]" if scalar(@ARGV) < 1;

$CLUSTER_FILE="$ARGV[0]";
shift @ARGV;

foreach $dir (@ARGV) {
	if (! -d $dir) {
		print STDERR "$dir not exist\n";
	} else {
		push @SENTENCE_DIRS, $dir;
	}
}

sub print_cluster {
	if (scalar(@CLUSTER) == 0) {
		return;
	}

	print "<h1>Cluster</h1>\n";

	print "<p>\n";
	foreach $page (@CLUSTER) {
		print "$page<br>\n";
	}
	print "</p>\n";

	foreach $dir (@SENTENCE_DIRS) {
		$dir =~ /\/sentences\/([^\/]+)\//;
		print "<h2>" . ucfirst $1 . "</h2>\n";
		print "<p>\n";
		foreach $page (@CLUSTER) {
			$filename = uri_escape($page, "^A-Za-z0-9\-\._~\%");
			$filename =~ s/^\./\%2E/;
			open SENT_FILE, "<$dir/$filename.sentences";
			while (<SENT_FILE>) {
				chomp;
				s/^\d+ //;
				print "$_<br>\n";
			}
			close SENT_FILE;
		}
		print "</p>\n";
	}

	@CLUSTER=();
	return;
}

@CLUSTER=();

open FILE, "<$CLUSTER_FILE";
while (<FILE>) {
	chomp;
	s/#.*$//;
	s/\s+$//;

	if (/^$/) {
		print_cluster;
	} else {
		push @CLUSTER, $_;
	}
}
close FILE;

print_cluster;
