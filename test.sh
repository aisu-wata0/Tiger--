#!/bin/sh
echo > test.log;
for FILE in test/*.tig; do
     ./parser.exe $FILE || echo $FILE failed >> test.log
done

