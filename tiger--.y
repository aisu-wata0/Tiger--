
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

#define logSyntax true
//#define YYSTYPE class STNode *

extern FILE *fp;

extern char *yytext;
extern int yylex();
extern int yylineno;
//extern int column;

void yyerror(const std::string & msg, const std::string & note = "")
{
	std::cerr << std::endl
	<< "error: " << msg << " in line " << yylineno << ". \tNext token: " << yytext << std::endl;
	std::cerr << note << std::endl;

	exit(1);
}

void yywarn(const std::string & msg, const std::string & note = "")
{
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

enum class Type {
	Void,
	Str,
	Int,
};

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

	void printChilds(const std::string & prefix, std::ofstream & os){
		for(auto it : childs){
			os << prefix << '"' << this << "\\n" << code << "\" -> \"" << it << "\\n" << it->code << '\\n' << it->rule << std::endl;
			it->printChilds(prefix+"\t", os);
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

#define checkDeclare(id)	\
{	\
auto search = idTable.find(id);	\
if(search != idTable.end()) {	\
	std::ostringstream msg, note;	\
	msg << "syntax: redeclaration of '" << id << "'\n";	\
	note << "note: previous declaration of '" << id << "' was in line " << search->second.lineDeclared << "\n";	\
	yyerror(msg.str(), note.str());	\
}	\
}	\

#define checkType(t1, t2)	\
{	\
}	\


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

	if(!yyparse()){
		printf("\n\nParsing completed\n\n");
	} else {
		printf("\n\nParsing failed\n\n");
		exit(EXIT_FAILURE);
	}

	fclose(yyin);

	if(graphviz){
		std::string filename("./derivationTree.dot");
		std::ofstream fileStream(filename);

		fileStream << "digraph G {" << std::endl;

		fileStream << "\tgraph [fontname = \"monospace\"];\n"
		<< "\tnode [fontname = \"monospace\"];\n"
		<< "\tedge [fontname = \"monospace\"];\n";

		root->printChilds("", fileStream);
		fileStream << "}" << std::endl;

		std::cout << "\n\tSummoning dot and opening resulting graph picture\n" << std::endl;

		std::string command = "dot -Tpng " + filename + " -O";
		std::cout << command << std::endl;
		system(command.c_str());

		command = ("xdg-open " + filename + ".png&");
		std::cout << command << std::endl;
		system(command.c_str());
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
%type <Node> voidExp
%type <Exp> valuedExp
%type <Exp> sequence
%type <Node> attribution whileLoop
%type <Exp> functionCall
%type <Node> parameter_declaration parameterList ifThenExp ifThenElse ifThen

%type <Int> CONSTANT
%type <Id> IDENTIFIER
%type <Node> STRING_LITERAL
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

if(logSyntax)std::cout << "\n==  letExp -->  program \t\tnext token:'" << yytext << std::endl;
}

	;


letExp
	: LET declarationList IN expressionList END
{std::cout << "\n==  LET declarationList IN expressionList END -->  letExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->rule = "letExp";
$$->type = $4->type;
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$2}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$5});
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
{if(logSyntax)std::cout << "\n== declarationList declaration  -->  declarationList \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->rule = "declarationList";
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$2});
}

	| // empty
{if(logSyntax)std::cout << "\n==   -->  declarationList \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string("\\l"));
}
	;

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valuedExp
{if(logSyntax)std::cout << "\n== VAR IDENTIFIER ASSIGN valuedExp  -->  declarationVar \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4});

std::string &id = $2->code;
checkDeclare(id);

idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $4->type;
}

	;

declarationFunc
	: FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression
{if(logSyntax)std::cout << "\n== FUNCTION IDENTIFIER '(' parameter_declaration ')' ASSIGN expression  -->  declarationFunc \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;

$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4, $5, $6});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$7}, "\t");

std::string &id = $2->code;
checkDeclare(id);

idTable[id].lineDeclared = $2->lineDeclared;
idTable[id].type = $7->type;
}

	;

parameter_declaration
    : parameter_declaration ',' IDENTIFIER
{if(logSyntax)std::cout << "\n== IDENTIFIER ',' parameter_declaration --> parameter_declaration \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
    | IDENTIFIER
{if(logSyntax)std::cout << "\n== IDENTIFIER --> parameter_declaration \t\tnext token:'" << yytext << std::endl;
}

    | // empty
{if(logSyntax)std::cout << "\n==  --> parameter_declaration \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string(""));
}
    ;


expressionList
	: expressionList ';' expression
{if(logSyntax)std::cout << "\n==  expressionList ';' expression  -->  expressionList \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->type = $3->type;

$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l";
}

	| expression
{if(logSyntax)std::cout << "\n== expression  -->  expressionList \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1});
$$->type = $1->type;
}

/* //TODO: warnings
	| whileLoop expressionList
{if(logSyntax)std::cout << "\n==  whileLoop expressionList  -->  expressionList \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}

	| ifThenExp expressionList
{if(logSyntax)std::cout << "\n==  ifThenExp expressionList  -->  expressionList \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}

	| expression ';'
{if(logSyntax)std::cout << "\n== expression ';'  -->  expressionList \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->type = $1->type;
$$->pushChilds(std::vector<STNode*>{$1, $2});

yywarn("syntax: extra ';' after last expression in sequence", "note: code: " + $1->code);
}
*/

	;


expression
	: voidExp
{if(logSyntax)std::cout << "\n== voidExp  -->  expression \t\tnext token:'" << yytext << std::endl;
}

	| valuedExp
{if(logSyntax)std::cout << "\n== valuedExp  -->  expression \t\tnext token:'" << yytext << std::endl;
}

	;


voidExp
	: ifThenExp
{if(logSyntax)std::cout << "\n== ifThenExp  -->  voidExp \t\tnext token:'" << yytext << std::endl;
}

	| whileLoop
{if(logSyntax)std::cout << "\n== whileLoop  -->  voidExp \t\tnext token:'" << yytext << std::endl;
}

	| attribution
{if(logSyntax)std::cout << "\n== attribution  -->  voidExp \t\tnext token:'" << yytext << std::endl;
}

	| // empty
{if(logSyntax)std::cout << "\n==   -->  voidExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string(""));
}

	;

valuedExp
	: logicExp
{if(logSyntax)std::cout << "\n== logicExp  -->  valuedExp \t\tnext token:'" << yytext << std::endl;
}
	;

sequence
	: '(' expressionList ')'
{if(logSyntax)std::cout << "\n== '(' expressionList ')'  -->  sequence \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->type = $2->type;
}

	;



attribution
	: IDENTIFIER ASSIGN valuedExp
{if(logSyntax)std::cout << "\n== IDENTIFIER ASSIGN valuedExp  -->  attribution \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
checkType($1, $3);
}

	;


whileLoop
	: WHILE valuedExp DO expression
{if(logSyntax)std::cout << "\n== WHILE valuedExp DO expression  -->  whileLoop \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
}
	;



functionCall // TODO: semantic: maybe this ID was not declared
// maybe this ID was not a function, but a var
	: IDENTIFIER '(' parameterList ')'
{if(logSyntax)std::cout << "\n== IDENTIFIER '(' parameterList ')'  -->  functionCall \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4});
$$->type = $1->type;
}

	| IDENTIFIER '(' ')'
{if(logSyntax)std::cout << "\n== IDENTIFIER '(' ')'  -->  functionCall \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->type = $1->type;
}
	;

parameterList
	: valuedExp ',' parameterList
{if(logSyntax)std::cout << "\n== valuedExp ',' parameterList --> parameterList \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| valuedExp
{if(logSyntax)std::cout << "\n== valuedExp --> parameterList \t\tnext token:'" << yytext << std::endl;
}
	;


ifThenExp
	: ifThenElse
{if(logSyntax)std::cout << "\n== ifThenElse --> ifThenExp \t\tnext token:'" << yytext << std::endl;
}

	| ifThen
{if(logSyntax)std::cout << "\n== ifThen --> ifThenExp \t\tnext token:'" << yytext << std::endl;
}

	;


ifThenElse
	: IF valuedExp THEN expression ELSE expression
{if(logSyntax)std::cout << "\n== IF valuedExp THEN expression ELSE expression --> ifThenElse \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;

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
}
	;

ifThen
	: IF valuedExp THEN expression
{if(logSyntax)std::cout << "\n== IF valuedExp THEN expression --> ifThen \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;

$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
}
	;


logicExp
	: logicExp '&' logicExpCom
{if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logicExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logicExp '|' logicExpCom
{if(logSyntax)std::cout << "\n== " << $1->code << " '|' " << $3->code << " --> logicExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logicExpCom
	;

logicExpCom
	: logicExpCom '<' arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " '<' " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logicExpCom '>' arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " '>' " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logicExpCom '=' arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logicExpCom NE_OP arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " NE_OP " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logicExpCom LE_OP arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " LE_OP " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logicExpCom GE_OP arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " GE_OP " << $3->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| arithExp
{if(logSyntax)std::cout << "\n== " << $1->code << " --> logicExpCom \t\tnext token:'" << yytext << std::endl;
}

	;


arithExp
	: arithExp '+' arithExpMd
{if(logSyntax)std::cout << "\n== " << $1->code << " '+' " << $3->code << " --> arithExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithExp '-' arithExpMd
{if(logSyntax)std::cout << "\n== " << $1->code << " '-' " << $3->code << " --> arithExp \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithExpMd
{if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExp \t\tnext token:'" << yytext << std::endl;
}

	;

arithExpMd
	: arithExpMd '*' arithExpCon
{if(logSyntax)std::cout << "\n== " << $1->code << " '*' " << $3->code << " --> arithExpMd \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithExpMd '/' arithExpCon
{if(logSyntax)std::cout << "\n== " << $1->code << " '/' " << $3->code << " --> arithExpMd \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithExpCon
{if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExpMd \t\tnext token:'" << yytext << std::endl;
}

	;

arithExpCon
	: '-' arithExpValue
%prec UMINUS
{
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2});
if(logSyntax)std::cout << "\n== '-' " << $2->code << " --> arithExpCon \t\tnext token:'" << yytext << std::endl;
}

	| arithExpValue
{
if(logSyntax)std::cout << "\n== " << $1->code << " --> arithExpCon \t\tnext token:'" << yytext << std::endl;
}

	;

// TODO: semantic: check types
arithExpValue
	: IDENTIFIER
{
if(logSyntax)std::cout << "\n== IDENTIFIER --> arithExpValue \t\tnext token:'" << yytext << std::endl;
} // TODO: semantic: may be function id without calling

	| CONSTANT
{
if(logSyntax)std::cout << "\n== CONSTANT --> arithExpValue \t\tnext token:'" << yytext << std::endl;
}

	| functionCall
{
checkType(Type::Int, $1->type);
if(logSyntax)std::cout << "\n== functionCall --> arithExpValue \t\tnext token:'" << yytext << std::endl;
}

	| sequence
{
if(logSyntax)std::cout << "\n== sequence  -->  valuedExp \t\tnext token:'" << yytext << std::endl;
}

	| STRING_LITERAL
{
if(logSyntax)std::cout << "\n== STRING_LITERAL  -->  valuedExp \t\tnext token:'" << yytext << std::endl;
}

	| letExp
{
if(logSyntax)std::cout << "\n== letExp  -->  valuedExp \t\tnext token:'" << yytext << std::endl;
}

	| '(' valuedExp ')'
{
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
if(logSyntax)std::cout << "\n== '(' valuedExp ')' --> arithExpValue \t\tnext token:'" << yytext << std::endl;
}

	;


%%
