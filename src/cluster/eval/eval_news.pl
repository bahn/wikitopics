#!/usr/bin/env perl

print "1\n";
for ($i = 10; $i <=200; $i+=10) {
    print "$i";
    for ($j = 1; $j <= 15; $j++) {
        last unless (-e "../../../data/clusters/kmeans-news/kmeans-$i-$j");
        $flag[$i][$j] = 1;
        $result=`./eval_kmeans.sh -news/kmeans-$i-$j | ./tabularize.pl | tail -1`;
        @words = $result =~ m/\S+/g;
        print "\t$words[1]";
        for ($k = 2; $k <6; $k++) {
            $num[$i][$j][$k] = $words[$k];
        }
    }
    print "\n";
}

for ($k = 2; $k < 6; $k++) {
    print "$k\n";
    for ($i = 10; $i <=200; $i+=10) {
        print "$i";
        for ($j = 1; $j <= 15; $j++) {
            last unless ($flag[$i][$j]);
            print "\t$num[$i][$j][$k]";
        }
        print "\n";
    }
}
