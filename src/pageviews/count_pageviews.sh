#!/bin/bash
for FILE in */*/*; do
	wc -l $FILE
done
