#!/usr/bin/env perl

while (<>) {
    chomp;
    if (/^pagecounts-([0-9]*)\.gz/) {
        $date = $1;
        $num = 0;
    } elsif (/^(.*)\t[0-9]*$/) {
        $topic = $1;
        print "$date $num $topic\n";
        $num += 1;
    }
}