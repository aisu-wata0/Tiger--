
all:
	flex tiger--.lex
	g++ lex.yy.c -std=c++11 -O3 -lfl -o conta
