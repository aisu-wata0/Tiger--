%token IDENTIFIER CONSTANT STRING_LITERAL
%token LE_OP GE_OP NE_OP
 // %token EQ_OP '='
 // %token AND_OP '&' OR_OP '|'

%token IF ELSE WHILE DO
%token ASSIGN END LET THEN FUNCTION VAR
%token IN

%start program

%{

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <stdio.h>
#include <ctype.h>
#include <string>
#include <vector>

#define logSyntax true
#define YYSTYPE class STNode *

extern FILE *fp;

extern char *yytext;
extern int yylex();
extern int yylineno;
//extern int column;

void yyerror(const std::string & msg)
{
	fflush(stdout);
	std::cerr << std::endl
	<< "error: " << msg << " in line " << yylineno << ". Token = " << yytext << std::endl;

	exit(1);
}

void yywarn(const std::string & msg)
{
	fflush(stdout);
	std::cerr << std::endl
	<< "warning: " << msg << " in line " << yylineno << ". Token = " << yytext << std::endl;
}


enum class Type {
	Void,
	Str,
	Int,
};


class STNode {
public:
    std::string *pStr;
    std::vector<STNode*> childs;
};

class STNodeId : public STNode {
public:
	Type type;
};

class STNodeInt : public STNode {
public:
	int value;
};


#include "lex.yy.c"

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

/*%union{
    char *a;
    std::string *pStr;
    double d;
    int fn;
    STNode
}*/

//%type <pStr> logic_expression logic_expression_com arithmetic_expression arithmetic_expression_md arithmetic_expression_con arithmetic_expression_value;

%%
letStatement
    : LET declaration_list IN expression_list END 
{std::cout << "\n==  LET declaration_list IN expression_list END -->  letStatement \t\tnext token:'" << yytext << std::endl;}
	| VAR 
{yyerror("syntax: missing let");}
	| LET declaration_list expression
{yyerror("syntax: missing in");}
	| LET declaration_list IN expression_list 
{yyerror("syntax: missing end");}	
    ;

program
	: letStatement
{std::cout << "\n==  letStatement -->  program \t\tnext token:'" << yytext << std::endl;}	
	;

declaration_list
	: declaration declaration_list

{if(logSyntax)std::cout << "\n== declaration declaration_list  -->  declaration_list \t\tnext token:'" << yytext << std::endl;}
	| declaration
{if(logSyntax)std::cout << "\n== declaration  -->  declaration_list \t\tnext token:'" << yytext << std::endl;}
	| //empty
	;

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valued_expression
{if(logSyntax)std::cout << "\n== VAR IDENTIFIER ASSIGN valued_expression  -->  declarationVar \t\tnext token:'" << yytext << std::endl;}
	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression
{if(logSyntax)std::cout << "\n== FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression  -->  declarationFunc \t\tnext token:'" << yytext << std::endl;}
	;



expression_list
	: expression ';' expression_list
{if(logSyntax)std::cout << "\n==  expression ';' expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| whileLoop expression_list
{if(logSyntax)std::cout << "\n==  whileLoop expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| ifThenStatement expression_list
{if(logSyntax)std::cout << "\n==  ifThenStatement expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| expression ';'
{if(logSyntax)std::cout << "\n== expression ';'  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| expression
{if(logSyntax)std::cout << "\n== expression  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| // empty
{if(logSyntax)std::cout << "\n==   -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	;


/*
expression_list
	: expression_list_semicolon expression
{if(logSyntax)std::cout << "\n== expression_list_semicolon expression  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| expression_list_semicolon
{if(logSyntax)std::cout << "\n== expression_list_semicolon  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| expression
{if(logSyntax)std::cout << "\n== expression  -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	| // empty
{if(logSyntax)std::cout << "\n==   -->  expression_list \t\tnext token:'" << yytext << std::endl;}
	;

expression_list_semicolon
	: expression ';' expression_list_semicolon 
{if(logSyntax)std::cout << "\n== expression ';' expression_list_semicolon  -->  expression_list_semicolon \t\tnext token:'" << yytext << std::endl;}
	| expression ';' 
{if(logSyntax)std::cout << "\n== expression  -->  expression_list_semicolon \t\tnext token:'" << yytext << std::endl;}
	;
*/

expression
	: void_expression 
{if(logSyntax)std::cout << "\n== void_expression  -->  expression \t\tnext token:'" << yytext << std::endl;}
	| valued_expression
{if(logSyntax)std::cout << "\n== valued_expression  -->  expression \t\tnext token:'" << yytext << std::endl;}
	;


void_expression
	: ifThenStatement
{if(logSyntax)std::cout << "\n== ifThenStatement  -->  void_expression \t\tnext token:'" << yytext << std::endl;}
	| whileLoop 
{if(logSyntax)std::cout << "\n== whileLoop  -->  void_expression \t\tnext token:'" << yytext << std::endl;}
	| atribution 
{if(logSyntax)std::cout << "\n== atribution  -->  void_expression \t\tnext token:'" << yytext << std::endl;}
	| ';'
{if(logSyntax)std::cout << "\n== ';'  -->  void_expression \t\tnext token:'" << yytext << std::endl;}
	;

valued_expression
	: logic_expression 
{if(logSyntax)std::cout << "\n== logic_expression  -->  valued_expression \t\tnext token:'" << yytext << std::endl;}
	| functionCall
{if(logSyntax)std::cout << "\n== functionCall  -->  valued_expression \t\tnext token:'" << yytext << std::endl;}
	| sequence
{if(logSyntax)std::cout << "\n== sequence  -->  valued_expression \t\tnext token:'" << yytext << std::endl;}
    | letStatement
{std::cout << "\n== letStatement  -->  valued_expression \t\tnext token:'" << yytext << std::endl;}
	;

sequence
	: '(' expression_list ')'
{if(logSyntax)std::cout << "\n== '(' expression_list ')'  -->  sequence \t\tnext token:'" << yytext << std::endl;}
	;



atribution
	: IDENTIFIER ASSIGN valued_expression
{if(logSyntax)std::cout << "\n== IDENTIFIER ASSIGN valued_expression  -->  atribution \t\tnext token:'" << yytext << std::endl;}
	;


whileLoop
	: WHILE valued_expression DO expression
{if(logSyntax)std::cout << "\n== WHILE valued_expression DO expression  -->  whileLoop \t\tnext token:'" << yytext << std::endl;}
	;



functionCall
	: IDENTIFIER '(' parameter_list ')'
{if(logSyntax)std::cout << "\n== IDENTIFIER '(' parameter_list ')'  -->  functionCall \t\tnext token:'" << yytext << std::endl;}
	;

parameter_declaration 
    : IDENTIFIER ',' parameter_declaration
{if(logSyntax)std::cout << "\n== IDENTIFIER ',' parameter_declaration --> parameter_declaration \t\tnext token:'" << yytext << std::endl;}
    | IDENTIFIER
{if(logSyntax)std::cout << "\n== IDENTIFIER --> parameter_declaration \t\tnext token:'" << yytext << std::endl;}
    |
    ;
	
parameter_list
	: valued_expression ',' parameter_list
{if(logSyntax)std::cout << "\n== valued_expression ',' parameter_list --> parameter_list \t\tnext token:'" << yytext << std::endl;}
	| valued_expression
{if(logSyntax)std::cout << "\n== valued_expression --> parameter_list \t\tnext token:'" << yytext << std::endl;}
	| STRING_LITERAL ',' parameter_list
{if(logSyntax)std::cout << "\n== STRING LITERAL ',' parameter_list --> parameter_list \t\tnext token:'" << yytext << std::endl;}
	| STRING_LITERAL
{if(logSyntax)std::cout << "\n== STRING LITERAL --> parameter_list \t\tnext token:'" << yytext << std::endl;}
	|
	;


ifThenStatement
	: ifThenElse
{if(logSyntax)std::cout << "\n== ifThenElse --> ifThenStatement \t\tnext token:'" << yytext << std::endl;}
	| ifThen
{if(logSyntax)std::cout << "\n== ifThen --> ifThenStatement \t\tnext token:'" << yytext << std::endl;}
	;


ifThenElse
	: IF valued_expression THEN expression ELSE expression
{if(logSyntax)std::cout << "\n== IF valued_expression THEN expression ELSE expression --> ifThenElse \t\tnext token:'" << yytext << std::endl;}
	;

ifThen
	: IF valued_expression THEN expression
{if(logSyntax)std::cout << "\n== IF valued_expression THEN expression --> ifThen \t\tnext token:'" << yytext << std::endl;}
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
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '&' " << *$3->pStr << " --> logic_expression \t\tnext token:'" << yytext << std::endl;}
	| logic_expression '|' logic_expression_com
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '|' " << *$3->pStr << " --> logic_expression \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com
	;

logic_expression_com
	: logic_expression_com '=' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '&' " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com NE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " NE_OP " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com '>' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '>' " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com '<' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '<' " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com GE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " GE_OP " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| logic_expression_com LE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " LE_OP " << *$3->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;}
	;


arithmetic_expression
	: arithmetic_expression '+' arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '+' " << *$3->pStr << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression '-' arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '-' " << *$3->pStr << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;}
	;

arithmetic_expression_md
	: arithmetic_expression_md '*' arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '*' " << *$3->pStr << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression_md '/' arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " '/' " << *$3->pStr << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;}
	;	

arithmetic_expression_con
	: '-' arithmetic_expression_value
{if(logSyntax)std::cout << "\n== '-' " << *$2->pStr << " --> arithmetic_expression_con \t\tnext token:'" << yytext << std::endl;}
	| arithmetic_expression_value
{if(logSyntax)std::cout << "\n== " << *$1->pStr << " --> arithmetic_expression_con \t\tnext token:'" << yytext << std::endl;}
	;

arithmetic_expression_value
	: IDENTIFIER
{if(logSyntax)std::cout << "\n== IDENTIFIER --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;}
	| CONSTANT
{if(logSyntax)std::cout << "\n== CONSTANT --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;}
	| functionCall
{if(logSyntax)std::cout << "\n== functionCall --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;}
	| '(' valued_expression ')'
{if(logSyntax)std::cout << "\n== '(' valued_expression ')' --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;}
	;


%%

