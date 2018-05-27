#!/bin/sh

echo > testError.log
for DIR in test/error/* ; do
	echo > $DIR/testError.log
	for FILE in $DIR/*.tig; do
		./tc-- $FILE && echo $FILE failed >> $DIR/testError.log
	done
	
	echo "Test Failures " $DIR ": " >> testError.log
	cat $DIR/testError.log >> testError.log
	echo >> testError.log
done

echo "Test Failures:"
cat testError.log


