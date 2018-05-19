
CC		= g++ -std=c++11

LIB		=  -lfl -ly

PROGRAM	= parser.exe

YACCFLAGS = -v -d --debug --verbose --graph


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
	$(CC) -O0 -g tiger--.tab.c $(LIB) -o $(PROGRAM);


lex: tiger--.l
	flex tiger--.l


yacc: tiger--.y
	bison $(YACCFLAGS) tiger--.y
	
