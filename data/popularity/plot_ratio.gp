set terminal postscript eps enhanced
set output "logratio.eps"
set xrange [0:1]
set yrange [-2:8]
set xlabel "quantile"
set ylabel "log ratio"
set size 0.6,0.6
plot "topics.ratio" using 2:3 with lines title "WikiTopics articles", \
     0 title "", \
     "events.ratio.3" using 2:3 with lines title "hand-curated articles"
