for day in `seq 2 15`; do for k in `seq 10 10 200`; do ./run_news_articles.sh $k $day; done; done
