#!/usr/bin/env perl

use Digest::MD5 qw(md5_hex);

die "$0 md5sums.txt basename filepath" if (scalar @ARGV < 3);

$md5sum_filename = $ARGV[0];
$filename = $ARGV[1];
$filepath = $ARGV[2];

%md5sums = ();
open FILE, "<", "$md5sum_filename" or die "failed opening md5sums.txt";
while (<FILE>) {
	chomp;
	@fields = split;
	die "the length of fields should be 2, not " . (scalar @fields) unless ((scalar @fields) == 2);
	$md5sums{$fields[1]} = $fields[0];
}
close FILE;

unless (exists $md5sums{$filename}) {
	print "don't know the correct md5 sum of $filename. exiting successfully...";
	exit 0;
}

open FILE, "<$filepath";
binmode FILE;
$md5sum = Digest::MD5->new->addfile(*FILE)->hexdigest;
close FILE;

die "$filename failed the checksum test" if ($md5sum != $md5sums{$filename});
