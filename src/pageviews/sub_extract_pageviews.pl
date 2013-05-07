#!/usr/bin/env perl

use Env qw(HOSTNAME);
use URI::Escape;

# check the command-line arguments
#print "$HOSTNAME\$ $0 @ARGV\n";
die "usage: $0 LIST_FILE [DATE]" if (scalar @ARGV < 1 or scalar @ARGV > 2);

%titles = ();
$last_title = "";

open FILE, "<$ARGV[0]" or die "failed opening $ARGV[0]: $!";
while (<FILE>) {
	chomp;
	$titles{uri_unescape($_)} = 1;
}
close FILE;

$date = 'unknown_date';
if ($#ARGV >= 1) {
	$date = $ARGV[1];
}

# main body
%printed = ();
while (<STDIN>) {
	@fields = split;
	if ($#fields >= 1) {
		$title = $fields[1];
		$title =~ s/#.*$//;
		if ($title eq "") {
			next;
		}
		$title = uri_unescape($title);

		if (exists $titles{$title}) {
			$printed{$title} = 1;
			print "$date\t$title\t$fields[2]\t$fields[1]\n";
		}
	}
}

#foreach $title (keys %titles) {
#	if (!$printed{$title}) {
#		print "$date\t$title\t0\n";
#	}
#}
