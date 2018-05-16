%token IDENTIFIER CONSTANT STRING_LITERAL
%token LE_OP GE_OP NE_OP
 // %token EQ_OP '='
 // %token AND_OP '&' OR_OP '|'

%token IF ELSE WHILE DO
%token ASSIGN END LET THEN FUNCTION VAR
%token UNKNOWN

%start program

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
	: VAR id ASSIGN valued_expression
	;
	
declarationFunc
	: FUNCTION id '(' parameters ')' ASSIGN expression
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
	: IDENTIFIER ASSIGNMENT valued_expression ';'
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

arithmetic_expression_con:
	: '-' arithmetic_expression_value
	| arithmetic_expression_value
	;

arithmetic_expression_value
	: IDENTIFIER
	| CONSTANT
	| '(' arithmetic_expression ')'
	;


%%

#include <stdio.h>

extern char yytext[];
extern int column;

void yyerror(char const *s)
{
	fflush(stdout);
	printf("\n%*s\n%*s\n", column, "^", column, s);
}

