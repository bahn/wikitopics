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

	foreach $page (@CLUSTER) {
		$page =~ s/_/ /g;
	}
	$cluster_title = join(", ", @CLUSTER);
	print '<h3><a href="#">' . $cluster_title . '</a></h3>' . "\n";

	print "<div>\n";
	print "\t<table>\n";
	print "\t\t<tr><th>Article</th>";
	foreach $dir (@SENTENCE_DIRS) {
		$dir =~ /\/sentences\/([^\/]+)\//;
		print "<th>" . ucfirst $1 . "</th>";
	}
	print "</tr>\n";
	foreach $page (@CLUSTER) {
		$filename = uri_escape($page, "^A-Za-z0-9\-\. _~\%");
		$filename =~ s/ /_/g;
		$filename =~ s/^\./\%2E/;
		print "\t\t<tr><td>";
		print '<a href="http://en.wikipedia.org/wiki/' . $filename . '" target="view">';
		print "$page</a></td>\n";
		foreach $dir (@SENTENCE_DIRS) {
			$dir =~ /\/sentences\/([^\/]+)\//;
			print "\t\t\t<td><!--" . ucfirst $1 . "-->";

			open SENT_FILE, "<$dir/$filename.sentences";
			while (<SENT_FILE>) {
				chomp;
				s/^\d+ //;
				print "\n\t\t\t$_<br>";
			}
			close SENT_FILE;
			print "</td>\n";
		}
		print "\t\t</tr>\n";
	}
	print "\t</table>\n";
	print "</div>\n";

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
