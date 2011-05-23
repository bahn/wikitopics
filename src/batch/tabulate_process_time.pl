#!/usr/bin/env perl

use Env qw(HOME);

$DELETE=0;
if ($ARGV[0] eq "--delete") {
	shift @ARGV;
	print "delete log files without an error...\n";
	$DELETE=1;
}

$DIR="$HOME/log/grid";
unless (-d $DIR) {
	die "$0 INPUT_DIR" unless (-d $ARGV[0]);
	$DIR = $ARGV[0];
} elsif (-d $ARGV[0]) {
	$DIR = $ARGV[0];
}

@FILES = glob("$DIR/proc_stats.* $DIR/do_all.* $DIR/proc_stat.* $DIR/do_almost.* $DIR/do_another.*");
print "START DATE\tEND DATE  \tLANG\tSTEP\tTIME\n";
foreach $FILENAME (@FILES) {
	open FILE, $FILENAME;
	$first_error = 1;
	while (<FILE>) {
		if (/^(\w+)\.(sh|py|pl)\s+(\-\S+\s+\S+\s+)?(\S+)\s+(\S+\s+)?([\-\d]+)(\s+([\-\d]+))?$/) {
			$step = $1;
			if ($step eq "add_hourly_stats") {
				$printing_step = "Add Stats";
				$defined_step = 1;
			} elsif ($step eq "redirect_stats") {
				$printing_step = "Redirect Stats";
				$defined_step = 1;
			} elsif ($step eq "list_topics") {
				$printing_step = "List Topics";
				$defined_step = 1;
			} elsif ($step eq "convert_topics") {
				$printing_step = "Resolve RevId";
				$defined_step = 1;
			} elsif ($step eq "kmeans") {
				$printing_step = "K-Means";
				$defined_step = 1;
			} elsif ($step eq "fetch_sentences") {
				$printing_step = "Fetch sents";
				$defined_step = 1;
			} elsif ($step eq "filter_sentences") {
				$printing_step = "Filter sents";
				$defined_step = 1;
			} elsif ($step eq "serif") {
				$printing_step = "Serif";
				$defined_step = 1;
			} elsif ($step eq "pick_sentence") {
				$printing_step = $step;
				$defined_step = 1;
			} elsif ($step eq "convert_clusters") {
				$printing_step = "Gen HTML";
				$defined_step = 1;
			} elsif ($step eq "check_revisions") {
				$printing_step = "Check RevId";
				$defined_step = 1;
			} elsif ($step eq "parallelize_serif") {
				$printing_step = "Parallelize";
				$defined_step = 0;
			} else {
				$defined_step = 0;
			}
			if ($defined_step) {
				if (/^(\w+)\.(sh|py|pl)\s+(\S+)\s+([\-\d]+)(\s+([\-\d]+))?$/) { # ko 2011-04-18
					$lang = $3;
					$start_date = $4;
					$end_date = $6;
				} elsif (/^(\w+)\.(sh|py|pl)\s+(\-\S+\s+\S+\s+)(\S+)\s+([\-\d]+)(\s+([\-\d]+))?$/) { # -c 100 ko 2011-04-18
					$lang = $4;
					$start_date = $5;
					$end_date = $7;
				} elsif (/^(\w+)\.(sh|py|pl)\s+(\S+)\s+(\S+)\s+([\-\d]+)(\s+([\-\d]+))?$/) { # ko redirects_file 2011-04-18
					if ($printing_step eq "pick_sentence") {
						$printing_step = ucfirst $4;
					}
					$lang = $3;
					$start_date = $5;
					$end_date = $7;
				}
			}

			$no_time = 0;
			if ($lang) {
				$lang = uc $lang;
			}
			if ($start_date) {
				if ($start_date =~ /^\d+$/) {
					$start_date = substr($start_date, 0, 4) . "-" . substr($start_date, 4, 2) . "-" . substr($start_date, 6, 2);
				}
			}
			unless ($end_date) {
				$end_date = $start_date;
			} elsif ($end_date) {
				if ($end_date =~ /^\d+$/) {
					$end_date = substr($end_date, 0, 4) . "-" . substr($end_date, 4, 2) . "-" . substr($end_date, 6, 2);
				}
			}
			unless ($defined_step) {
				unless ($step =~ /process_stats/ || $step =~ /do_all/) {
					print STDERR;
				}
			}
		} elsif (/real\s+(\d+)m(\d+)\.(\d+)s/) {
			$no_time++;
			if ($step eq "convert_topics" || $step eq "list_topics") {
				if ($no_time == 2) {
					$printing_step = "Subtotal (above 2)";
				} elsif ($no_time == 3) {
					$printing_step = "Total";
				} elsif ($no_time > 3) { # if $no_time != 1
					$defined_step = 0;
				}
			} elsif ($step eq "serif") {
				if ($no_time == 2) {
					$printing_step = "Serif Subtotal";
					$defined_step = 1;
				}
			} elsif ($step eq "do_all") {
				if ($no_time == 1) {
					$printing_step = "Total";
					$defined_step = 1;
				} elsif ($no_time >= 2) {
					$defined_step = 0;
				}
			} elsif ($step eq "parallelize_serif") {
				$printing_step = "Total";
				$defined_step = 1;
			} else {
				if ($no_time == 2) {
					$printing_step = "Total";
				} elsif ($no_time >= 3) {
					$defined_step = 0;
				}
			}
			$min = $1;
			$second = $2;
			$hour = $min/60;
			$min %= 60;
			if ($defined_step) {
				if ($cant_export and ($printing_step eq "Resolve RevId")) {
					printf "$start_date\t$end_date\t$lang\t$printing_step\tN/A\n";
				} else {
					printf "$start_date\t$end_date\t$lang\t$printing_step\t%d:%02d:%02d\n", $hour, $min, $second;
				}
			} else {
				printf "$start_date\t$end_date\t$lang\t%dth printed time from $step\t%02d:%02d:%02d\t$FILENAME\n", $no_time, $hour, $min, $second;
			}
		} elsif (/\/export\/people\/bahn\/wikitopics not found/) {
			$cant_export = 1;
		} else {
			unless (/\w+ \w+ \d+ [:\d]+ \w+ \d+/ || # date and time
				/[\d\-]+ [\d\:]+/ || # date and time in a different format
				/(real|user|sys)\s+\d+m\d+\.\d+s/ || # elapsed time
				/pagecounts-\d+\.gz/ || # pagecounts file name output by list_topics.py
				/convert_topics\.py \S+ \> \S+/ || # commands output by convert_topics.sh
				/convert_topics\.py \S+ \S+ \S+ \> \S+/ || # new output format of commands output by convert_topics.sh
				/Input: \S+/ || # kmeans output
				/Output: \S+/ ||
				/Entering KMeans iteration/ ||
				/KMeans converged with deltaMeans = \S+/ ||
				/moved in last iteration. Saying converged./ ||
				/This is UNIX English Serif for the ACE task/ || # Serif
				/Serif\/generic library version:/ ||
				/Serif\/English library version:/ ||
				/Copyright 2010 by BBN Technologies Corp\./ ||
				/All Rights Reserved\./ ||
				/Initializing Stage \d+/ ||
				/Warning Initializing WordNet from the backup location/ ||
				/Preloading \d+ entries into prob cache/ ||
				/Initializing document-level / ||
				/Processing #\d+: \d+-\d+/ ||
				/Flattening parse for very deep, long sentence./ ||
				/Flattening parse for long sentence with mostly punctuation./ ||
				/Processing #\d+:/ ||
				/\d+-\d\d\d\.\.\./ ||
				/Sognu/ && /Madness of Love/ && /I Can/ && /Taken by a Stranger/ && /Que me quiten lo/ ||
				/style=/ && /text-align : center ;/ ||
				/Session completed with \d+ warning\(s\)\./ ||
				/Check session log for warning messages\./ ||
				/Session log is in:/ ||
				/(\/)?([^\/]+\/)+session-log\.txt/ ||
				/All documents processed\./ ||
				/convert_clusters\.p[yl] / || # convert_clusters.pl
				/check_revisions\.py/ || # check_revisions.sh
				/^\.+$/ || # progress bar
				/Your job \d+ \(\"\w+\"\) has been submitted/ || # qsub
				/^$/) # empty line
			{
				if ($first_error) {
					print STDERR "Log file: $FILENAME\n";
					$first_error = 0;
				}
				if (/^\.+Traceback/) { # delete progress bar
					s/^\.+//;
				}
				print STDERR;
			}
		}
	}
	close FILE;
}
