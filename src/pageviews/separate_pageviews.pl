#!/usr/bin/env perl

use File::Basename;
use File::Path qw(make_path);
use Env qw(HOSTNAME);
use Pageviews;
#use IO::Handle;
use IO::File;

#print "$HOSTNAME\$ " . basename($0) . " @ARGV\n";

# check the command-line arguments
die "usage: $0 [OUTPUT_PATH [FILE1 [FILE2 [...]]]]" if (scalar @ARGV < 1);

$output_path = 'pageviews';
if (@ARGV) {
	$output_path = shift @ARGV;
}
#print "The pageviews files are located at $output_path.\n";

#%titles = ();
#if (@ARGV) {
#	open FILE, "<$ARGV[0]" or die "failed opening $ARGV[0]: $!";
#	while (<FILE>) {
#		@fields = split;
#		if ($#fields > 0) {
#			# there are more than one fields, so this must not be a list of titles.
#			break;
#		}
#		chomp;
#		$titles{$_} = 1;
#	}
#	close FILE;
#
#	if (%titles) {
#		shift;
#	}
#}

# modules
@open_files=();
%files=();
sub open_and_append {
	my $output_path = shift;
	my $title = shift;
	die "title is empty!" if (!defined $title or $title eq "");

	if (exists $files{$title}) {
		return $files{$title};
	} else {
		if (scalar @open_files >= 100) {
			$oldest_title = shift @open_files;
			delete $files{$oldest_title};
		}
		push @open_files, $title;
		my $filename = File::Spec->join($output_path, title_to_filename($title));
#		my $fh;
#		if (!-e "$filename") {
#			$fh = IO::File->new(">$filename") or die "could not open $filename: $!";
#			print $fh "date\tpageview\n";
#		} else {
#			$fh = IO::File->new(">>$filename") or die "could not append $filename: $!";
#		}
		my $fh = IO::File->new(">>$filename") or die "could not append $filename: $!";
		$files{$title}=$fh;
		return $fh;
	}
}

sub separate_file {
	my $infh = shift;
	while (<$infh>) {
		@fields = split;
		$title = $fields[1];
		$fh = open_and_append($output_path, $title);
		print $fh "$fields[0]\t$fields[2]\n";
	}
	
}

if (!-e ($output_path)) {
	make_path($output_path) or die "creating $output_path failed: $!";
}

if (@ARGV) {
	while (@ARGV) {
		$pattern = shift @ARGV;
		foreach $file (glob("$pattern")) {
			print "separating $file\n";
			open my $fh, "<$file" or die "failed opening $file: $!";
			separate_file($fh, $title);
			close $fh;
		}
	}
} else {
	separate_file(STDIN);
}

for $fh (values %files) {
	$fh->close;
}
