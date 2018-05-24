
CC			= g++ -std=c++14
FLAGS		= -O0 -g # DEBUG
#FLAGS		= -O3 # RELEASE

YACCFLAGS = --defines --debug --verbose --graph
#YACCFLAGS = --defines

LIB		=  -lfl -ly

PROGRAM	= parser.exe


all: $(PROGRAM)

clean:
	rm -f *.tab.h *.tab.c lex.yy.c $(PROGRAM)

cleanPng:
	rm -f *.png

cleanDot:
	rm -f *.dot

cleanTest:
	rm -f *.log
	rm -f test/*/*/*.log

cleanAll: clean cleanDot cleanPng cleanTest

rebuild: clean all



$(PROGRAM): lex yacc
	$(CC) $(FLAGS) tiger--.tab.c $(LIB) -o $(PROGRAM);


lex: tiger--.l
	flex tiger--.l


yacc: tiger--.y
	bison $(YACCFLAGS) tiger--.y
