%{
#include<bits/stdc++.h>
#include<cstring>
#include<cstdlib>
#include<iostream>
#include "lib/SymbolTable.h"
using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

SymbolTable* symbolTable = new SymbolTable(7);

int lineCount = 1;
int errorCount = 0;

string currentType;
string currentFunction;
string currentCalled;
string errorMessege;
string symbolName;
string symbolType;

ofstream logFile("log.txt");
ofstream errorFile("error.txt");

void yyerror(char *s)
{
	errorFile<< "Error at line "<<lineCount<<" :Syntax Error\n";
	++errorCount;
}

void PrintError(int lineNo, string error){
	logFile << "Error at line " << lineNo << " : "<<error << "\n\n";
	errorFile << "Error at line " << lineNo << " : "<<error << "\n\n";
	++errorCount;
}

void PrintLog(int lineNo, string grammar, string token){
	logFile << "Line " << lineNo << ": "<<grammar << "\n\n"  << token<< "\n\n";
}

set<string> DefinedFunctionList;
vector<SymbolInfo> ParameterList;
%}


%union	{SymbolInfo* si;}
%token <si> ADDOP SWITCH CONST_CHAR INCOP MULOP CASE DEFAULT CONST_FLOAT IF ELSE RELOP ID CONST_INT FOR WHILE DO BREAK CHAR FLOAT 
%token <si> CONTINUE PRINTLN ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON DECOP INT DOUBLE VOID RETURN

%type <si> start program unit func_declaration var_declaration type_specifier func_definition parameter_list compound_statement declaration_list statements statement 
%type <si> expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
 


%%

start: program
	{
		$$ = $1;
		PrintLog(lineCount, "start : program", "");
	}
	;

program: program unit	{
							$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "program");
							PrintLog(lineCount, "program : program unit", $$->getName());
						}
	| unit	{
				$$ = $1;
				PrintLog(lineCount, "program : unit", $$->getName());
			}
	;
	
unit: var_declaration	{
							$$ = $1;
							PrintLog(lineCount, "unit : var_declaration", $$->getName());
						}
     | func_declaration	{
							$$ = $1;
							PrintLog(lineCount, "unit : func_declaration", $$->getName());
						}
     | func_definition	{
							$$ = $1;
							PrintLog(lineCount, "func_definition", $$->getName());
						}
     ;
     
func_declaration: type_specifier ID LPAREN parameter_list RPAREN {
		currentFunction = $2->getName();
		
		if(symbolTable->Lookup(currentFunction) != NULL){			//Function already declared
			errorMessege="Multiple declaration of "+currentFunction;
			PrintError(lineCount, errorMessege);
		}

		else{														//Function is not declared
			SymbolInfo* syminfo = new SymbolInfo(currentFunction, "ID");
			for(auto i : ParameterList){
				syminfo->addFuncParams(i);
			}

			syminfo->setDataType($1->getName());
			syminfo->setStructType("func");
			ParameterList.clear();
			symbolTable->Insert(*syminfo);
		}
	} SEMICOLON	{
					$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ");", "func_declaration");
					PrintLog(lineCount, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON",$$->getName());
				}

		| type_specifier ID LPAREN RPAREN {
			currentFunction=$2->getName();

			if(symbolTable->Lookup(currentFunction) != NULL){
				errorMessege="Multiple declaration of "+currentFunction;
				PrintError(lineCount, errorMessege);	
			}
			else{
				SymbolInfo* syminfo = new SymbolInfo(currentFunction, "ID");
				syminfo->setDataType($1->getName());
				syminfo->setStructType("func");
				
				symbolTable->Insert(*syminfo);
			}
		} SEMICOLON	{
							$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();", "func_declaration");
							PrintLog(lineCount, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON",$$->getName());
						}
		;
		 
func_definition: type_specifier ID LPAREN parameter_list RPAREN {
	currentFunction=$2->getName();

	if(symbolTable->Lookup(currentFunction) == NULL){
		SymbolInfo* syminfo = new SymbolInfo(currentFunction, "ID");
		for(auto i : ParameterList){
			syminfo->addFuncParams(i);
		}
		syminfo->setStructType("func");
		syminfo->setDataType($1->getName());
		symbolTable->Insert(*syminfo);
	}
	else{
		SymbolInfo* syminfo = symbolTable->Lookup(currentFunction);
		for(auto i : DefinedFunctionList){
			if(i == currentFunction){
				errorMessege="Multiple declaration of "+currentFunction;
				PrintError(lineCount, errorMessege);	
			}
		}
		if(syminfo->getStructType() != "func"){
			errorMessege="Multiple declaration of "+currentFunction;
			PrintError(lineCount, errorMessege);
		}
		else{
			vector<SymbolInfo> params = syminfo->getFuncParams();

			if($1->getName() != syminfo->getDataType()){
				errorMessege="Return type mismatch with function declaration in function "+syminfo->getName();
				PrintError(lineCount, errorMessege);
			}

			if(params.size() != ParameterList.size()){
				errorMessege="Total number of arguments mismatch with declaration in function "+currentFunction;
				PrintError(lineCount, errorMessege);
			}

			int min = params.size();
			if(ParameterList.size() < min){
				min = ParameterList.size();
			}

			for(int i=0; i<min; i++){
				if(ParameterList[i].getDataType() != params[i].getDataType()){
					errorMessege= currentFunction+" parameter type error";
					PrintError(lineCount, errorMessege);
				}
			}
		}
	}
	
} compound_statement	{
							$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $4->getName() + ")" + $7->getName() + "\n", "func_definition");
							PrintLog(lineCount, "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement",$$->getName());
							DefinedFunctionList.insert(currentFunction);						
						}

		| type_specifier ID LPAREN RPAREN {
			currentFunction=$2->getName();

			if(symbolTable->Lookup(currentFunction) != NULL){
				SymbolInfo* syminfo = symbolTable->Lookup(currentFunction);
				if(syminfo->getStructType() != "func"){
					errorMessege= "Multiple declaration of "+currentFunction;
					PrintError(lineCount, errorMessege);
				}
			}
			else{
				SymbolInfo* syminfo = new SymbolInfo(currentFunction, "ID");
				syminfo->setDataType($1->getName());
				syminfo->setStructType("func");
		
				symbolTable->Insert(*syminfo);
			}
			
	} compound_statement	{
							$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $6->getName() + "\n", "func_definition");
							PrintLog(lineCount, "func_definition : type_specifier ID LPAREN RPAREN compound_statement",$$->getName());
							DefinedFunctionList.insert(currentFunction);	
						}
 		;				


parameter_list: parameter_list COMMA type_specifier ID	{
							$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "parameter_list");
							PrintLog(lineCount, "parameter_list  : parameter_list COMMA type_specifier ID", $$->getName());

							SymbolInfo* syminfo = new SymbolInfo($4->getName(), $4->getType());
							syminfo->setStructType("var");
							syminfo->setDataType($3->getName());
							
							bool isFound = false;
							for(auto i:ParameterList){
								if(i.getName() == syminfo->getName()){
									errorMessege= "Multiple declaration of "+i.getName()+" in parameter";
									PrintError(lineCount, errorMessege);

									isFound = true;
									break;
								}
							}
							if(!isFound){
								ParameterList.push_back(*syminfo);
							}
						}
		| parameter_list COMMA type_specifier	{
							$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "parameter_list");
							PrintLog(lineCount, "parameter_list  : parameter_list COMMA type_specifier", $$->getName());

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->setStructType("var");
							syminfo->setDataType($3->getName());
							ParameterList.push_back(*syminfo);
						}
 		| type_specifier ID	{
							$$ = new SymbolInfo($1->getName() + " " + $2->getName(), "parameter_list");
							PrintLog(lineCount, "parameter_list  : type_specifier ID", $$->getName());

							SymbolInfo* syminfo = new SymbolInfo($2->getName(), $2->getType());
							syminfo->setDataType($1->getName());
							syminfo->setStructType("var");
							
							ParameterList.push_back(*syminfo);
						}
		| type_specifier	{
							$$=$1;
							PrintLog(lineCount, "parameter_list  : type_specifier", $$->getName());

							SymbolInfo* syminfo = new SymbolInfo($1->getName(), $1->getType());
							syminfo->setStructType("var");
							syminfo->setDataType($1->getName());
							ParameterList.push_back(*syminfo);
						}
 		;

 		
compound_statement: LCURL EnterScopeRule statements RCURL	{
							$$ = new SymbolInfo($1->getName()+"\n"+$3->getName()+$4->getName()+"\n", "nonterminal");
							PrintLog(lineCount, "compound_statement : LCURL statements RCURL", $$->getName());

							symbolTable->PrintAllTables(logFile);
							symbolTable->ExitScope();
						}
 		    | LCURL EnterScopeRule RCURL	{
							$$ = new SymbolInfo($1->getName()+" "+$3->getName()+"\n", "");
							PrintLog(lineCount, "compound_statement : LCURL RCURL", $$->getName());
 
							symbolTable->ExitScope();
							symbolTable->PrintAllTables(logFile);
						}
 		    ;

EnterScopeRule:	{
						symbolTable->EnterScope();
						if(ParameterList.size() != 0){
							for(auto i : ParameterList){
								symbolTable->Insert(i);
							}
						}
						ParameterList.clear();
					}
	;
var_declaration: type_specifier declaration_list SEMICOLON	{
							$$ = new SymbolInfo($1->getName() + " " + $2->getName() + ";", "var_declaration");
							PrintLog(lineCount, "var_declaration : type_specifier declaration_list SEMICOLON", $$->getName());

							if($1->getName() == "void"){			//void type variable
								errorMessege= "Variable type cannot be void";
								PrintError(lineCount, errorMessege);
							}
						}
 		 ;
 		 
type_specifier: INT	{
							$$ = new SymbolInfo("int", "");
							PrintLog(lineCount, "type_specifier	: INT", $$->getName());

							currentType = "int";
						}
 		| FLOAT	{
							$$ = new SymbolInfo("float", "");
							PrintLog(lineCount, "type_specifier	: FLOAT", $$->getName());

							currentType = "float";
						}
 		| VOID	{
							$$ = new SymbolInfo("void", "");
							PrintLog(lineCount, "type_specifier	: VOID", $$->getName());

							currentType = "void";
						}
 		;
 		
declaration_list: declaration_list COMMA ID	{
							$$ = new SymbolInfo($1->getName()+" "+$2->getName()+" "+$3->getName(), "");
							PrintLog(lineCount, "declaration_list : declaration_list COMMA ID", $$->getName());
							

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->setDataType(currentType);
							syminfo->setStructType("var");
							
							ScopeTable* st = symbolTable->getCurrentScope();

							if(st->LookupBoolean(syminfo->getName())){		//id already in scopetable
								errorMessege= "Multiple declaration of "+syminfo->getName();
								PrintError(lineCount,  errorMessege);
							}
							if(currentType != "void"){
								symbolTable->Insert(*syminfo);
							}

						}

 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{
							$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]",	"declaration_list");
							PrintLog(lineCount, "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->getName());

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->setStructType("array");
							syminfo->setDataType(currentType);

							ScopeTable* sc = symbolTable->getCurrentScope();

							if(sc->LookupBoolean(syminfo->getName())){		//id already in scopetable
								errorMessege= "Multiple declaration of "+syminfo->getName();
								PrintError(lineCount, errorMessege);
							}
							if(currentType != "void"){
								symbolTable->Insert(*syminfo);
							}
						}
 		  | ID	{
							symbolName = $1->getName();
							PrintLog(lineCount, "declaration_list : ID", symbolName);

							$$ = new SymbolInfo($1->getName(), "");

							SymbolInfo* syminfo = new SymbolInfo(symbolName, $1->getType());
							syminfo->setStructType("var");
							syminfo->setDataType(currentType);

							ScopeTable* sc = symbolTable->getCurrentScope();

							if(sc->LookupBoolean(syminfo->getName())){		//id already in scopetable
								errorMessege= "Multiple declaration of "+syminfo->getName();
								PrintError(lineCount, errorMessege);
							}
							if(currentType != "void"){
								symbolTable->Insert(*syminfo);
							}
						}
 		  | ID LTHIRD CONST_INT RTHIRD	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName();
							
							PrintLog(lineCount, "declaration_list : ID LTHIRD CONST_INT RTHIRD", symbolName);

							$$ = new SymbolInfo(symbolName, "");

							SymbolInfo* syminfo = new SymbolInfo($1->getName(), $1->getType());
							syminfo->setStructType("array");
							syminfo->setDataType(currentType);
							
							ScopeTable* sc = symbolTable->getCurrentScope();

							if(sc->LookupBoolean(syminfo->getName())){			//id already in scopetable
								errorMessege= "Multiple declaration of "+syminfo->getName();
								PrintError(lineCount, errorMessege);
							}					
							if(currentType != "void"){
								symbolTable->Insert(*syminfo);
							}
						}
 		  ;
 		  
statements: statement	{
							$$=$1;
							PrintLog(lineCount, "statements : statement", $$->getName());
						}
	   | statements statement	{
							$$ = new SymbolInfo($1->getName() + "\n" + $2->getName(), "statements");
							PrintLog(lineCount, "statements : statements statement", $$->getName());
						}
	   ;
	   
statement: var_declaration	{
							$$=$1;
							PrintLog(lineCount, "statement : var_declaration", $$->getName());
						}
	  | expression_statement	{
							$$=$1;
							PrintLog(lineCount, "statement : expression_statement", $$->getName());
						}
	  | compound_statement	{
							symbolName = $1->getName();
							PrintLog(lineCount, "statement : compound_statement", symbolName);

							$$ = new SymbolInfo(symbolName, "");
						}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
							$$ = new SymbolInfo("for(" + $3->getName() + $4->getName() + $5->getName() + ")" + $7->getName(),	"statement");
							PrintLog(lineCount, "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", $$->getName());
						}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE	{
							$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName(),	"statement");
							PrintLog(lineCount, "statement : IF LPAREN expression RPAREN statement", $$->getName());
						}
	  | IF LPAREN expression RPAREN statement ELSE statement	{
							$$ = new SymbolInfo("if(" + $3->getName() + ")" + $5->getName() + "else" + $7->getName(),	"statement");
							PrintLog(lineCount, "statement : IF LPAREN expression RPAREN statement ELSE statement", $$->getName());
						}
	  | WHILE LPAREN expression RPAREN statement	{
							$$ = new SymbolInfo("while(" + $3->getName() + ")" + $5->getName(),	"statement");
							PrintLog(lineCount, "statement : WHILE LPAREN expression RPAREN statement", $$->getName());
						}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+"\n";
							PrintLog(lineCount, "statement : PRINTLN LPAREN ID RPAREN SEMICOLON", symbolName);

							$$ = new SymbolInfo(symbolName, "");

							SymbolInfo* syminfo = symbolTable->Lookup($3->getName());
							if(syminfo==NULL){
								errorMessege= "Undeclared variable "+$3->getName();
								PrintError(lineCount, errorMessege);
							}
						}
	  | RETURN expression SEMICOLON	{
							$$ = new SymbolInfo("return " + $2->getName() + ";", "statement");
							PrintLog(lineCount, "statement : RETURN expression SEMICOLON", $$->getName());

							SymbolInfo* temp = symbolTable->Lookup(currentFunction);
							if(temp->getDataType()=="void"){
								errorMessege= "return with a value, in function returning void";
								PrintError(lineCount, errorMessege);
							}

							else if(temp->getDataType() != "float" && ($2->getDataType()!= temp->getDataType())){
								errorMessege= "Function return type error";
								PrintError(lineCount, errorMessege);
							}
						}
	  ;
	  
expression_statement: SEMICOLON	{
							$$ = new SymbolInfo(";", "SEMICOLON");
						}	

			| expression SEMICOLON	{
							$$ = new SymbolInfo($1->getName() + ";", "expression_statement");							

							PrintLog(lineCount, "expression_statement 	: expression SEMICOLON", $$->getName());
						} 
			;
	  
variable: ID	{
							symbolName = $1->getName();
							PrintLog(lineCount, "variable : ID", symbolName);

							SymbolInfo* syminfo = symbolTable->Lookup(symbolName);
							if(syminfo == NULL){
								errorMessege= "Undeclared variable "+symbolName;
								PrintError(lineCount, errorMessege);
								
								$$ = new SymbolInfo(symbolName, "");
								$$->setDataType("");
								$$->setStructType("var");
								
							}
							else{
								if(syminfo->getStructType() == "array"){
									errorMessege= "Type mismatch, "+syminfo->getName()+ " is an array";
									PrintError(lineCount, errorMessege);	
								}
								$$ = new SymbolInfo(symbolName, "");
								$$ = syminfo;
							}
							
						} 		
	 | ID LTHIRD expression RTHIRD	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName();
							PrintLog(lineCount, "variable : ID LTHIRD expression RTHIRD", symbolName);

							SymbolInfo* syminfo = symbolTable->Lookup($1->getName());
							
							if(syminfo != NULL){
								if(syminfo->getStructType() != "array"){
									errorMessege= syminfo->getName()+" not an array";
									PrintError(lineCount, errorMessege);
								}
								
								$$ = new SymbolInfo(symbolName, "");
								$$->setStructType("array");
								$$->setDataType(syminfo->getDataType());

								if($3->getDataType()=="float"){		//float array size
									errorMessege= "Expression inside third brackets not an integer";
									PrintError(lineCount, errorMessege);								
								}
							}else{
								errorMessege= "Undeclared variable "+symbolName;
								PrintError(lineCount, errorMessege);
								
								$$ = new SymbolInfo($1->getName(), "array");
								$$->setStructType("array");
								$$->setDataType("");
							}
						} 
	 ;
	 
 expression: logic_expression	{
							symbolName = $1->getName();

							PrintLog(lineCount, "expression : logic expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						}	
	   | variable ASSIGNOP logic_expression	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();

							PrintLog(lineCount, "expression : variable ASSIGNOP logic_expression", symbolName);

							if($3->getDataType() != "" && $1->getDataType() != "") {

								if($1->getDataType()=="void" || $3->getDataType()=="void" ){
									errorMessege= "Void function used in expression";
									PrintError(lineCount, errorMessege);
								
								}
								else if($1->getDataType()!="float" && ($1->getDataType() != $3->getDataType())){
									errorMessege= "Type Mismatch";
									PrintError(lineCount, errorMessege);
									
								}
							}
							
							
							$$ = new SymbolInfo(symbolName, "");
						} 	
	   ;
			
logic_expression: rel_expression	{
							symbolName = $1->getName();
							PrintLog(lineCount, "logic_expression : rel_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						} 	
		 | rel_expression LOGICOP rel_expression	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();
							PrintLog(lineCount, "logic_expression : rel_expression LOGICOP rel_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$->setDataType("int");

							if($1->getDataType()=="void" || $3->getDataType()=="void" ){
								errorMessege= "Void function used in expression";
								PrintError(lineCount, errorMessege);
								
							}
						} 	
		 ;
			
rel_expression: simple_expression	{
							symbolName = $1->getName();
							PrintLog(lineCount, "rel_expression	: simple_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						} 
		| simple_expression RELOP simple_expression	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();;
							PrintLog(lineCount, "rel_expression	: simple_expression RELOP simple_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$->setDataType("int");

							if($1->getDataType()=="void" || $3->getDataType()=="void" ){
								errorMessege= "Void function used in expression";
								PrintError(lineCount, errorMessege);
								
							}
						}	
		;
				
simple_expression: term	{
							symbolName = $1->getName();
							PrintLog(lineCount, "simple_expression : term", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						} 
		  | simple_expression ADDOP term	{
							symbolName = $1->getName() +" "+ $2->getName()+" "+$3->getName();

							PrintLog(lineCount, "simple_expression : simple_expression ADDOP term", symbolName);

							$$ = new SymbolInfo(symbolName, "");

							if($1->getDataType()=="float" || $3->getDataType()=="float"){
								$$->setDataType("float");
							}

							else if($1->getDataType()=="int" || $3->getDataType()=="int"){
								$$->setDataType("int");
							}

							else if($1->getDataType()=="void" || $3->getDataType()=="void" ){
								errorMessege= "Void function used in expression";
								PrintError(lineCount, errorMessege);
								
							}
						} 
		  ;
					
term:	unary_expression	{
							symbolName = $1->getName();
							PrintLog(lineCount, "term :	unary_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						}
     |  term MULOP unary_expression	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();
							PrintLog(lineCount, "term :	term MULOP unary_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "nonterminal");

							if($1->getDataType()=="void" || $3->getDataType()=="void"){
								errorMessege= "Void function used in expression";
								PrintError(lineCount, errorMessege);
							}

							if($2->getName()=="%"){

								if($1->getDataType()!="int" || $3->getDataType()!="int"){
									errorMessege= "Non-Integer operand on modulus operator";
									PrintError(lineCount, errorMessege);
									
								}

								if($3->getName()=="0"){
									errorMessege= "Modulus by Zero";
									PrintError(lineCount, errorMessege);
									
								}
								$$->setDataType("int");
							}
							else{
								if($1->getDataType()=="float" || $3->getDataType()=="float"){
									$$->setDataType("float");
								}
								else{
									$$->setDataType("int");
								}
							}
						}
     ;

unary_expression: ADDOP unary_expression	{
							symbolName = $1->getName()+" "+$2->getName();
							PrintLog(lineCount, "unary_expression : ADDOP unary_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$->setDataType($2->getDataType());
						}  
		 | NOT unary_expression	{
							symbolName = $1->getName()+" "+$2->getName();
							PrintLog(lineCount, "unary_expression : NOT unary expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$->setDataType($2->getDataType());
						} 
		 | factor	{
							symbolName = $1->getName();
							PrintLog(lineCount, "unary_expression : factor", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						} 
		 ;
	
factor: variable	{
							symbolName = $1->getName();
							PrintLog(lineCount, "factor	: variable", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;	
						} 

	| ID LPAREN {
		currentCalled = $1->getName();
	} argument_list RPAREN	{
							if($4->getName() != "("){
								symbolName = $1->getName()+" "+$2->getName()+" "+$4->getName()+" "+$5->getName();
							}
							else{
								symbolName = $1->getName()+" "+$2->getName()+" "+$5->getName();
							}
							PrintLog(lineCount, "factor	: ID LPAREN argument_list RPAREN", symbolName);

							SymbolInfo* t = symbolTable->Lookup($1->getName());
							if(t == NULL){
								errorMessege= "Undeclared function "+$1->getName();
								PrintError(lineCount, errorMessege);
								
								$$ = new SymbolInfo(symbolName, "nonterminal");
								ParameterList.clear();
							}
							else{
								vector<SymbolInfo> v = t->getFuncParams();
								if(v.size() != ParameterList.size()){
									errorMessege= "Total number of arguments mismatch in function "+ currentCalled;
									PrintError(lineCount, errorMessege);
									
								}
								int size = v.size();
								if(ParameterList.size()<size){
									size = ParameterList.size();
								}
								for(int i=0; i<size; i++){
									
									if(v[i].getDataType() != ParameterList[i].getDataType()){
										if(v[i].getDataType()=="float" && ParameterList[i].getDataType()=="int"){
											;
										}
										else{
											errorMessege= to_string(i+1) + "th argument mismatch in function "+currentCalled;
											PrintError(lineCount, errorMessege);
											
											break;
										}
									}
								}							
								ParameterList.clear();
								$$ = new SymbolInfo(symbolName, "");
								$$->setDataType(t->getDataType());
							}
						}
	| LPAREN expression RPAREN	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();
							PrintLog(lineCount, "factor	: LPAREN expression RPAREN", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$->setDataType($2->getDataType());
						}
	| CONST_INT	{
							symbolName = $1->getName();
							PrintLog(lineCount, "factor	: CONST_INT", symbolName);

							$$ = new SymbolInfo(symbolName, "CONST_INT");
							$$->setStructType("val");
							$$->setDataType("int");
						} 
	| CONST_FLOAT	{
							symbolName = $1->getName();
							PrintLog(lineCount, "factor	: CONST_FLOAT", symbolName);

							$$ = new SymbolInfo(symbolName, "CONST_FLOAT");
							$$->setStructType("val");
							$$->setDataType("float");
						}
	| variable INCOP	{
							$$ = new SymbolInfo($1->getName() + "++",	$1->getType());
							PrintLog(lineCount, "factor	: variable INCOP", $$->getName());
						} 
	| variable DECOP	{
							$$ = new SymbolInfo($1->getName() + "--",	$1->getType());
							PrintLog(lineCount, "factor	: variable DECOP", $$->getName());
						}
	;
	
argument_list: arguments	{
							symbolName = $1->getName();
							PrintLog(lineCount, "argument_list : arguments", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
						}
			| {
							symbolName = " ";
							PrintLog(lineCount, "argument_list : |", symbolName);

							$$ = new SymbolInfo(symbolName, "");
			}
			;
	
arguments: arguments COMMA logic_expression	{
							symbolName = $1->getName()+" "+$2->getName()+" "+$3->getName();
							PrintLog(lineCount, "arguments : arguments COMMA logic_expression", symbolName);
							
							$$ = new SymbolInfo(symbolName, "");
							ParameterList.push_back(*$3);
						}
	      | logic_expression	{
							symbolName = $1->getName();
							PrintLog(lineCount, "arguments : logic_expression", symbolName);

							$$ = new SymbolInfo(symbolName, "");
							$$ = $1;
							ParameterList.push_back(*$1);
						}
	      ;

%%
int main(int argc,char *argv[])
{
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	yyin= fin;
	yyparse();

	symbolTable->PrintAllTables(logFile);
	logFile<<"Total lines: "<<lineCount<<endl;
	logFile<<"Total errors: "<<errorCount<<endl;

	fclose(yyin);
	return 0;
}