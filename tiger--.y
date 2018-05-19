%token IDENTIFIER CONSTANT STRING_LITERAL
%token LE_OP GE_OP NE_OP
 // %token EQ_OP '='
 // %token AND_OP '&' OR_OP '|'

%token IF ELSE WHILE DO
%token ASSIGN END LET THEN FUNCTION VAR
%token IN
%token '-'

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
			os << prefix << '"' << this << "\\n" << code << "\" -> \"" << it << "\\n" << it->code << '"' << std::endl;
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

%type <Int> logic_expression logic_expression_com arithmetic_expression arithmetic_expression_md arithmetic_expression_con arithmetic_expression_value;

%type <Exp> letStatement program

%type <Node> declaration_list declaration declarationVar declarationFunc

%type <Exp> expression_list expression
%type <Node> void_expression
%type <Exp> valued_expression
%type <Exp> sequence
%type <Node> atribution whileLoop
%type <Exp> functionCall
%type <Node> parameter_declaration parameter_list ifThenStatement ifThenElse ifThen

%type <Int> CONSTANT
%type <Id> IDENTIFIER
%type <Node> STRING_LITERAL
%type <Node> LE_OP GE_OP NE_OP
 // %token EQ_OP '='
 // %token AND_OP '&' OR_OP '|'
%type <Node> '&' '|' '=' '>' '<'  '+' '-' '*' '/' '(' ')' ',' ';'
%type <Node> IF ELSE WHILE DO
%type <Node> ASSIGN END LET THEN FUNCTION VAR
%type <Node> IN

%%

program
	: letStatement
{std::cout << "\n==  letStatement -->  program \t\tnext token:'" << yytext << std::endl;

$1->code += "\\l";

root = $1;

std::string filename("./derivationTree.dot");
{
	std::ofstream fileStream(filename);
	
	fileStream << "digraph G {" << std::endl;
	
	fileStream << "\tgraph [fontname = \"monospace\"];\n"
	<< "\tnode [fontname = \"monospace\"];\n"
	<< "\tedge [fontname = \"monospace\"];\n";
	
	$1->printChilds("", fileStream);
	fileStream << "}" << std::endl;
}
if(graphviz){
	system(("dot -Tpng " + filename + " -O").c_str());
	system(("xdg-open " + filename + ".png&").c_str());
}

}

	;


letStatement
	: LET declaration_list IN expression_list END 
{std::cout << "\n==  LET declaration_list IN expression_list END -->  letStatement \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
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
$$->code += "\\l";
}

	| VAR 
{yyerror("syntax: missing let");}
	| LET declaration_list expression
{yyerror("syntax: missing in");}
	| LET declaration_list IN expression_list 
{yyerror("syntax: missing end");}	
	;


declaration_list
	: declaration declaration_list
{if(logSyntax)std::cout << "\n== declaration declaration_list  -->  declaration_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;

$$->pushChilds(std::vector<STNode*>{$1});
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$2});
}

	| declaration
{if(logSyntax)std::cout << "\n== declaration  -->  declaration_list \t\tnext token:'" << yytext << std::endl;
}

	| // empty
{if(logSyntax)std::cout << "\n== declaration declaration_list  -->  declaration_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string("\n"));
}
	;

declaration
	: declarationVar
	| declarationFunc
	;

declarationVar
	: VAR IDENTIFIER ASSIGN valued_expression
{if(logSyntax)std::cout << "\n== VAR IDENTIFIER ASSIGN valued_expression  -->  declarationVar \t\tnext token:'" << yytext << std::endl;
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
    : IDENTIFIER ',' parameter_declaration
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
   

expression_list
	: expression ';' expression_list
{if(logSyntax)std::cout << "\n==  expression ';' expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->type = $3->type;

$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->code += "\\l";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l";
}

	| whileLoop expression_list
{if(logSyntax)std::cout << "\n==  whileLoop expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}

	| ifThenStatement expression_list
{if(logSyntax)std::cout << "\n==  ifThenStatement expression_list  -->  expression_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2});
$$->type = $2->type;

yywarn("syntax: missing ';' after expression in expression list", "note: code: " + $1->code);
}//TODO: warning, missing ';'

	| expression ';'
{if(logSyntax)std::cout << "\n== expression ';'  -->  expression_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->type = $1->type;
$$->pushChilds(std::vector<STNode*>{$1, $2});

yywarn("syntax: extra ';' after last expression in sequence", "note: code: " + $1->code);
}//TODO: warning, extra ';'

	| expression
{if(logSyntax)std::cout << "\n== expression  -->  expression_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1});
$$->type = $1->type;
}

	;


expression
	: void_expression 
{if(logSyntax)std::cout << "\n== void_expression  -->  expression \t\tnext token:'" << yytext << std::endl;
}

	| valued_expression
{if(logSyntax)std::cout << "\n== valued_expression  -->  expression \t\tnext token:'" << yytext << std::endl;
}

	;


void_expression
	: ifThenStatement
{if(logSyntax)std::cout << "\n== ifThenStatement  -->  void_expression \t\tnext token:'" << yytext << std::endl;
}

	| whileLoop 
{if(logSyntax)std::cout << "\n== whileLoop  -->  void_expression \t\tnext token:'" << yytext << std::endl;
}

	| atribution 
{if(logSyntax)std::cout << "\n== atribution  -->  void_expression \t\tnext token:'" << yytext << std::endl;
}

	| // empty
{if(logSyntax)std::cout << "\n==   -->  void_expression \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string(""));
}

	;

valued_expression
	: logic_expression 
{if(logSyntax)std::cout << "\n== logic_expression  -->  valued_expression \t\tnext token:'" << yytext << std::endl;
}

	| functionCall
{if(logSyntax)std::cout << "\n== functionCall  -->  valued_expression \t\tnext token:'" << yytext << std::endl;
}// TODO: check types

	| sequence
{if(logSyntax)std::cout << "\n== sequence  -->  valued_expression \t\tnext token:'" << yytext << std::endl;
}// TODO: check types

	| letStatement
{std::cout << "\n== letStatement  -->  valued_expression \t\tnext token:'" << yytext << std::endl;
}// TODO: check types

	;

sequence
	: '(' expression_list ')'
{if(logSyntax)std::cout << "\n== '(' expression_list ')'  -->  sequence \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
$$->type = $2->type;
}

	;



atribution
	: IDENTIFIER ASSIGN valued_expression
{if(logSyntax)std::cout << "\n== IDENTIFIER ASSIGN valued_expression  -->  atribution \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
checkType($1, $3);
}

	;


whileLoop
	: WHILE valued_expression DO expression
{if(logSyntax)std::cout << "\n== WHILE valued_expression DO expression  -->  whileLoop \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
}
	;



functionCall
	: IDENTIFIER '(' parameter_list ')'
{if(logSyntax)std::cout << "\n== IDENTIFIER '(' parameter_list ')'  -->  functionCall \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeExp;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3, $4});
$$->type = $1->type;
}
	;
	
parameter_list
	: valued_expression ',' parameter_list
{if(logSyntax)std::cout << "\n== valued_expression ',' parameter_list --> parameter_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| valued_expression
{if(logSyntax)std::cout << "\n== valued_expression --> parameter_list \t\tnext token:'" << yytext << std::endl;
}

	| STRING_LITERAL ',' parameter_list
{if(logSyntax)std::cout << "\n== STRING LITERAL ',' parameter_list --> parameter_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| STRING_LITERAL
{if(logSyntax)std::cout << "\n== STRING LITERAL --> parameter_list \t\tnext token:'" << yytext << std::endl;
}

	| // empty
{if(logSyntax)std::cout << "\n== STRING LITERAL --> parameter_list \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;
$$->code = std::move(std::string(""));
}
	;


ifThenStatement
	: ifThenElse
{if(logSyntax)std::cout << "\n== ifThenElse --> ifThenStatement \t\tnext token:'" << yytext << std::endl;
}

	| ifThen
{if(logSyntax)std::cout << "\n== ifThen --> ifThenStatement \t\tnext token:'" << yytext << std::endl;
}

	;


ifThenElse
	: IF valued_expression THEN expression ELSE expression
{if(logSyntax)std::cout << "\n== IF valued_expression THEN expression ELSE expression --> ifThenElse \t\tnext token:'" << yytext << std::endl;
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
$$->code += "\\l";
}
	;

ifThen
	: IF valued_expression THEN expression
{if(logSyntax)std::cout << "\n== IF valued_expression THEN expression --> ifThen \t\tnext token:'" << yytext << std::endl;
$$ = new STNode;

$$->pushChilds(std::vector<STNode*>{$1});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$2});
$$->code += " ";
$$->pushChilds(std::vector<STNode*>{$3});
$$->code += "\\l\t";
$$->pushChilds(std::vector<STNode*>{$4}, "\t");
$$->code += "\\l";
}
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
{if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logic_expression \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression '|' logic_expression_com
{if(logSyntax)std::cout << "\n== " << $1->code << " '|' " << $3->code << " --> logic_expression \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression_com
	;

logic_expression_com
	: logic_expression_com '=' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " '&' " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression_com NE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " NE_OP " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression_com '>' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " '>' " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression_com '<' arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " '<' " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| logic_expression_com GE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " GE_OP " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| logic_expression_com LE_OP arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " LE_OP " << $3->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	| arithmetic_expression
{if(logSyntax)std::cout << "\n== " << $1->code << " --> logic_expression_com \t\tnext token:'" << yytext << std::endl;
}

	;


arithmetic_expression
	: arithmetic_expression '+' arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << $1->code << " '+' " << $3->code << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithmetic_expression '-' arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << $1->code << " '-' " << $3->code << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithmetic_expression_md
{if(logSyntax)std::cout << "\n== " << $1->code << " --> arithmetic_expression \t\tnext token:'" << yytext << std::endl;
}

	;

arithmetic_expression_md
	: arithmetic_expression_md '*' arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << $1->code << " '*' " << $3->code << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithmetic_expression_md '/' arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << $1->code << " '/' " << $3->code << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}
	| arithmetic_expression_con
{if(logSyntax)std::cout << "\n== " << $1->code << " --> arithmetic_expression_md \t\tnext token:'" << yytext << std::endl;
}

	;	

arithmetic_expression_con
	: '-' arithmetic_expression_value
{if(logSyntax)std::cout << "\n== '-' " << $2->code << " --> arithmetic_expression_con \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2});
}
	| arithmetic_expression_value
{if(logSyntax)std::cout << "\n== " << $1->code << " --> arithmetic_expression_con \t\tnext token:'" << yytext << std::endl;
}

	;

arithmetic_expression_value
	: IDENTIFIER
{if(logSyntax)std::cout << "\n== IDENTIFIER --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;
} // TODO: semantic: may be function id without calling

	| CONSTANT
{if(logSyntax)std::cout << "\n== CONSTANT --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;
}

	| functionCall
{if(logSyntax)std::cout << "\n== functionCall --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;
checkType(Type::Int, $1->type);
} // TODO: semantic: is this check sufficient?

	| '(' valued_expression ')'
{if(logSyntax)std::cout << "\n== '(' valued_expression ')' --> arithmetic_expression_value \t\tnext token:'" << yytext << std::endl;
$$ = new STNodeInt;
$$->pushChilds(std::vector<STNode*>{$1, $2, $3});
}

	;


%%

