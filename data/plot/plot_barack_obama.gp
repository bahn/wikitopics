set terminal postscript eps enhanced
set output "obama.eps"
set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set log y
set xrange ["2008-12-01":"2009-02-09"]
set yrange [100:100000000]
set arrow 1 from "2009-01-20", 100 to "2009-01-20", 1000000 nohead
set ylabel "Page views"
set size 0.6,0.6
plot "Barack_Obama.dat" using 1:2 with lines title "Barack Obama", \
	 "United_States.dat" using 1:2 with lines title "United States", \
	 "List_of_Presidents_of_the_United_States.dat" using 1:2 with lines title "List of Presidents of the United States", \
	 "President_of_the_United_States.dat" using 1:2 with lines title "President of the United States", \
	 "African_American.dat" using 1:2 with lines title "African American", \
	 "List_of_African-American_firsts.dat" using 1:2 with lines title "List of African-American firsts"
