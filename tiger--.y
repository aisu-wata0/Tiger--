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
#include <string>

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

%union {
    char *a;
    std::string *pStr;
    double d;
    int fn;
}

%%

program
	: LET declaration_list IN expression_list END
	| LET declaration_list IN  END
	;

declaration_list
	: declaration declaration_list 
{printf("\n== declaration declaration_list  -->  declaration_list   '%s'\n", yytext);}
	| declaration
{printf("\n== declaration  -->  declaration_list   '%s'\n", yytext);}
	;

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valued_expression
{printf("\n== VAR IDENTIFIER ASSIGN valued_expression  -->  declarationVar   '%s'\n", yytext);}
	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_list ')' ASSIGN expression
{printf("\n== FUNCTION IDENTIFIER '(' parameter_list ')' ASSIGN expression  -->  declarationFunc   '%s'\n", yytext);}
	;

expression_list
	: expression_list_semicolon expression
{printf("\n== expression_list_semicolon expression  -->  expression_list   '%s'\n", yytext);}
	| expression_list_semicolon
{printf("\n== expression_list_semicolon  -->  expression_list   '%s'\n", yytext);}
	| expression
{printf("\n== expression  -->  expression_list   '%s'\n", yytext);}
	;

expression_list_semicolon
	: expression ';' expression_list_semicolon 
{printf("\n== expression ';' expression_list_semicolon  -->  expression_list_semicolon   '%s'\n", yytext);}
	| expression ';' 
{printf("\n== expression  -->  expression_list_semicolon   '%s'\n", yytext);}
	;


expression
	: void_expression 
{printf("\n== void_expression  -->  expression   '%s'\n", yytext);}
	| valued_expression
{printf("\n== valued_expression  -->  expression   '%s'\n", yytext);}
	;


void_expression
	: ifThenStatement
{printf("\n== ifThenStatement  -->  void_expression   '%s'\n", yytext);}
	| whileLoop 
{printf("\n== whileLoop  -->  void_expression   '%s'\n", yytext);}
	| atribution 
{printf("\n== atribution  -->  void_expression   '%s'\n", yytext);}
	| void_sequence 
{printf("\n== void_sequence  -->  void_expression   '%s'\n", yytext);}
	| functionCall
{printf("\n== functionCall  -->  void_expression   '%s'\n", yytext);}
	;

valued_expression
	: logic_expression 
{printf("\n== logic_expression  -->  valued_expression   '%s'\n", yytext);}
	| valued_sequence 
{printf("\n== valued_sequence  -->  valued_expression   '%s'\n", yytext);}
	| functionCall 
{printf("\n== functionCall  -->  valued_expression   '%s'\n", yytext);}
	;

valued_sequence
	: '(' expression_list_semicolon valued_expression semicolon_opt ')'
{printf("\n== '(' expression_list_semicolon valued_expression semicolon_opt ')'  -->  valued_sequence   '%s'\n", yytext);}
	| '(' valued_expression semicolon_opt ')'
{printf("\n== '(' valued_expression semicolon_opt ')'  -->  valued_sequence   '%s'\n", yytext);}
	;

void_sequence
	: '(' void_expression ';' ')' 
{printf("\n== '(' void_expression ';' ')'  -->  void_sequence   '%s'\n", yytext);}
	| '(' void_expression ')' 
{printf("\n== '(' void_expression ')'  -->  void_sequence   '%s'\n", yytext);}
	| '(' expression_list_semicolon void_expression semicolon_opt ')'
{printf("\n== '(' expression_list_semicolon void_expression semicolon_opt ')'  -->  void_sequence   '%s'\n", yytext);}
	| '(' semicolon_opt ')'
{printf("\n== '(' semicolon_opt ')'  -->  void_sequence   '%s'\n", yytext);}
	;

semicolon_opt
	: /* empty */
{printf("\n==   -->  semicolon_opt   '%s'\n", yytext);}
	| ";"
{printf("\n== ';'  -->  semicolon_opt   '%s'\n", yytext);}
	;

atribution
	: IDENTIFIER ASSIGN valued_expression
{printf("\n== IDENTIFIER ASSIGN valued_expression  -->  atribution   '%s'\n", yytext);}
	;


whileLoop
	: WHILE valued_expression DO expression
{printf("\n== WHILE valued_expression DO expression  -->  whileLoop   '%s'\n", yytext);}
	;


functionCall
	: IDENTIFIER '(' parameter_list ')'
{printf("\n== IDENTIFIER '(' parameter_list ')'  -->  functionCall   '%s'\n", yytext);}
	;

parameter_list
	: valued_expression ',' parameter_list
	| valued_expression
	| STRING_LITERAL ',' parameter_list
	| STRING_LITERAL
	|
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


logic_expression
	: logic_expression '&' logic_expression_com
	| logic_expression '|' logic_expression_com
	| logic_expression_com
	;

logic_expression_com
	: logic_expression_com '=' arithmetic_expression
	| logic_expression_com NE_OP arithmetic_expression
	| logic_expression_com '>' arithmetic_expression
	| logic_expression_com '<' arithmetic_expression
	| logic_expression_com GE_OP arithmetic_expression
	| logic_expression_com LE_OP arithmetic_expression
	| arithmetic_expression
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
	| '(' valued_expression ')'
	;


%%
