#!/usr/bin/env perl
# tabularize.perl
# WARNING
#    revised to work for automatic clustering.
#    might not work for the previous ones.
#
# the script to tabularize the results of the eval.py script.
#
# Usage:
#        ./eval.py gold_standard test_set | ./tabularize.perl

$num_rows = 0;
$sum_g = 0;
$sum_t = 0;
$sum_p = 0;
$sum_r = 0;
$sum_f = 0;

sub summary {
    if ($num_rows > 0) {
        $sum_g /= $num_rows;
        $sum_t /= $num_rows;
        $sum_p /= $num_rows;
        $sum_r /= $num_rows;
        $sum_f /= $num_rows;
        printf "\t$old_algo\t\t%.1f\t%.1f\t%.4f\t%.4f\t%.4f\n", $sum_g, $sum_t, $sum_p, $sum_r, $sum_f;
        $sum_g = $sum_t = $sum_p = $sum_r = $sum_f = 0;
        $num_rows = 0;
    }
}

while (<>) {
    chomp;
    $line = $_;
    if (/^gold standard/) {
        # e.g. clusters-bahn/cluster0127.txt
        # clusters-ben/pick0127
        # clusters-ccb/pick0127.clusters-ccb
        if (/clusters-([^\/]+)\/.+(\d{4})/) {
            $gold = $1;
            $date = $2;
        } elsif (/clusters\/([^\/]+)\/.+(\d{4})/) {
            $gold = $1;
            $date = $2;
        }
    }
    if (/^clustering/) {
        # e.g. clusters-bahn/cluster0127.txt
        # clusters-ben/pick0127
        # clusters-ccb/pick0127.clusters-ccb
        $old_algo = $algo;
        if (/clusters-([^\/]+)\/.+(\d{4})/) {
            $algo = $1;
            $confirm_date = $2;
        } elsif (/clusters\/([^\/]+)\/([-0-9]+).clusters/) {
            # e.g. clusters/auto-onehop/2009-01-27.clusters
            $algo = $1;
            $confirm_date = $2;
            $confirm_date =~ s/[0-9]{4}-([0-9]{2})-([0-9]{2})/\1\2/;
        } elsif (/clusters\/([^\/]+)\/.+(\d{4})/) {
            $algo = $1;
            $confirm_date = $2;
        } else {
            print "$_\n";
        }
        die "Dates don't match: $date and $confirm_date" if ($date ne $confirm_date);
        # for cluster threshold: e.g. cluster-mturk.1
        if (/clusters-mturk.(\d)/) {
            $algo = $algo . $1;
        }
        if (defined($old_algo) && $old_algo ne $algo) {
            summary();
        }
    }
    if (/clusters of/) {
        if (/gold standard: (\d*)/) {
            $gold_num = $1;
        } elsif (/test set: (\d*)/) {
            $test_num = $1;
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
            print "$gold\t$algo\t$date\t$gold_num\t$test_num\t";
            print "$prec\t$rec\t$fscore\n";
            $sum_g += $gold_num;
            $sum_t += $test_num;
            $sum_p += $prec;
            $sum_r += $rec;
            $sum_f += $fscore;
            $num_rows++;
        }
    }
}
summary();
