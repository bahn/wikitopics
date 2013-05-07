#!/usr/bin/env perl
use strict;
use warnings;
use IO::File;
use File::Basename;
use URI::Escape;
use Env qw(HOSTNAME);

#print STDERR "$HOSTNAME\$ $0\n";

my @files=sort @ARGV;
my %fh=();
my %line=();

#print STDERR "merging the files below...\n";
foreach my $file (@files) {
	#print STDERR "   $file\n";
	my $fh = $fh{$file} = IO::File->new("<$file");
	my $line = $line{$file} = <$fh>;
}

while (1) {
# find the next title to print
	my $current_title = "";
	foreach my $file (@files) {
		my $line = $line{$file};
		if (!defined $line or $line eq "") {
			next;
		}
		my @fields = split ' ', $line;
		my $title = $fields[1];
		if (!defined $title or $title eq "") {
			next;
		}
		if ($current_title eq "" or $current_title gt $title) {
			$current_title = $title;
		}
	}

	if ($current_title eq "") {
		last;
	}

# print pageviews for the title
	foreach my $file (@files) {
		my $fh = $fh{$file};
		while (1) {
			my $line = $line{$file};
			if (!defined $line or $line eq "") {
				last;
			}
			my @fields = split ' ', $line;
			if ($#fields >= 1) {
				my $title = $fields[1];
				if ($current_title ne $title) {
					last;
				}
			}

			print $line;
			$line{$file} = <$fh>;
		}
	}
}

foreach my $fh (values %fh) {
	$fh->close;
}
