#!/usr/bin/env perl
use URI::Escape;
$la='en';
if ($#ARGV >= 0 && $ARGV[0] eq '-l') {
    $la=$ARGV[1];
    shift; shift;
}

print "<table>\n";
print "<tr><th>Rank</th><th>Titles and links</th><th>Trending score</th></tr>\n";
while (<>) {
    /^([^ ]*) /;
    $title = uri_escape($1, "^A-Za-z0-9\-\. _~\%");
    if ($la eq "en") {
        s| | <a href="http://$la.wikipedia.org/wiki/$title" target="view">[now]</a></td><td>|;
    } else {
        s| | <a href="http://$la.wikipedia.org/wiki/$title" target="view">[now]</a> <a href="http://translate.google.com/translate?hl=en&sl=$la&tl=en&u=http%3A%2F%2F$la.wikipedia.org%2Fwiki%2F$title" target="translate">[now:translate]</a></td><td>|;
    }
    s|^|<tr><td>$.</td><td>|;
    s|$|</td></tr>|;
    print;
}
print "</table>\n";
