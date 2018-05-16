%token IDENTIFIER CONSTANT STRING_LITERAL
%token LE_OP GE_OP NE_OP
 // %token EQ_OP '='
 // %token AND_OP '&' OR_OP '|'

%token IF ELSE WHILE DO
%token ASSIGN END LET THEN FUNCTION VAR
%token IN
%token UNKNOWN

%start program

%{

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <stdio.h>
#include <ctype.h>

extern FILE *fp;

extern char *yytext;
extern int yylex();
extern int yylineno;
//extern int column;
   
void yyerror(const std::string & msg)
{
	fflush(stdout);
	std::cerr << "Error: " << msg << " in line " << yylineno << ". Token = " << yytext << std::endl;
	
	exit(1);
}

#include"lex.yy.c"

int count=0;

int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");

	if(!yyparse())
		printf("\nParsing completed\n");
	else
		printf("\nParsing failed\n");

	fclose(yyin);
	
	return 0;
}

%}

%%

program
	: LET declaration_list IN expressions END
	;

declaration_list
	: declaration declaration_list
	| declaration
	;
	
declaration
	: declarationVar | declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valued_expression
	;
	
declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_list ')' ASSIGN expression
	;

expressions
	: expression expressions
	| expression
	;

expression
	: atribution
	| ifThenStatement
	| whileLoop
	| functionCall
	| '(' parameter_list ')'
	;


atribution
	: IDENTIFIER ASSIGN valued_expression ';'
	;


whileLoop
	: WHILE valued_expression DO expression
	;


functionCall
	: IDENTIFIER '(' parameter_list ')' ';'
	;

parameter_list
	: valued_expression ',' parameter_list
	| valued_expression
	| STRING_LITERAL ',' parameter_list
	| STRING_LITERAL
	; 


ifThenStatement
	: ifThenElse
	| ifThen
	;

ifThenElse
	: IF valued_expression THEN expression ELSE expression
	;

ifThen
	: IF valued_expression THEN expression
	;

 /**
ifThenElse
	: IF expression then ifThenElse ELSE ifThenElse
	;

ifThen
	: IF valued_expression THEN expression
	| IF valued_expression THEN ifThenElse ELSE ifThen
	;

 /**/



valued_expression
	: arithmetic_expression
	| logic_expression
	;


logic_expression
	: logic_expression '&' logic_expression_com
	| logic_expression '|' logic_expression_com
	| logic_expression_com
	;
	
logic_expression_com
	: logic_expression_com '=' logic_expression_st
	| logic_expression_com NE_OP logic_expression_st
	| logic_expression_com '>' logic_expression_st
	| logic_expression_com '<' logic_expression_st
	| logic_expression_com GE_OP logic_expression_st
	| logic_expression_com LE_OP logic_expression_st
	| logic_expression_st
	;
	
logic_expression_st
	: IDENTIFIER
	| CONSTANT
	| '(' logic_expression ')'
	;


arithmetic_expression
	: arithmetic_expression '+' arithmetic_expression_md
	| arithmetic_expression '-' arithmetic_expression_md
	| arithmetic_expression_md
	;

arithmetic_expression_md
	: arithmetic_expression_md '*' arithmetic_expression_con
	| arithmetic_expression_md '/' arithmetic_expression_con
	| arithmetic_expression_con
	;

arithmetic_expression_con
	: '-' arithmetic_expression_value
	| arithmetic_expression_value
	;

arithmetic_expression_value
	: IDENTIFIER
	| CONSTANT
	| '(' arithmetic_expression ')'
	;


%%

