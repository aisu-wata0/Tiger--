
%{
#include <stdio.h>
#include <iostream>
#include <map>

#include "tiger--.tab.h"

#define logLex true

std::map<std::string,int> idCount;
std::map<std::string, Id> idTable;

template <class T>
inline T* tokenFound(bool text = true){
	if(logLex)
		std::cout << yytext;
	
	T *pNode = new T;
	yylval.Node = (STNode*)pNode;
	
	if(text)
		pNode->str = std::move(std::string(yytext));
	
	return pNode;
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
<C_COMMENT>\n			++yylineno;
<C_COMMENT><<EOF>>		yyerror("lexical: unclosed comment");

"*/"	{ // Unopened comment
	yyerror("lexical: unopened comment");
}

var	{
	tokenFound<STNode>();

	idCount["var"] += 1;
	return(VAR);
}

function	{
	tokenFound<STNode>();

	idCount["function"] += 1;
	return(FUNCTION);
}

if	{
	tokenFound<STNode>();

	idCount["if"] += 1;
	return(IF);
}

then	{
	tokenFound<STNode>();

	idCount["then"] += 1;
	return(THEN);
}

else	{
	tokenFound<STNode>();

	idCount["else"] += 1;
	return(ELSE);
}

while	{
	tokenFound<STNode>();

	idCount["while"] += 1;
	return(WHILE);
}

do	{
	tokenFound<STNode>();

	idCount["do"] += 1;
	return(DO);
}

let	{
	tokenFound<STNode>();

	idCount["let"] += 1;
	return(LET);
}

in	{
	tokenFound<STNode>();

	idCount["in"] += 1;
	return(IN);
}

end	{
	tokenFound<STNode>();

	idCount["end"] += 1;
	return(END);
}

":="	{
	tokenFound<STNode>();

	idCount[":="] += 1;
	return(ASSIGN);
}

";"	{
	tokenFound<STNode>();

	idCount[";"] += 1;
	return(';');
}

","	{
	tokenFound<STNode>();

	idCount[","] += 1;
	return(',');
}

"("	{
	tokenFound<STNode>();

	idCount["("] += 1;
	return('(');
}

")"	{
	tokenFound<STNode>();

	idCount[")"] += 1;
	return(')');
}

"+"	{
	tokenFound<STNode>();

	idCount["+"] += 1;
	return('+');
}

"-"	{
	tokenFound<STNode>();

	idCount["-"] += 1;
	return('-');
}

"*"	{
	tokenFound<STNode>();

	idCount["*"] += 1;
	return('*');
}

"/"	{
	tokenFound<STNode>();

	idCount["/"] += 1;
	return('/');
}

"="	{
	tokenFound<STNode>();

	idCount["="] += 1;
	return('=');
}

"<>"	{
	tokenFound<STNode>();

	idCount["<>"] += 1;
	return(NE_OP);
}

">"	{
	tokenFound<STNode>();

	idCount[">"] += 1;
	return('>');
}

"<"	{
	tokenFound<STNode>();

	idCount["<"] += 1;
	return('<');
}

">="	{
	tokenFound<STNode>();

	idCount[">="] += 1;
	return(GE_OP);
}

"<="	{
	tokenFound<STNode>();

	idCount["<="] += 1;
	return(LE_OP);
}

"&"	{
	tokenFound<STNode>();

	idCount["&"] += 1;
	return('&');
}

"|"	{
	tokenFound<STNode>();

	idCount["|"] += 1;
	return('|');
}

{identifier}	{
	auto lval = tokenFound<STNodeId>();
	
	std::string &id = lval->str;

	auto search = idTable.find(id);

	if(search != idTable.end()) {
		lval->type = search->second.type;
	} else {
		// find out in syntax what it is
		// and set
		// idTable[id] = type found;
	}
	
	lval->lineDeclared = yylineno;

	idCount["IDENTIFIER"] += 1;
	return(IDENTIFIER);
}

{unsigned_integer}	{
	auto lval = tokenFound<STNodeInt>();
	
	lval->value = atoi(yytext);
	
	idCount["CONSTANT"] += 1;
	return(CONSTANT);
}

{string}	{
	tokenFound<STNode>(false);
	
	std::string txt(yytext);
	
	std::ostringstream cleanedStr;
	cleanedStr << "\\\"" << txt.substr(1, txt.size()-2) << "\\\"";
	
	yylval.Node->str = cleanedStr.str();
	
	idCount["STRING_LITERAL"] += 1;
	return(STRING_LITERAL);
}

{bad_string} {	
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

