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

#define logToken true

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

%union{
    char *a;
    std::string *pStr;
    double d;
    int fn; 
}

%type <pStr> logic_expression;

%type <pStr> logic_expression_com;

%type <pStr> arithmetic_expression;

%type <pStr> arithmetic_expression_md;

%type <pStr> arithmetic_expression_con;

%type <pStr> arithmetic_expression_value;

%%

program
	: LET declaration_list IN expression_list END
	| LET declaration_list IN  END
	;

declaration_list
	: declaration declaration_list

{if(logToken)printf("\n== declaration declaration_list  -->  declaration_list   '%s'\n", yytext);}
	| declaration
{if(logToken)printf("\n== declaration  -->  declaration_list   '%s'\n", yytext);}
	;

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valued_expression
{if(logToken)printf("\n== VAR IDENTIFIER ASSIGN valued_expression  -->  declarationVar   '%s'\n", yytext);}
	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression
{if(logToken)printf("\n== FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression  -->  declarationFunc   '%s'\n", yytext);}
	;



expression_list
	: expression ';' expression_list
{if(logToken)printf("\n==  expression ';' expression_list  -->  expression_list   '%s'\n", yytext);}
	| whileLoop expression_list
{if(logToken)printf("\n==  whileLoop expression_list  -->  expression_list   '%s'\n", yytext);}
	| ifThenStatement expression_list
{if(logToken)printf("\n==  ifThenStatement expression_list  -->  expression_list   '%s'\n", yytext);}
	| expression ';'
{if(logToken)printf("\n== expression ';'  -->  expression_list   '%s'\n", yytext);}
	| expression
{if(logToken)printf("\n== expression  -->  expression_list   '%s'\n", yytext);}
	| // empty
{if(logToken)printf("\n==   -->  expression_list   '%s'\n", yytext);}
	;


/*
expression_list
	: expression_list_semicolon expression
{if(logToken)printf("\n== expression_list_semicolon expression  -->  expression_list   '%s'\n", yytext);}
	| expression_list_semicolon
{if(logToken)printf("\n== expression_list_semicolon  -->  expression_list   '%s'\n", yytext);}
	| expression
{if(logToken)printf("\n== expression  -->  expression_list   '%s'\n", yytext);}
	| // empty
{if(logToken)printf("\n==   -->  expression_list   '%s'\n", yytext);}
	;

expression_list_semicolon
	: expression ';' expression_list_semicolon 
{if(logToken)printf("\n== expression ';' expression_list_semicolon  -->  expression_list_semicolon   '%s'\n", yytext);}
	| expression ';' 
{if(logToken)printf("\n== expression  -->  expression_list_semicolon   '%s'\n", yytext);}
	;
*/

expression
	: void_expression 
{if(logToken)printf("\n== void_expression  -->  expression   '%s'\n", yytext);}
	| valued_expression
{if(logToken)printf("\n== valued_expression  -->  expression   '%s'\n", yytext);}
	;


void_expression
	: ifThenStatement
{if(logToken)printf("\n== ifThenStatement  -->  void_expression   '%s'\n", yytext);}
	| whileLoop 
{if(logToken)printf("\n== whileLoop  -->  void_expression   '%s'\n", yytext);}
	| atribution 
{if(logToken)printf("\n== atribution  -->  void_expression   '%s'\n", yytext);}
	| ';'
{if(logToken)printf("\n== ';'  -->  void_expression   '%s'\n", yytext);}
	;

valued_expression
	: logic_expression 
{if(logToken)printf("\n== logic_expression  -->  valued_expression   '%s'\n", yytext);}
	| functionCall
{if(logToken)printf("\n== functionCall  -->  valued_expression   '%s'\n", yytext);}
	| sequence
{if(logToken)printf("\n== sequence  -->  valued_expression   '%s'\n", yytext);}
	;

sequence
	: '(' expression_list ')'
{if(logToken)printf("\n== '(' expression_list ')'  -->  sequence   '%s'\n", yytext);}
	;

semicolon_opt
	: /* empty */
{if(logToken)printf("\n==   -->  semicolon_opt   '%s'\n", yytext);}
	| ";"
{if(logToken)printf("\n== ';'  -->  semicolon_opt   '%s'\n", yytext);}
	;

atribution
	: IDENTIFIER ASSIGN valued_expression
{if(logToken)printf("\n== IDENTIFIER ASSIGN valued_expression  -->  atribution   '%s'\n", yytext);}
	;


whileLoop
	: WHILE valued_expression DO expression
{if(logToken)printf("\n== WHILE valued_expression DO expression  -->  whileLoop   '%s'\n", yytext);}
	;



functionCall
	: IDENTIFIER '(' parameter_list ')'
{if(logToken)printf("\n== IDENTIFIER '(' parameter_list ')'  -->  functionCall   '%s'\n", yytext);}
	;

parameter_declaration 
    : IDENTIFIER ',' parameter_declaration
{if(logToken)printf("\n== IDENTIFIER ',' parameter_declaration --> parameter_declaration	'%s'\n",yytext);}
    | IDENTIFIER
{if(logToken)printf("\n== IDENTIFIER --> parameter_declaration	'%s'\n",yytext);}
    |
    ;
	
parameter_list
	: valued_expression ',' parameter_list
{if(logToken)printf("\n== valued_expression ',' parameter_list --> parameter_list	'%s'\n",yytext);}
	| valued_expression
{if(logToken)printf("\n== valued_expression --> parameter_list '%s'\n",yytext);}
	| STRING_LITERAL ',' parameter_list
{if(logToken)printf("\n== STRING LITERAL ',' parameter_list --> parameter_list	'%s'\n",yytext);}
	| STRING_LITERAL
{if(logToken)printf("\n== STRING LITERAL --> parameter_list	'%s'\n",yytext);}
	|
	;


ifThenStatement
	: ifThenElse
{if(logToken)printf("\n== ifThenElse --> ifThenStatement	'%s'\n",yytext);}
	| ifThen
{if(logToken)printf("\n== ifThen --> ifThenStatement	'%s'\n",yytext);}
	;

ifThenElse
	: IF valued_expression THEN expression ELSE expression
{if(logToken)printf("\n== IF valued_expression THEN expression ELSE expression --> ifThenElse	'%s'\n",yytext);}
	;

ifThen
	: IF valued_expression THEN expression
{if(logToken)printf("\n== IF valued_expression THEN expression --> ifThen	'%s'\n",yytext);}
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
{if(logToken)printf("\n== %s '&' %s --> logic_expression	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression '|' logic_expression_com
{if(logToken)printf("\n== %s '|' %s --> logic_expression	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com
	;

logic_expression_com
	: logic_expression_com '=' arithmetic_expression
{if(logToken)printf("\n== %s '&' %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com NE_OP arithmetic_expression
{if(logToken)printf("\n== %s NE_OP %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com '>' arithmetic_expression
{if(logToken)printf("\n== %s '>' %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com '<' arithmetic_expression
{if(logToken)printf("\n== %s '<' %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com GE_OP arithmetic_expression
{if(logToken)printf("\n== %s GE_OP %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| logic_expression_com LE_OP arithmetic_expression
{if(logToken)printf("\n== %s LE_OP %s --> logic_expression_com	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| arithmetic_expression
{if(logToken)printf("\n== %s --> logic_expression_com	'%s'\n",$1->c_str(),yytext);}
	;


arithmetic_expression
	: arithmetic_expression '+' arithmetic_expression_md
{if(logToken)printf("\n== %s '+' %s --> arithmetic_expression	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| arithmetic_expression '-' arithmetic_expression_md
{if(logToken)printf("\n== %s '-' %s --> arithmetic_expression	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| arithmetic_expression_md
{if(logToken)printf("\n== %s --> arithmetic_expression	'%s'\n",$1->c_str(),yytext);}
	;

arithmetic_expression_md
	: arithmetic_expression_md '*' arithmetic_expression_con
{if(logToken)printf("\n== %s '*' %s --> arithmetic_expression_md	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| arithmetic_expression_md '/' arithmetic_expression_con
{if(logToken)printf("\n== %s '/' %s --> arithmetic_expression_md	'%s'\n",$1->c_str(),$3->c_str(),yytext);}
	| arithmetic_expression_con
{if(logToken)printf("\n== %s --> arithmetic_expression_md	'%s'\n",$1->c_str(),yytext);}
	;	

arithmetic_expression_con
	: '-' arithmetic_expression_value
{if(logToken)printf("\n== '-' %s --> arithmetic_expression_con	'%s'\n",$2->c_str(),yytext);}
	| arithmetic_expression_value
{if(logToken)printf("\n== %s --> arithmetic_expression_con	'%s'\n",$1->c_str(),yytext);}
	;

arithmetic_expression_value
	: IDENTIFIER

{if(logToken)printf("\n== IDENTIFIER --> arithmetic_expression_value	'%s'\n",yytext);}
	| CONSTANT
{if(logToken)printf("\n== CONSTANT --> arithmetic_expression_value	'%s'\n",yytext);}
	| functionCall
{if(logToken)printf("\n== functionCall --> arithmetic_expression_value	'%s'\n",yytext);}
	| '(' valued_expression ')'
{if(logToken)printf("\n== '(' valued_expression ')' --> arithmetic_expression_value	'%s'\n",yytext);}
	;


%%

