
all: lex syntax
	g++ -std=c++11 -O3 -lfl lex.yy.c -o conta

lex: tiger--.lex
	flex tiger--.lex

syntax: tiger--.yacc
