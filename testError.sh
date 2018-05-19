#!/bin/sh

echo > testError.log
for DIR in test/error/* ; do
    for FILE in DIR/*.tig; do
        ./parser.exe $FILE && echo $FILE failed >> testError.log
   done
done

