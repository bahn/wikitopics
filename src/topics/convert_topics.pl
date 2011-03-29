#!/usr/bin/env perl
print "<table>\n";
print "<tr><th>Rank</th><th>Titles and links</th><th>Trending score</th></tr>\n";
while (<>) {
    /^([^ ]*) /;
    $title = $1;
    s| | <a href="http://en.wikipedia.org/wiki/$title" target="view">[now]</a></td><td>|;
    s|^|<tr><td>$.</td><td>|;
    s|$|</td></tr>|;
    print;
}
print "</table>\n";
