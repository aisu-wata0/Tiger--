
CC		= g++ -std=c++11

LIB		=  -lfl -ly

PROGRAM	= parser.exe

YACCFLAGS = --debug --verbose


all: $(PROGRAM)


clean:
	rm -f *.tab.h *.tab.c lex.yy.c $(PROGRAM)

cleanPng:
	rm -f *.png

cleanDot:
	rm -f *.dot

cleanAll: clean cleanDot cleanPng
	
rebuild: clean all



$(PROGRAM): lex yacc
	$(CC) -O0 -g tiger--.tab.c $(LIB) -o $(PROGRAM);


lex: tiger--.l
	flex tiger--.l


yacc: tiger--.y
	bison -d $(YACCFLAGS) tiger--.y
	
