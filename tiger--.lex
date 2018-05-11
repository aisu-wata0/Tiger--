
%{

#include <stdio.h>
#include <iostream>
#include <map>
// #include "y.tab.h"

int lineNumber = 0;

std::map<std::string,int> idCount;

void yyerror(const std::string & msg)
{
	std::cerr << "Error: " << msg << " in line " << lineNumber << ". Token = " << yytext << "\n";
	
	exit(1);
}

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
<C_COMMENT>\n			++lineNumber;
<C_COMMENT><<EOF>>		yyerror("EOF in comment");

"*/"	{ // Unopened comment
	idCount["UNKNOWN"] += 1;
	return(UNKNOWN);
}

var	{
	idCount["var"] += 1;
	return(VAR);
}

function	{
	idCount["function"] += 1;
	return(FUNCTION);
}

if	{
	idCount["if"] += 1;
	return(IF);
}

then	{
	idCount["then"] += 1;
	return(THEN);
}

else	{
	idCount["else"] += 1;
	return(ELSE);
}

while	{
	idCount["while"] += 1;
	return(WHILE);
}

do	{
	idCount["do"] += 1;
	return(DO);
}

let	{
	idCount["let"] += 1;
	return(LET);
}

in	{
	idCount["in"] += 1;
	return(IN);
}

end	{
	idCount["end"] += 1;
	return(END);
}

":="	{
	idCount[":="] += 1;
	return(ASSIGN);
}

";"	{
	idCount[";"] += 1;
	return(';');
}

","	{
	idCount[","] += 1;
	return(',');
}

"("	{
	idCount["("] += 1;
	return('(');
}

")"	{
	idCount[")"] += 1;
	return(')');
}

"+"	{
	idCount["+"] += 1;
	return('+');
}

"-"	{
	idCount["-"] += 1;
	return('-');
}

"*"	{
	idCount["*"] += 1;
	return('*');
}

"/"	{
	idCount["/"] += 1;
	return('/');
}

"="	{
	idCount["="] += 1;
	return('=');
}

"<>"	{

	idCount["<>"] += 1;
	return(NE_OP);
}

">"	{
	idCount[">"] += 1;
	return('>');
}

"<"	{
	idCount["<"] += 1;
	return('<');
}

">="	{
	idCount[">="] += 1;
	return(GE_OP);
}

"<="	{
	idCount["<="] += 1;
    return(LE_OP);
}

"&"	{
	idCount["&"] += 1;
    return('&');
}

"|"	{
	idCount["|"] += 1;
    return('|');
}

{identifier}	{ idCount["IDENTIFICADOR"] += 1; }

{unsigned_integer}	{
	idCount["INTEIRO"] += 1;
}

{string}	{
	idCount["{string}"] += 1;
}

{white_space}	/* no effect */

\n	{
	++lineNumber;
}


 /*.	yyerror("Illegal input"); */

.	{
	idCount["UNKNOWN"] += 1;
}


%%


int main()
{
	
	yylex();
	
	for(auto it = idCount.begin(); it != idCount.end() ; ++it){
		std::cout << it->first << " : " << it->second << "\n";
	}

	return 0;
}


