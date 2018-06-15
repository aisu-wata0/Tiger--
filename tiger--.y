
%precedence THEN
%precedence ELSE

%nonassoc LGCOP '&' '|'
%nonassoc CMPOP '<' '>' '=' NE_OP LE_OP GE_OP
%left ADDOP '+' '-'
%left MULOP '*' '/' // '%'
%left UMINUS

%token IDENTIFIER CONSTANT STRING_LITERAL
%token IF WHILE DO
%token ASSIGN END LET FUNCTION VAR
%token IN

%expect 1 // ctrl+f "conflict" for explanations
%locations

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

#define logSyntax false
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
	<< "error: " << msg << " in line " << yylineno << ".\n\tNext token: " << yytext << std::endl;
	if(note != "")
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

void checkType(Type t1, Type t2) {/** TODO
	if(t1 != t2){
		std::ostringstream msg;
		msg << "semantic: type mismatch '" << t1 << "' with '" << t2 << "'\n";
		yyerror(msg.str());
	}
/**/
}
void checkTypeID(STNodeId* node1, Type t2) {/** TODO
	if(node1->type != t2){
		std::ostringstream msg, note;
		msg << "semantic: type mismatch '" << node1->type << "' with '" << t2 << "' ";
		note << "note: previous declaration of '" << node1->code << "' was in line " << node1->lineDeclared << "\n";
		yyerror(msg.str(), note.str());
	}
/**/
}


#include "lex.yy.c"

void unexpectedToken(const std::string & msg, YYLTYPE err){
	std::cerr << msg << std::endl;
	std::cerr << "error start line:column " << err.first_line << ":" << err.first_column << std::endl;
	std::cerr << "error end   line:column " << err.last_line << ":" << err.last_column << std::endl;
}

int count = 0;
int graphviz = 0;
int graphvizPNG = 0;
STNode *root = nullptr;

int main(int argc, char *argv[])
{
	int i = 1;

	if(argc > 1){
		if(strcmp(argv[i], "-g") == 0){
			graphviz = 1;
			++i;
		}
		if(strcmp(argv[i], "-G") == 0){
			graphviz = 1;
			graphvizPNG = 1;
			++i;
		}
	}

	yyin = fopen(argv[i], "r");

	int result = yyparse();

	fclose(yyin);

	if(errorNo > 0){
		std::cout << "\nParsing failed\n";
	}

	std::string schar;

	if(errorNo > 0){
		schar = "s";
		if(errorNo == 1)
			schar = "";
		std::cout << errorNo << " error"+schar << "\n";
	}

	if(warnNo > 0){
		schar = "s";
		if(warnNo == 1)
			schar = "";
		std::cout << warnNo << " warning"+schar << std::endl;
	}

	if(graphviz && root != nullptr){
		std::cout << "\n\tWriting derivation tree to dot file" << std::endl;

		std::string filename("./derivationTree.dot");
		std::ofstream fileStream(filename);

		fileStream << "digraph G {" << std::endl;

		fileStream << "\tgraph [fontname = \"monospace\"];\n"
		<< "\tnode [fontname = \"monospace\"];\n"
		<< "\tedge [fontname = \"monospace\"];\n";
		int numberOfNodes = 0;
		root->printChilds("", fileStream, numberOfNodes);
		fileStream << "}" << std::endl;


		if(graphvizPNG){
			std::cout << "\n\tSummoning dot and opening resulting graph picture\n" << std::endl;

			std::string command = "dot -Tpng " + filename + " -O";
			std::cout << command << std::endl;
			int result;
			result = system(command.c_str());
			if(result < 0)
				std::cerr << "Command: \"" << command << "\" failed" << std::endl;

			command = ("xdg-open " + filename + ".png&");
			std::cout << command << std::endl;
			result = system(command.c_str());
			if(result < 0)
				std::cerr << "Command: \"" << command << "\" failed" << std::endl;
		}
	}

	if(errorNo > 0){
		exit(EXIT_FAILURE);
	}

	return EXIT_SUCCESS;
}


%}

%error-verbose

%union{
	int *p;
	STNode *Node;
	STNodeExp *Exp;
	STNodeId *Id;
	STNodeInt *Int;
}



%type <Node> declarationList declaration declarationVar declarationFunc

%type <Exp> functionCall
%type <Exp> expressionList expression
%type <Exp> sequence
%type <Exp> letExp program
%type <Exp> valuedExp valuedExpValue
%type <Exp> voidExp
%type <Node> attribution whileLoop
%type <Node> parameterDeclaration parameterList
%type <Node> ifThenExp ifThenElse ifThen

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
	: expression
{
$1->code += "\\l";

root = $1;

if(logSyntax)std::cout << "\n REDUCE:   letExp -->  program \t\tnext token: " << yytext << std::endl << "lines: " << yylineno << std::endl;
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
if(logSyntax)std::cout << "\n REDUCE:   LET declarationList IN expressionList END -->  letExp \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| LET declarationList error expressionList END
{
$$ = new STNodeExp;
$$->type = $4->type;

$$->rule = "letExp";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$2}, "\t");
$$->code += "\\l";
$$->code += "ERROR";
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$5});
if(logSyntax)std::cout << "\n REDUCE:   LET declarationList ERROR expressionList END -->  letExp \t\tnext token: " << yytext << std::endl;
unexpectedToken("Missing 'in' in let expression", @3);
}
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
if(logSyntax)std::cout << "\n REDUCE:  declarationList declaration  -->  declarationList \t\tnext token: " << yytext << std::endl;
}

	| // empty
{
$$ = new STNode;

$$->rule = "declarationList";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n REDUCE:    -->  declarationList \t\tnext token: " << yytext << std::endl;
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
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2, $3, $4});
if(logSyntax)std::cout << "\n REDUCE:  VAR IDENTIFIER ASSIGN valuedExp  -->  declarationVar \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| VAR IDENTIFIER error valuedExp
{
$$ = new STNode;

std::string &id = $2->code;
checkDeclare(id);
idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $4->type;

$$->rule = "declarationVar";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ERROR ";
$$->pushChilds(std::vector<STNode*>{$4});
if(logSyntax)std::cout << "\n REDUCE:  error IDENTIFIER ASSIGN valuedExp  -->  declarationVar \t\tnext token: " << yytext << std::endl;
unexpectedToken("Missing ':=' in var declaration", @3);
}

	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameterDeclaration ')' ASSIGN expression
{
$$ = new STNode;

std::string &id = $2->code;
checkDeclare(id);
idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $7->type;

$$->rule = "declarationFunc";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2, $3, $4, $5, $6});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$7}, "\t");
if(logSyntax)std::cout << "\n REDUCE:  FUNCTION IDENTIFIER '(' parameterDeclaration ')' ASSIGN expression  -->  declarationFunc \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| FUNCTION IDENTIFIER error parameterDeclaration ')' ASSIGN expression
{
$$ = new STNode;

std::string &id = $2->code;
checkDeclare(id);
idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $7->type;

$$->rule = "declarationFunc";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ERROR ";
$$->pushChilds(std::vector<STNode*>{$4, $5, $6});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$7}, "\t");
if(logSyntax)std::cout << "\n REDUCE:  FUNCTION IDENTIFIER '(' parameterDeclaration ')' ASSIGN expression  -->  declarationFunc \t\tnext token: " << yytext << std::endl;
unexpectedToken("Missing '(' at start of parameter declarations in function declaration", @3);
}

	;

parameterDeclaration
    : parameterDeclaration ',' IDENTIFIER
{
$$ = new STNode;
$$->rule = "parameterDeclaration";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  parameterDeclaration ',' IDENTIFIER --> parameterDeclaration \t\tnext token: " << yytext << std::endl;
}

    | IDENTIFIER
{
if(logSyntax)std::cout << "\n REDUCE:  IDENTIFIER --> parameterDeclaration \t\tnext token: " << yytext << std::endl;
}

    | // empty
{
$$ = new STNode;
$$->rule = "parameterDeclaration";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n REDUCE:   --> parameterDeclaration \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| error
{
$$ = new STNode;
$$->rule = "parameterDeclaration";
$$->code = std::move(std::string(" ERROR "));
if(logSyntax)std::cout << "\n REDUCE: ERROR  --> parameterDeclaration \t\tnext token: " << yytext << std::endl;
unexpectedToken("Invalid parameter declaration", @1);
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
if(logSyntax)std::cout << "\n REDUCE:   expressionList ';' expression  -->  expressionList \t\tnext token: " << yytext << std::endl;
}

	| expression
{
$$ = new STNodeExp;
$$->type = $1->type;

$$->rule = "expressionList";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  expression  -->  expressionList \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| error
{
$$ = new STNodeExp;
$$->code = std::move("ERROR");

$$->rule = "expressionList";
if(logSyntax)std::cout << "\n REDUCE:  ERROR  -->  expressionList \t\tnext token: " << yytext << std::endl;
unexpectedToken("Missing ';' in expression list, discarting all previous expression", @1);
}

	;


expression
	: voidExp
{
$1->type = Type::Void;
$$ = new STNodeExp;
$$->rule = "expression";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  voidExp  -->  expression \t\tnext token: " << yytext << std::endl;
}

	| valuedExp
{
$$ = new STNodeExp;
$$->rule = "expression";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  valuedExp  -->  expression \t\tnext token: " << yytext << std::endl;
}

	;


voidExp
	: ifThenExp
{
$$ = new STNodeExp;
$$->rule = "voidExp";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  ifThenExp  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| whileLoop
{
$$ = new STNodeExp;
$$->rule = "voidExp";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  whileLoop  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| attribution
{
$$ = new STNodeExp;
$$->rule = "voidExp";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  attribution  -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	| // empty
{
$$ = new STNodeExp;

$$->rule = "voidExp";
$$->code = std::move(std::string(""));
if(logSyntax)std::cout << "\n REDUCE:    -->  voidExp \t\tnext token: " << yytext << std::endl;
}

	;


sequence
	: '(' expressionList ')'
{
$$ = new STNodeExp;
$$->rule = "sequence";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->type = $2->type;
if(logSyntax)std::cout << "\n REDUCE:  '(' expressionList ')'  -->  sequence \t\tnext token: " << yytext << std::endl;
}

	;



attribution
	: IDENTIFIER ASSIGN valuedExp
{
$$ = new STNodeExp;
checkTypeID($1, $3->type);

$$->rule = "attribution";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  IDENTIFIER ASSIGN valuedExp  -->  attribution \t\tnext token: " << yytext << std::endl;
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
if(logSyntax)std::cout << "\n REDUCE:  WHILE valuedExp DO expression  -->  whileLoop \t\tnext token: " << yytext << std::endl;
}

// ERROR HANDLING
	| WHILE valuedExp error expression
{
$$ = new STNodeExp;

$$->rule = "whileLoop";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->code += "ERROR";
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
if(logSyntax)std::cout << "\n REDUCE:  WHILE valuedExp DO expression  -->  whileLoop \t\tnext token: " << yytext << std::endl;
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
if(logSyntax)std::cout << "\n REDUCE:  IDENTIFIER '(' parameterList ')'  -->  functionCall \t\tnext token: " << yytext << std::endl;
}

	| IDENTIFIER '(' ')'
{
$$ = new STNodeExp;
$$->type = $1->type;

$$->rule = "functionCall";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  IDENTIFIER '(' ')'  -->  functionCall \t\tnext token: " << yytext << std::endl;
}
	;

parameterList
	: parameterList ',' valuedExp
{
$$ = new STNode;
$$->rule = "parameterList";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  valuedExp ',' parameterList --> parameterList \t\tnext token: " << yytext << std::endl;
}
	| valuedExp
{
$$ = new STNode;
$$->rule = "parameterList";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  valuedExp --> parameterList \t\tnext token: " << yytext << std::endl;
}
	;


ifThenExp
	: ifThenElse
{
$$ = new STNode;
$$->rule = "ifThenExp";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  ifThenElse --> ifThenExp \t\tnext token: " << yytext << std::endl;
}

	| ifThen
{
$$ = new STNode;
$$->rule = "ifThenExp";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  ifThen --> ifThenExp \t\tnext token: " << yytext << std::endl;
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
if(logSyntax)std::cout << "\n REDUCE:  IF valuedExp THEN expression ELSE expression --> ifThenElse \t\tnext token: " << yytext << std::endl;
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
if(logSyntax)std::cout << "\n REDUCE:  IF valuedExp THEN expression --> ifThen \t\tnext token: " << yytext << std::endl;
}
	;


valuedExp
	: valuedExp '&' valuedExp
%prec LGCOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '&' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '|' valuedExp
%prec LGCOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '|' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '<' valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '<' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '>' valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '>' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '=' valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '&' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp NE_OP valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " NE_OP " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp LE_OP valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " LE_OP " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp GE_OP valuedExp
%prec CMPOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->rule = "valuedExp";
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " GE_OP " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '+' valuedExp
%prec ADDOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "valuedExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '+' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}
	| valuedExp '-' valuedExp
%prec ADDOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "valuedExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '-' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '*' valuedExp
%prec MULOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "valuedExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << "*" << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExp '/' valuedExp
%prec MULOP
{
// checkType(Type::Int, $1);
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $1->type;

$$->rule = "valuedExp";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " '/' " << $3->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| '-' valuedExp
%prec UMINUS
{
// checkType(Type::Int, $2);
$$ = new STNodeInt;
$$->type = $2->type;

$$->rule = "valuedExp";
$$->pushChilds(std::vector<STNode*>{$1, $2});
if(logSyntax)std::cout << "\n REDUCE:  '-' " << $2->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	| valuedExpValue
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->pushChilds(std::vector<STNode*>{$1});

if(logSyntax)std::cout << "\n REDUCE:  " << $1->code << " --> valuedExp \t\tnext token: " << yytext << std::endl;
}

	;

// TODO: semantic: check types
valuedExpValue
	: IDENTIFIER
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  IDENTIFIER --> valuedExpValue \t\tnext token: " << yytext << std::endl;
} // TODO: semantic: may be function id without calling

	| CONSTANT
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  CONSTANT --> valuedExpValue \t\tnext token: " << yytext << std::endl;
}

	| STRING_LITERAL
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  STRING_LITERAL  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

	| functionCall
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  functionCall --> valuedExpValue \t\tnext token: " << yytext << std::endl;
}

	| sequence
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  sequence  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

	| letExp
{
$$ = new STNodeInt;
$$->type = $1->type;
$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1});
if(logSyntax)std::cout << "\n REDUCE:  letExp  -->  valuedExp \t\tnext token: " << yytext << std::endl;
}

// s-r conflict: this could be a sequence (expression): shift ')', instead of reducing valuedExp -> expression
	| '(' valuedExp ')'
{

$$ = new STNodeInt;
$$->type = $2->type;

$$->rule = "valuedExpValue";
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n REDUCE:  '(' valuedExp ')' --> valuedExpValue \t\tnext token: " << yytext << std::endl;
}

	;


%%
