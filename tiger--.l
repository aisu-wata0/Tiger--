
%{
#include <stdio.h>
#include <iostream>
#include <map>

#include "tiger--.tab.h"

#define logToken true

std::map<std::string,int> idCount;
std::map<std::string, std::string> idTable;

%}


%x C_COMMENT

white_space       [ \t]*
digit             [0-9]
alpha             [A-Za-z_]
alpha_num         ({alpha}|{digit})
hex_digit         [0-9A-F]
identifier        [A-Za-z]|([A-Za-z]{alpha_num}*)
unsigned_integer  {digit}+
hex_integer       ${hex_digit}{hex_digit}*
exponent          e[+-]?{digit}+
i                 {unsigned_integer}
real              ({i}\.{i}?|{i}?\.{i}){exponent}?
string            \"([^"\n]|\"\")+\"
bad_string        \"([^"\n]|\"\")+

%%

"/*"					BEGIN(C_COMMENT);
<C_COMMENT>"*/"			BEGIN(INITIAL);
<C_COMMENT>"/*"			{} // ignore nested comments
<C_COMMENT>[^*/\n]+		// ignore
<C_COMMENT>\n			++yylineno;
<C_COMMENT><<EOF>>		yyerror("EOF in comment");

"*/"	{ // Unopened comment
	idCount["UNKNOWN"] += 1;
	return(UNKNOWN);
}

var	{
	if(logToken)
		std::cout << yytext;

	idCount["var"] += 1;
	return(VAR);
}

function	{
	if(logToken)
		std::cout << yytext;

	idCount["function"] += 1;
	return(FUNCTION);
}

if	{
	if(logToken)
		std::cout << yytext;

	idCount["if"] += 1;
	return(IF);
}

then	{
	if(logToken)
		std::cout << yytext;

	idCount["then"] += 1;
	return(THEN);
}

else	{
	if(logToken)
		std::cout << yytext;

	idCount["else"] += 1;
	return(ELSE);
}

while	{
	if(logToken)
		std::cout << yytext;

	idCount["while"] += 1;
	return(WHILE);
}

do	{
	if(logToken)
		std::cout << yytext;

	idCount["do"] += 1;
	return(DO);
}

let	{
	if(logToken)
		std::cout << yytext;

	idCount["let"] += 1;
	return(LET);
}

in	{
	if(logToken)
		std::cout << yytext;

	idCount["in"] += 1;
	return(IN);
}

end	{
	if(logToken)
		std::cout << yytext;

	idCount["end"] += 1;
	return(END);
}

":="	{
	if(logToken)
		std::cout << yytext;

	idCount[":="] += 1;
	return(ASSIGN);
}

";"	{
	if(logToken)
		std::cout << yytext;

	idCount[";"] += 1;
	return(';');
}

","	{
	if(logToken)
		std::cout << yytext;

	idCount[","] += 1;
	return(',');
}

"("	{
	if(logToken)
		std::cout << yytext;

	idCount["("] += 1;
	return('(');
}

")"	{
	if(logToken)
		std::cout << yytext;

	idCount[")"] += 1;
	return(')');
}

"+"	{
	if(logToken)
		std::cout << yytext;

	idCount["+"] += 1;
	return('+');
}

"-"	{
	if(logToken)
		std::cout << yytext;

	idCount["-"] += 1;
	return('-');
}

"*"	{
	if(logToken)
		std::cout << yytext;

	idCount["*"] += 1;
	return('*');
}

"/"	{
	if(logToken)
		std::cout << yytext;

	idCount["/"] += 1;
	return('/');
}

"="	{
	if(logToken)
		std::cout << yytext;

	idCount["="] += 1;
	return('=');
}

"<>"	{
	if(logToken)
		std::cout << yytext;

	idCount["<>"] += 1;
	return(NE_OP);
}

">"	{
	if(logToken)
		std::cout << yytext;

	idCount[">"] += 1;
	return('>');
}

"<"	{
	if(logToken)
		std::cout << yytext;

	idCount["<"] += 1;
	return('<');
}

">="	{
	if(logToken)
		std::cout << yytext;

	idCount[">="] += 1;
	return(GE_OP);
}

"<="	{
	if(logToken)
		std::cout << yytext;

	idCount["<="] += 1;
	return(LE_OP);
}

"&"	{
	if(logToken)
		std::cout << yytext;

	idCount["&"] += 1;
	return('&');
}

"|"	{
	if(logToken)
		std::cout << yytext;

	idCount["|"] += 1;
	return('|');
}

{identifier}	{
	if(logToken)
		std::cout << yytext;
	
	std::string id(yytext);
	
	auto search = idTable.find(id);

  if(search != idTable.end()) {
		yylval.pStr = &search->second;
  } else {
  // copy string to permanent entry
  	idTable[id] = id;
		yylval.pStr = &idTable[id];
  }
  
	idCount["IDENTIFIER"] += 1;
	return(IDENTIFIER);
}

{unsigned_integer}	{
	if(logToken)
		std::cout << yytext;
	
	yylval.fn = atoi(yytext);
	
	idCount["CONSTANT"] += 1;
	return(CONSTANT);
}

{string}	{
	if(logToken)
		std::cout << yytext;
	
	idCount["STRING_LITERAL"] += 1;
	return(STRING_LITERAL);
}

{white_space}	{
	if(logToken)
		std::cout << yytext;
	
}/* no effect */

\n	{
	if(logToken)
		std::cout << yytext;
	
	++yylineno;
}


 /*.	yyerror("Illegal input"); */

.	{
	if(logToken)
		std::cout << yytext;
	
	idCount["UNKNOWN"] += 1;
	return(UNKNOWN);
}


%%

/*
int mein()
{
	
	yylex();
	
	for(auto it = idCount.begin(); it != idCount.end() ; ++it){
		std::cout << it->first << " : " << it->second << "\n";
	}

	return 0;
}

*/

