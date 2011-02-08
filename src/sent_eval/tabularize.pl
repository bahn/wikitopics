#!/usr/bin/env perl
#
# tabularize.pl
#
# convert the results of eval_sents.py script into a tabularized form.

$phase = 0;
while (<>) {
    if (/^([^ ]*) evaluated against ([^ ]*)$/) {
        $test_set = $1;
        $gold_set = $2;
        chomp $gold_set;
        $phase = 1;
    } elsif (/^p = [^0-9.]* ([0-9.]*)$/) {
        $precision = $1;
    } elsif (/^r = [^0-9.]* ([0-9.]*)$/) {
        $recall = $1;
    } elsif (/^f = 2pr [^0-9.]* ([0-9.]*)$/) {
        $f1 = $1;
        if ($phase == 1) {
            $best_p = $precision;
            $best_r = $recall;
            $best_f = $f1;
            $phase++;
        } elsif ($phase == 2) {
            $second_p = $precision;
            $second_r = $recall;
            $second_f = $f1;

            printf "%s\t%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n", $test_set, $gold_set, $best_p, $best_r, $best_f, $second_p, $second_r, $second_f;
            $phase = 0;
        } else {
            $phase = 0;
        }
    }
}
