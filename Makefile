
CC		= g++ -std=c++11

LIB		=  -lfl -ly

PROGRAM	= yacc.exe


$(PROGRAM): lex yacc
	$(CC) -O0 -g tiger--.tab.c $(LIB) -o $(PROGRAM);

lex: tiger--.l
	flex tiger--.l

yacc: tiger--.y
	bison -d tiger--.y
	
clean:
	rm *.tab.h *.tab.c lex.yy.c $(PROGRAM)
