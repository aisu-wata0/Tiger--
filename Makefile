
CC		= g++ -std=c++11

LIB		=  -lfl -ll

all: syntax lex
	$(CC) -O0 -g $(LIB) tiger--.tab.c -o yacc ;
	#$(CC) -O3 $(LIB) lex.yy.c -o lex;

lex: tiger--.l
	flex tiger--.l

syntax: tiger--.y
	bison -d tiger--.y
	
clean:
	rm *.tab.h *.tab.c lex.yy.c
