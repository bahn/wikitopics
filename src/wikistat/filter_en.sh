for file in daily/*2009*; do gunzip -c $file | awk '$1=="en" {print} $1>"en" {exit}' | gzip -c - > en_$file; done
