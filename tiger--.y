
%precedence THEN
%precedence ELSE

%left '&' '|'
%left '<' '>' '=' NE_OP LE_OP GE_OP
%left '+' '-'
%left '*' '/'
%left UMINUS

%token IDENTIFIER CONSTANT STRING_LITERAL
%token IF WHILE DO
%token ASSIGN END LET FUNCTION VAR
%token IN

%expect 1 // ctrl+f "conflict" for explanations

%start program

%{

#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <stdio.h>
#include <ctype.h>
#include <string>
#include <vector>
#include <sstream>
#include <fstream>
#include <map>
#include <algorithm>

#define logSyntax true
//#define YYSTYPE class STNode *

extern FILE *fp;

extern char *yytext;
extern int yylex();
extern int yylineno;
//extern int column;
int errorNo = 0;
int warnNo = 0;

void yyerror(const std::string & msg, const std::string & note = "")
{
	++errorNo;
	std::cerr << std::endl
	<< "error: " << msg << " in line " << yylineno << ". \tNext token: " << yytext << std::endl;
	std::cerr << note << std::endl;
}

void yywarn(const std::string & msg, const std::string & note = "")
{
	++warnNo;
	std::cerr << std::endl
	<< "warning: " << msg << " in line " << yylineno << ". Token = " << yytext << std::endl;
	std::cerr << note << std::endl;
}


void replaceAll(std::string& str, const std::string& from, const std::string& to) {
    if(from.empty())
        return;
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // In case 'to' contains 'from', like replacing 'x' with 'yx'
    }
}

//!!! Subtract extra lines from TypeSTART_LINE if an entry takes more than one
constexpr auto TypeSTART_LINE = __LINE__;
enum class Type { // Each line has to be an enum, se above
	Void,
	Str,
	Int,
};
constexpr auto TypeMax = __LINE__ - TypeSTART_LINE - 4;

std::ostream& operator<<(std::ostream& out, const Type value){
	std::string s;
#define CASE_VAL(p) case(p): s = #p; break;
	switch(value){
		CASE_VAL(Type::Void);
		CASE_VAL(Type::Str);
		CASE_VAL(Type::Int);
		default:
			s = "UnknownType";
	}
#undef CASE_VAL

	return out << s;
}

class Id {
public:
	int lineDeclared;
	Type type;
};

class STNode {
public:
	std::string code;
	std::string rule;
	std::vector<STNode*> childs;

	void pushChilds(const std::vector<STNode*> & childs, const std::string & prefix = ""){
		for(auto it : childs){
			std::string childCode(it->code);
			replaceAll(childCode, "\\l", "\\l" + prefix);
			//childCode = prefix + childCode;
			this->code += "" + childCode;
			this->childs.push_back(it);
		}
	}

	void printChilds(const std::string & prefix, std::ofstream & os, int & numberId){
		int myId = numberId;
		++numberId;
		for(auto it : childs){
			//os << prefix << graphNode(this, myId) << " -> " << graphNode(it, numberId) << std::endl;
			os << prefix << "\"" << myId << "\\n" << this->rule << "\\n" << code << "\" -> \"" << numberId << "\\n" << it->rule << "\\n" << it->code << "\"" << std::endl;

			it->printChilds(prefix+"\t", os, numberId);
		}
	}
};

class STNodeExp : public STNode {
public:
	Type type;
};

class STNodeId : public STNodeExp {
public:
	int lineDeclared;
};

class STNodeInt : public STNodeExp {
public:
	int value;
};

std::map<std::string, Id> idTable;

void checkDeclare(const std::string & id) {
	auto search = idTable.find(id);
	if(search != idTable.end()) {
		std::ostringstream msg, note;
		msg << "semantic: redeclaration of '" << id << "'\n";
		note << "note: previous declaration of '" << id << "' was in line " << search->second.lineDeclared << "\n";
		yyerror(msg.str(), note.str());
	}
}

void checkType(Type t1, Type t2) {/**
	if(t1 != t2){
		std::ostringstream msg;
		msg << "semantic: type mismatch '" << t1 << "' with '" << t2 << "'\n";
		yyerror(msg.str());
	}
/**/
}
void checkTypeID(STNodeId* node1, Type t2) {/**
	if(node1->type != t2){
		std::ostringstream msg, note;
		msg << "semantic: type mismatch '" << node1->type << "' with '" << t2 << "' ";
		note << "note: previous declaration of '" << node1->code << "' was in line " << node1->lineDeclared << "\n";
		yyerror(msg.str(), note.str());
	}
/**/
}


#include "lex.yy.c"

int count = 0;
int graphviz = 0;
STNode *root;

int main(int argc, char *argv[])
{
	int i = 1;

	if(argc > 1)
	if(strcmp(argv[i], "-g") == 0){
		graphviz = 1;
		++i;
	}

	yyin = fopen(argv[i], "r");

	int result = yyparse();

	fclose(yyin);

	if(errorNo > 0){
		printf("\n\nParsing failed\n\n");
	} else {
		printf("\n\nParsing completed\n\n");
	}

	std::string schar;

	if(errorNo>0){
		schar = "s";
		if(errorNo == 1)
			schar = "";
		std::cout << errorNo << " error"+schar << "\n";
	}

	if(warnNo>0){
		schar = "s";
		if(warnNo == 1)
			schar = "";
		std::cout << warnNo << " warning"+schar << std::endl;
	}

	if(graphviz){
		std::string filename("./derivationTree.dot");
		std::ofstream fileStream(filename);

		fileStream << "digraph G {" << std::endl;

		fileStream << "\tgraph [fontname = \"monospace\"];\n"
		<< "\tnode [fontname = \"monospace\"];\n"
		<< "\tedge [fontname = \"monospace\"];\n";
		int numberOfNodes = 0;
		root->printChilds("", fileStream, numberOfNodes);
		fileStream << "}" << std::endl;

		std::cout << "\n\tSummoning dot and opening resulting graph picture\n" << std::endl;

		std::string command = "dot -Tpng " + filename + " -O";
		std::cout << command << std::endl;
		system(command.c_str());

		command = ("xdg-open " + filename + ".png&");
		std::cout << command << std::endl;
		system(command.c_str());
	}

	if(errorNo > 0){
		exit(EXIT_FAILURE);
	}

	return 0;
}

%}

%union{
	int *p;
	STNode *Node;
	STNodeExp *Exp;
	STNodeId *Id;
	STNodeInt *Int;
}

%type <Int> logicExp logicExpCom arithExp arithExpMd arithExpCon arithExpValue;

%type <Exp> letExp program

%type <Node> declarationList declaration declarationVar declarationFunc

%type <Exp> expressionList expression
%type <Exp> voidExp
%type <Exp> valuedExp
%type <Exp> sequence
%type <Node> attribution whileLoop
%type <Exp> functionCall
%type <Node> parameter_declaration parameterList ifThenExp ifThenElse ifThen

%type <Int> CONSTANT
%type <Id> IDENTIFIER
%type <Exp> STRING_LITERAL
%type <Node> '&' '|'
%type <Node> '<' '>' '=' NE_OP LE_OP GE_OP
%type <Node> '+' '-'
%type <Node> '*' '/'
%type <Node> '(' ')' ',' ';'
%type <Node> IF ELSE WHILE DO
%type <Node> ASSIGN END LET THEN FUNCTION VAR
%type <Node> IN

%%

program
	: letExp
{
$1->code += "\\l";

root = $1;

if(logSyntax)std::cout << "\n==  letExp -->  program \t\tnext token: " << yytext << std::endl;
}

	;


letExp
	: LET declarationList IN expressionList END
{
$$ = new STNodeExp;
$$->type = $4->type;

$$->rule = "letExp";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$2}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$5});
if(logSyntax)std::cout << "\n==  LET declarationList IN expressionList END -->  letExp \t\tnext token: " << yytext << std::endl;
}

/* // TODO: warnings
	| VAR

{yyerror("syntax: missing let");}
	| LET declarationList expression
{yyerror("syntax: missing in");}
	| LET declarationList IN expressionList
{yyerror("syntax: missing end");}
*/
	;


declarationList
	: declarationList declaration
{
$$ = new STNode;

$$->rule = "declarationList";
$$->pushChilds(std::vector<STNode*>{$1});
if($1->code != ""){
	$$->code += "\\l";
}
$$->pushChilds(std::vector<STNode*>{$2});
if(logSyntax)std::cout << "\n== declarationList declaration  -->  declarationList \t\tnext token: " << yytext << std::endl;
}

	| // empty
{
$$ = new STNode;

$$->rule = "declarationList";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n==   -->  declarationList \t\tnext token: " << yytext << std::endl;
}

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valuedExp
{
$$ = new STNode;

std::string &id = $2->code;
checkDeclare(id);
idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $4->type;

$$->rule = "declarationVar";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4});
if(logSyntax)std::cout << "\n== VAR IDENTIFIER ASSIGN valuedExp  -->  declarationVar \t\tnext token: " << yytext << std::endl;
}

	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression
{
$$ = new STNode;

std::string &id = $2->code;
checkDeclare(id);
idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $7->type;

$$->rule = "declarationFunc";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4, $5, $6});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$7}, "\t");
if(logSyntax)std::cout << "\n== FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression  -->  declarationFunc \t\tnext token: " << yytext << std::endl;
}

	;

parameter_declaration
    : parameter_declaration ',' IDENTIFIER
{
$$ = new STNode;
$$->rule = "parameter_declaration";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== IDENTIFIER ',' parameter_declaration --> parameter_declaration \t\tnext token: " << yytext << std::endl;
}

    | IDENTIFIER
{
if(logSyntax)std::cout << "\n== IDENTIFIER --> parameter_declaration \t\tnext token: " << yytext << std::endl;
}

    | // empty
{
$$ = new STNode;
$$->rule = "parameter_declaration";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n==  --> parameter_declaration \t\tnext token: " << yytext << std::endl;
}
    ;


expressionList
	: expressionList ';' expression
{
$$ = new STNodeExp;
$$->rule = "expressionList";
$$->type = $3->type;

$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$3});
if(logSyntax)std::cout << "\n==  expressionList ';' expression  -->  expressionList \t\tnext token: " << yytext << std::endl;
}

	| expression
{
$$ = new STNodeExp;
$$->type = $1->type;

$$->rule = "expressionList";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n== expression  -->  expressionList \t\tnext token: " << yytext << std::endl;
}

	| error
{
$$ = new STNodeExp;
$$->code = std::move("ERROR");

$$->rule = "expressionList";
if(logSyntax)std::cout << "\n== ERROR  -->  expressionList \t\tnext token: " << yytext << std::endl;
}

/* //TODO: warnings
	| whileLoop expressionList
{
$$ = new STNodeExp;
$$->rule = "expressionList";
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

if(logSyntax)std::cout << "\n==  whileLoop expressionList  -->  expressionList \t\tnext token: " << yytext << std::endl;
yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}

	| ifThenExp expressionList
{
$$ = new STNodeExp;
$$->rule = "expressionList";
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

if(logSyntax)std::cout << "\n==  ifThenExp expressionList  -->  expressionList \t\tnext token: " << yytext << std::endl;
yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}

	| expression ';'
{
$$ = new STNodeExp;
$$->rule = "expressionList";
$$->type = $1->type;
$$->pushChilds(std::vector<STNode*>{$1, $2});

if(logSyntax)std::cout << "\n== expression ';'  -->  expressionList \t\tnext token: " << yytext << std::endl;
yywarn("syntax: extra ';' after last expression in sequence", "note: code: " + $1->code);
}
*/

	;


expression
	: voidExp
{
$1->type = Type::Void;

if(logSyntax)std::cout << "\n== voidExp  -->  expression \t\tnext token: " << yytext << std::endl;
}

	| valuedExp
{
if(logSyntax)std::cout << "\n== valuedExp  -->  expression \t\tnext token: " << yytext << std::endl;
}

	;


voidExp
	: ifThenExp
{
if(logSyntax)std::cout << "\n== ifThenExp  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| whileLoop
{
if(logSyntax)std::cout << "\n== whileLoop  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| attribution
{
if(logSyntax)std::cout << "\n== attribution  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| // empty
{
$$ = new STNodeExp;

$$->rule = "voidExp";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n==   -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	;

valuedExp
	: logicExp
{
if(logSyntax)std::cout << "\n== logicExp  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}
	;

sequence
	: '(' expressionList ')'
{
$$ = new STNodeExp;
$$->rule = "sequence";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->type = $2->type;
if(logSyntax)std::cout << "\n== '(' expressionList ')'  -->  sequence \t\tnext token: " << yytext << std::endl;
}

	;



attribution
	: IDENTIFIER ASSIGN valuedExp
{
$$ = new STNodeExp;
checkTypeID($1, $3->type);

$$->rule = "attribution";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== IDENTIFIER ASSIGN valuedExp  -->  attribution \t\tnext token: " << yytext << std::endl;
}

	;


whileLoop
	: WHILE valuedExp DO expression
{
$$ = new STNodeExp;

$$->rule = "whileLoop";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
if(logSyntax)std::cout << "\n== WHILE valuedExp DO expression  -->  whileLoop \t\tnext token: " << yytext << std::endl;
}
	;



functionCall // TODO: semantic: maybe this ID was not declared
// maybe this ID was not a function, but a var
	: IDENTIFIER '(' parameterList ')'
{
$$ = new STNodeExp;
$$->type = $1->type;

$$->rule = "functionCall";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4});
if(logSyntax)std::cout << "\n== IDENTIFIER '(' parameterList ')'  -->  functionCall \t\tnext token: " << yytext << std::endl;
}

	| IDENTIFIER '(' ')'
{
$$ = new STNodeExp;
$$->type = $1->type;

$$->rule = "functionCall";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== IDENTIFIER '(' ')'  -->  functionCall \t\tnext token: " << yytext << std::endl;
}
	;

parameterList
	: valuedExp ',' parameterList
{
$$ = new STNode;
$$->rule = "parameterList";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== valuedExp ',' parameterList --> parameterList \t\tnext token: " << yytext << std::endl;
}
	| valuedExp
{
if(logSyntax)std::cout << "\n== valuedExp --> parameterList \t\tnext token: " << yytext << std::endl;
}
	;


ifThenExp
	: ifThenElse
{
if(logSyntax)std::cout << "\n== ifThenElse --> ifThenExp \t\tnext token: " << yytext << std::endl;
}

	| ifThen
{
if(logSyntax)std::cout << "\n== ifThen --> ifThenExp \t\tnext token: " << yytext << std::endl;
}

	;


ifThenElse
	: IF valuedExp THEN expression ELSE expression
{
$$ = new STNodeExp;

$$->rule = "ifThenElse";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$5});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$6}, "\t");
if(logSyntax)std::cout << "\n== IF valuedExp THEN expression ELSE expression --> ifThenElse \t\tnext token: " << yytext << std::endl;
}
	;

ifThen
	: IF valuedExp THEN expression
{
$$ = new STNodeExp;

$$->rule = "ifThen";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
if(logSyntax)std::cout << "\n== IF valuedExp THEN expression --> ifThen \t\tnext token: " << yytext << std::endl;
}
	;


logicExp
	: logicExp '&' logicExpCom
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logicExp \t\tnext token: " << yytext << std::endl;
}

	| logicExp '|' logicExpCom
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '|' " << $3->code << " --> logicExp \t\tnext token: " << yytext << std::endl;
}
	| logicExpCom
	;

logicExpCom
	: logicExpCom '<' arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '<' " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| logicExpCom '>' arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '>' " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| logicExpCom '=' arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| logicExpCom NE_OP arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " NE_OP " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| logicExpCom LE_OP arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " LE_OP " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| logicExpCom GE_OP arithExp
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "logicExpCom";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " GE_OP " << $3->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	| arithExp
{
if(logSyntax)std::cout << "\n== " << $1->code << " --> logicExpCom \t\tnext token: " << yytext << std::endl;
}

	;


arithExp
	: arithExp '+' arithExpMd
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "arithExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '+' " << $3->code << " --> arithExp \t\tnext token: " << yytext << std::endl;
}
	| arithExp '-' arithExpMd
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "arithExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '-' " << $3->code << " --> arithExp \t\tnext token: " << yytext << std::endl;
}
	| arithExpMd
{
if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExp \t\tnext token: " << yytext << std::endl;
}

	;

arithExpMd
	: arithExpMd '*' arithExpCon
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "arithExpMd";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << "*" << $3->code << " --> arithExpMd \t\tnext token: " << yytext << std::endl;
}

	| arithExpMd '/' arithExpCon
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "arithExpMd";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== " << $1->code << " '/' " << $3->code << " --> arithExpMd \t\tnext token: " << yytext << std::endl;
}

	| arithExpCon
{
if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExpMd \t\tnext token: " << yytext << std::endl;
}

	;

arithExpCon
	: '-' arithExpValue
%prec UMINUS
{
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $2->type;

$$->rule = "arithExpCon";
$$->pushChilds(std::vector<STNode*>{$1, $2});
if(logSyntax)std::cout << "\n== '-' " << $2->code << " --> arithExpCon \t\tnext token: " << yytext << std::endl;
}

	| arithExpValue
{
if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExpCon \t\tnext token: " << yytext << std::endl;
}

	;

// TODO: semantic: check types
arithExpValue
	: IDENTIFIER
{
//std::cout << "\n" << $1->type << " " << $1->code << std::endl;

if(logSyntax)std::cout << "\n== IDENTIFIER --> arithExpValue \t\tnext token: " << yytext << std::endl;
} // TODO: semantic: may be function id without calling

	| CONSTANT
{
if(logSyntax)std::cout << "\n== CONSTANT --> arithExpValue \t\tnext token: " << yytext << std::endl;
}

	| functionCall
{
if(logSyntax)std::cout << "\n== functionCall --> arithExpValue \t\tnext token: " << yytext << std::endl;
}

	| sequence
{
if(logSyntax)std::cout << "\n== sequence  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

	| STRING_LITERAL
{
if(logSyntax)std::cout << "\n== STRING_LITERAL  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

	| letExp
{
if(logSyntax)std::cout << "\n== letExp  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

// s-r conflict: this could be a sequence (expression): shift ')', instead of reducing valuedExp -> expression
	| '(' valuedExp ')'
{
$$ = new STNodeInt;
$$->type = $2->type;

$$->rule = "arithValue";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== '(' valuedExp ')' --> arithExpValue \t\tnext token: " << yytext << std::endl;
}

	;


%%
