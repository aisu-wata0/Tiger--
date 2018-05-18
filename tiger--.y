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
#include <iostream>
#include <stdio.h>
#include "lex.yy.c"

//extern char yytext[];
//extern char yylex();
//extern int yylineno;
//extern int column;

int yywrap() {
   // open next reference or source file and start scanning
   /*if((yyin = compiler->getNextFile()) != NULL) {
      yylineno = 0; // reset line counter for next source file
      return 0;
   }*/
   return 1;
}

void yyerror(const std::string & msg)
{
	fflush(stdout);
	std::cerr << "Error: " << msg << " in line " << yylineno << ". Token = " << yytext << std::endl;
	
	exit(1);
}

 /*
void yyerror(char const *s)
{
	printf("\n%*s\n%*s\n", column, "^", column, s);
}
*/

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
	: FUNCTION IDENTIFIER '(' parameters ')' ASSIGN expression
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
	| '(' parameters ')'
	;


atribution
	: IDENTIFIER ASSIGN valued_expression ';'
	;


whileLoop
	: WHILE valued_expression DO expression
	;


functionCall
	: IDENTIFIER '(' parameters ')' ';'
	;

parameters
	: valued_expression ',' valued_expression
	| valued_expression
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
