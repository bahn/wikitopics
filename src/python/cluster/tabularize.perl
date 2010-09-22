#!/usr/bin/env perl
#
# convert the output format of the evaluation scripts
# into a tabularized form

while (<>) {
    chomp;
    $line = $_;
    if (/^gold standard/) {
	/clusters-([^\/]+)\/.+(\d{4})/;
	$gold = $1;
	$date = $2;
    }
    if (/^clustering/) {
	/clusters-([^\/]+)\/.+(\d{4})/;
	$algo = $1;
	$confirm_date = $2;
	die if ($date ne $confirm_date);
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
