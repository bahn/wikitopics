#!/usr/bin/env perl
# tabularize.perl
#
# the script to tabularize the results of the eval.py script.
#
# Usage:
#	./eval.py gold_standard test_set | ./tabularize.perl

while (<>) {
    chomp;
    $line = $_;
    if (/^gold standard/) {
	# e.g. clusters-bahn/cluster0127.txt
	# clusters-ben/pick0127
	# clusters-ccb/pick0127.clusters-ccb
	/clusters-([^\/]+)\/.+(\d{4})/;
	$gold = $1;
	$date = $2;
    }
    if (/^clustering/) {
	# e.g. clusters-bahn/cluster0127.txt
	# clusters-ben/pick0127
	# clusters-ccb/pick0127.clusters-ccb
	/clusters-([^\/]+)\/.+(\d{4})/;
	$algo = $1;
	$confirm_date = $2;
	die if ($date ne $confirm_date);
	# for cluster threshold: e.g. cluster-mturk.1
	if (/clusters-mturk.(\d)/) {
	    $algo = $algo . $1;
	}
    }
    if (/BCubed/) {
	if (/precision/) {
	    /([\.0-9]+)/;
	    $prec = $1;
	} elsif (/recall/) {
	    /([\.0-9]+)/;
	    $rec = $1;
	} elsif (/F-score/) {
	    /([\.0-9]+)/;
	    $fscore = $1;
	    print "$gold\t$algo\t$date\t";
	    print "$prec\t$rec\t$fscore\n";
	}
    }
}
