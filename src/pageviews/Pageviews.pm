package Pageviews;
use Exporter;
use File::Spec;
use Digest::SHA qw(sha224_hex);
use URI::Escape;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(title_to_filename open_and_append);
our @EXPORT = qw(title_to_filename open_and_append);

sub title_to_filename {
	my $title = shift;
	my $filename = uri_escape($title, "^A-Za-z0-9\-\. _~\%");
	$filename =~ s/ /_/g;
	$filename =~ s/^\./\%2E/;

	if (length($filename) > 128) {
		my $digest = sha224_hex($filename);
		$filename = substr($filename, 0, 128) . $digest;
	}
	return $filename . '_pageviews.txt';
}

1;
