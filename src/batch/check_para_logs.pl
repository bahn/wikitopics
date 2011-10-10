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
	die "$0 INPUT_DIR" unless (-d $1);
	$DIR = $1;
} elsif (-d $1) {
	$DIR = $1;
}

@FILES = glob("$DIR/para_serif.* $DIR/para_proc.* $DIR/ext_redir.* $DIR/conv_clust.* $DIR/add_stats.* $DIR/redir_stat.* $DIR/list_topic.* $DIR/check_rev.* $DIR/fetch_sent.* $DIR/kmeans.*");
foreach $FILENAME (@FILES) {
	open FILE, $FILENAME;
	$first_error = 1;
	$first_line = "";
	$any_error = 0;
	while (<FILE>) {
		if (!$first_line) {
			$first_line = $_;
		}
		if (/(\w+)\.(sh|py|pl)\s+/) {
			$step = $1;
			$lang = "";
			$start_date = "";
			$end_date = "";

			if (/(\w+)\.(sh|py|pl)\s+(\S+)\s+([\-\d]+)(\s+([\-\d]+))?/) { # ko 2011-04-18
				$lang = $3;
				$start_date = $4;
				$end_date = $6;
			} elsif (/(\w+)\.(sh|py|pl)\s+(\-\S+\s+\S+\s+)(\S+)\s+([\-\d]+)(\s+([\-\d]+))?/) { # -c 100 ko 2011-04-18
				$lang = $4;
				$start_date = $5;
				$end_date = $7;
			} elsif (/(\w+)\.(sh|py|pl)\s+(\S+)\s+(\S+)\s+([\-\d]+)(\s+([\-\d]+))?/) { # ko redirects_file 2011-04-18
				$lang = $3;
				$start_date = $5;
				$end_date = $7;
			}

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
		} else {
			unless (/\w+ \w+ \d+ [:\d]+ \w+ \d+/ || # date and time
				/[\d\-]+ [\d\:]+/ || # date and time in a different format
				/(real|user|sys)\s+\d+m\d+\.\d+s/ || # elapsed time
				/pagecounts-\d+\.gz/ || # pagecounts file name output by list_topics.py
				/\/export\/people\/bahn\/wikitopics not found/ ||
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
				/Session completed with \d+ error\(s\) and \d+ warning\(s\)\./ ||
				/convert_clusters\.p[yl] / || # convert_clusters.pl
				/check_revisions\.py/ || # check_revisions.sh
				/^\.+$/ || # progress bar
				/exporting articles\.\.\./ || # para_serif.sh
				/running serif\.\.\./ ||
				/selecting sentences\.\.\./ ||
				/Your job \d+ \(\"\w+\"\) has been submitted/ || # qsub
				/^$/) # empty line
			{
				if ($first_error) {
					print "\nLog file: $FILENAME\n";
					print $first_line;
					$first_error = 0;
				}
				if (/^\.+Traceback/) { # delete progress bar
					s/^\.+//;
				}
				print;
				$any_error = 1;
			}
		}
	}
	close FILE;
	if ($DELETE && !$any_error) {
		unlink($FILENAME);
	}
}
