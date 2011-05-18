#!/usr/bin/env perl
#
# tabularize.pl
#
# convert the results of eval_sents.py script into a tabularized form.

$phase = 0;

$p1 = $p2 = $r1 = $r2 = $f1 = $f2 = $num = 0;
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
        $f = $1;
        if ($phase == 1) {
            $best_p = $precision;
            $best_r = $recall;
            $best_f = $f;
            $phase++;
        } elsif ($phase == 2) {
            $second_p = $precision;
            $second_r = $recall;
            $second_f = $f;

            printf "%s\t%s\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n", $test_set, $gold_set, $best_p, $best_r, $best_f, $second_p, $second_r, $second_f;
			$p1 += $best_p; $r1 += $best_r; $f1 += $best_f;
			$p2 += $second_p; $r2 += $second_r; $f2 += $second_f;
			$num += 1;
            $phase = 0;
        } else {
            $phase = 0;
        }
    }
}

if ($num) {
	$p1 /= $num; $r1 /= $num; $f1 /= $num;
	$p2 /= $num; $r2 /= $num; $f2 /= $num;
}
printf "\t\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\n", $p1, $r1, $f1, $p2, $r2, $f2;
