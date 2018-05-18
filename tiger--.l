
%{
#include <stdio.h>
#include <iostream>
#include <map>

#include "tiger--.tab.h"

#define logLex true

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
<C_COMMENT><<EOF>>		yyerror("lexical: unclosed comment");

"*/"	{ // Unopened comment
	yyerror("lexical: unopened comment");
}

var	{
	if(logLex)
		std::cout << yytext;

	idCount["var"] += 1;
	return(VAR);
}

function	{
	if(logLex)
		std::cout << yytext;

	idCount["function"] += 1;
	return(FUNCTION);
}

if	{
	if(logLex)
		std::cout << yytext;

	idCount["if"] += 1;
	return(IF);
}

then	{
	if(logLex)
		std::cout << yytext;

	idCount["then"] += 1;
	return(THEN);
}

else	{
	if(logLex)
		std::cout << yytext;

	idCount["else"] += 1;
	return(ELSE);
}

while	{
	if(logLex)
		std::cout << yytext;

	idCount["while"] += 1;
	return(WHILE);
}

do	{
	if(logLex)
		std::cout << yytext;

	idCount["do"] += 1;
	return(DO);
}

let	{
	if(logLex)
		std::cout << yytext;

	idCount["let"] += 1;
	return(LET);
}

in	{
	if(logLex)
		std::cout << yytext;

	idCount["in"] += 1;
	return(IN);
}

end	{
	if(logLex)
		std::cout << yytext;

	idCount["end"] += 1;
	return(END);
}

":="	{
	if(logLex)
		std::cout << yytext;

	idCount[":="] += 1;
	return(ASSIGN);
}

";"	{
	if(logLex)
		std::cout << yytext;

	idCount[";"] += 1;
	return(';');
}

","	{
	if(logLex)
		std::cout << yytext;

	idCount[","] += 1;
	return(',');
}

"("	{
	if(logLex)
		std::cout << yytext;

	idCount["("] += 1;
	return('(');
}

")"	{
	if(logLex)
		std::cout << yytext;

	idCount[")"] += 1;
	return(')');
}

"+"	{
	if(logLex)
		std::cout << yytext;

	idCount["+"] += 1;
	return('+');
}

"-"	{
	if(logLex)
		std::cout << yytext;

	idCount["-"] += 1;
	return('-');
}

"*"	{
	if(logLex)
		std::cout << yytext;

	idCount["*"] += 1;
	return('*');
}

"/"	{
	if(logLex)
		std::cout << yytext;

	idCount["/"] += 1;
	return('/');
}

"="	{
	if(logLex)
		std::cout << yytext;

	idCount["="] += 1;
	return('=');
}

"<>"	{
	if(logLex)
		std::cout << yytext;

	idCount["<>"] += 1;
	return(NE_OP);
}

">"	{
	if(logLex)
		std::cout << yytext;

	idCount[">"] += 1;
	return('>');
}

"<"	{
	if(logLex)
		std::cout << yytext;

	idCount["<"] += 1;
	return('<');
}

">="	{
	if(logLex)
		std::cout << yytext;

	idCount[">="] += 1;
	return(GE_OP);
}

"<="	{
	if(logLex)
		std::cout << yytext;

	idCount["<="] += 1;
	return(LE_OP);
}

"&"	{
	if(logLex)
		std::cout << yytext;

	idCount["&"] += 1;
	return('&');
}

"|"	{
	if(logLex)
		std::cout << yytext;

	idCount["|"] += 1;
	return('|');
}

{identifier}	{
	if(logLex)
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
	if(logLex)
		std::cout << yytext;
	
	yylval.fn = atoi(yytext);
	
	idCount["CONSTANT"] += 1;
	return(CONSTANT);
}

{string}	{
	if(logLex)
		std::cout << yytext;
	
	idCount["STRING_LITERAL"] += 1;
	return(STRING_LITERAL);
}

{bad_string} {
	if(logLex)
		std::cout << yytext;
	
	yyerror("lexical: unclosed string");
}

{white_space}	{
	if(logLex)
		std::cout << yytext;
	
}/* no effect */

\n	{
	if(logLex)
		std::cout << yytext;
	
	++yylineno;
}


.	{
	if(logLex)
		std::cout << yytext;
	
	yyerror("lexical: illegal input");
}


%%

/*
int main()
{
	yylex();
	
	for(auto it = idCount.begin(); it != idCount.end() ; ++it){
		std::cout << it->first << " : " << it->second << "\n";
	}

	return 0;
}

*/

