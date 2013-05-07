#!/usr/bin/env perl

use File::Basename;
use File::Path;
use Pageviews;

# check the command-line arguments
print "$HOSTNAME\$ $0 @ARGV\n";
if (scalar @ARGV < 2) {
	die "$0 INPUT_FILE OUTPUT_FILE [LIST_FILE]";
}

$INPUTFILE=$ARGV[0];
$OUTPUTFILE=$ARGV[1];

if ($#ARGV >= 2) {
	$list_file = $ARGV[2];
	open FILE, "<$list_file" or die "failed opening $LIST_FILE: $!";
	%filenames = ();
	while (<FILE>) {
		chomp;
		$filenames{title_to_filename($_)} = 1;
	}
	$filename = basename($INPUTFILE);
	die "skipping $title since it is not in the list..." unless (exists $filenames{$filename});
}

%dailysum = ();
%checked = ();
open FILE, "<$INPUTFILE" or die "failed opening $INPUTFILE: $!";
if (!-e dirname($OUTPUTFILE)) {
	make_path(dirname($OUTPUTFILE)) or die "failed making the directory " . dirname($OUTPUTFILE) . ": $!";
}
open OUTFILE, ">$OUTPUTFILE" or die "failed opening $OUTPUTFILE: $!";
while (<FILE>) {
	if (/^([0-9]*)-([0-9][0-9])([0-9]*)\t([0-9]*)$/) {
		$dailysum{$1} += $4;
		if (exists $checked{"$1-$2"}) {
			if ($checked{"$1-$2"}[1] != $4) {
				print "mismatch for $1-$2\n";
				@temp = @{$checked{"$1-$2"}};
				print "@temp\n";
				print "$1-$2$3 $4\n";
			}
		} else {
			$checked{"$1-$2"} = ["$1-$2$3", $4];
		}
	}
}
close FILE;

foreach $date (sort keys %dailysum) {
	print OUTFILE "$date $dailysum{$date}\n";
}
close OUTFILE;
