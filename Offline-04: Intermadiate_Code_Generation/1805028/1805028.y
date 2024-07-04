%{
#include<bits/stdc++.h>
#include<iostream>
#include<cstring>
#include<cstdlib>
#include "lib/SymbolTable.h"
#include "lib/util.h"

using namespace std;

int yylex(void);
int yyparse(void);
extern FILE *yyin;

SymbolTable* st = new SymbolTable(30);

int line_count = 1;
int tc = 0;
int errorCount = 0;
int lc = 0;
int optimized_line=0;

string Name;
string Type;
set<pair<string, string>> arrVarList;
string codeSegment;
string current_type = "";
string current_called = "";
set<string> varList;
string current_func = "";


void yyerror(char *s){}

ofstream errorFile("error.txt");
FILE* optimizedCode;
ofstream codeFile("code.asm");
ofstream optimized_code;
ifstream read_code;

string newTemp(){
	string t = "t";
	tc++;
	t+= to_string(tc);
	varList.insert(t);
	return t;
}

string newLabel(){
	string label = "L";
	lc++;
	label += to_string(lc);
	return label;
}


void Optimized_Code(string filename){
	read_code.open(filename);
	optimized_code.open("optimized_code.asm");
	string first_line;
	string second_line;
	string first_words;
	string final_first_words;
	string second_words;
	string final_second_words;

	while(getline(read_code,first_line)){
		vector <string> first_tokens;
		vector <string> second_tokens;
		stringstream check_first(first_line);
      
		while(getline(check_first, first_words, ' ')){	
			stringstream check_first_word(first_words);
			while(getline(check_first_word, final_first_words, ',')){
				first_tokens.push_back(final_first_words);
			}
		}
		if(first_tokens.size()==3 && first_tokens.at(0) == "ADD" && first_tokens.at(2) == "0"){
			optimized_code <<";"<<first_line << "\t(optimization)\n";
			optimized_line++;
		}
		else if(first_tokens.size()==3 && first_tokens.at(0) == "SUB" && first_tokens.at(2) == "0"){
			optimized_code <<";"<<first_line << "\t(optimization)\n";
			optimized_line++;
		}
		else{
			optimized_code <<first_line<<"\n";
		}

		
		if(first_tokens.size() == 3 && first_tokens.at(0) == "MOV"){
			getline(read_code,second_line);
			
			stringstream check_second(second_line);

			while(getline(check_second, second_words, ' ')){
				stringstream check_second_word(second_words);
				while(getline(check_second_word, final_second_words, ',')){
					second_tokens.push_back(final_second_words);
				}
			}
			if(second_tokens.size() == 3 && second_tokens.at(0) == "MOV"){
				int match1 = first_tokens.at(1).compare(second_tokens.at(2));
				int match2 = first_tokens.at(2).compare(second_tokens.at(1));

				int match3= first_tokens.at(1).compare(second_tokens.at(1));
				int match4= first_tokens.at(2).compare(second_tokens.at(2));

				if((match1 == 0 && match2 == 0) || (match3 == 0 && match4 == 0)){
					optimized_code <<";"<< second_line << "\t(optimization)\n";
					optimized_line++;
				}
				else{
					optimized_code << second_line << "\n";
				}
			}
			else
				optimized_code << second_line << "\n";	
		}		
	}
	optimized_code<<"\n\n;Total number of eliminated line: "<<to_string(optimized_line);
	optimized_code.close();
}

void print_error(int line, string error){
	errorFile << "Error at line " << line << " : "<<error << "\n\n";
	++errorCount;
}

vector<SymbolInfo> ParameterList;
set<string> completedFunc;
%}


%union	{SymbolInfo* si; vector<SymbolInfo*>* vec;}
%token <si> CONST_FLOAT IF ELSE CONST_CHAR MULOP INCOP RELOP ID FOR ADDOP CASE DEFAULT SWITCH CONST_INT
%token <si> CONTINUE BREAK RETURN ASSIGNOP LOGICOP NOT WHILE DO CHAR FLOAT DOUBLE PRINTLN VOID
%token <si> LCURL RCURL LTHIRD RTHIRD COMMA LPAREN RPAREN SEMICOLON DECOP INT

%type <si> func_definition parameter_list start program unit func_declaration compound_statement
%type <si> var_declaration type_specifier declaration_list statements statement expression_statement
%type <si> variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
 


%%

start: program
	{
		Name = $1->getName();
		Type = $1->getType();
		$$ = new SymbolInfo(Name, Type);

		if(errorCount==0){
			$$->setCode($$->getCode()+$1->getCode());
			codeFile<<InitializeAssembly(varList, arrVarList , $$->getCode())<<endl;
			Optimized_Code("code.asm");
		}
	}
	;

program: program unit	{
							Name = $1->getName()+" "+$2->getName();
							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode());
						}
	| unit	{
				Name = $1->getName();
				$$ = new SymbolInfo(Name, "");
				$$->setCode($$->getCode()+$1->getCode());
			}
	;
	
unit: var_declaration	{
							Name = $1->getName();
							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
     | func_declaration	{
							Name = $1->getName();
							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
     | func_definition	{
							Name = $1->getName();
							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
     ;
     
func_declaration: type_specifier ID LPAREN parameter_list RPAREN {
		current_func = $2->getName();
		if(st->lookUp(current_func) != NULL){
			print_error(line_count, "Multiple declaration of "+current_func);
		}
		else{
			SymbolInfo* syminfo = new SymbolInfo(current_func, "ID");
			for(auto ind : ParameterList){
				syminfo->addFuncParams(ind);
			}
			syminfo->Set_StructType("func");
			syminfo->Set_DataType($1->getName());
			ParameterList.clear();
			st->Insert(*syminfo);
		}
	} SEMICOLON	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" "+$7->getName()+"\n";
							$$ = new SymbolInfo(Name, "func");
						}
		| type_specifier ID LPAREN RPAREN {
			current_func=$2->getName();
			if(st->lookUp(current_func) != NULL){
				print_error(line_count, "Multiple declaration of "+current_func);
			}
			else{
				SymbolInfo* temp = new SymbolInfo(current_func, "ID");
				temp->Set_StructType("func");
				temp->Set_DataType($1->getName());
				st->Insert(*temp);
			}
		} SEMICOLON	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$6->getName()+"\n";
							$$ = new SymbolInfo(Name, "");
						}
		;
		 
func_definition: type_specifier ID LPAREN parameter_list RPAREN {
	current_func=$2->getName();
	if(st->lookUp(current_func) != NULL){
		SymbolInfo* temp = st->lookUp(current_func);
		for(auto i : completedFunc){
			if(i == current_func){
				print_error(line_count, "Multiple declaration of "+current_func);
			}
		}
		if(temp->Get_StructType() != "func"){
			print_error(line_count, "Multiple declaration of "+current_func);
		}
		else{
			vector<SymbolInfo> v = temp->getFuncParams();
			if($1->getName() != temp->Get_DataType()){
				print_error(line_count, "Return type mismatch with function declaration in function "+temp->getName());
				
			}
			if(v.size() != ParameterList.size()){
				print_error(line_count, "Total number of arguments mismatch with declaration in function "+current_func);
			}

			int minsize = v.size();
			if(ParameterList.size() < minsize){
				minsize = ParameterList.size();
			}

			for(int i=0; i<minsize; i++){
				if(ParameterList[i].Get_DataType() != v[i].Get_DataType()){
					print_error(line_count, current_func+" parameter type error");
					
				}
			}
		}
	}
	else{
		SymbolInfo* temp = new SymbolInfo(current_func, "ID");
		for(auto i : ParameterList){
			temp->addFuncParams(i);
		}
		temp->Set_StructType("func");
		temp->Set_DataType($1->getName());
		st->Insert(*temp);
	}
	
} compound_statement	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" "+$7->getName();

							$$ = new SymbolInfo(Name, "func");	
							completedFunc.insert(current_func);
	
							SymbolInfo* temp = st->lookUp(current_func);
							vector<SymbolInfo> tempVect = temp->getFuncParams();
							for(int i=tempVect.size()-1; i>=0; i--){
								$$->setCode($$->getCode()+"POP AX\n");
								$$->setCode($$->getCode()+"MOV "+tempVect[i].getName()+", AX\n");
							}

							$$->setCode($$->getCode()+current_func + " PROC\n");

							if(current_func=="main"){
								$$->setCode($$->getCode()+ "MOV AX, @DATA \nMOV DS, AX\n");
							}	
							else{
								
							}
							
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode()+$4->getCode()+$5->getCode()+$7->getCode());	
							
							if(current_func!="main"){
								
								if(temp->Get_DataType()!="void"){
									$$->setCode($$->getCode()+"PUSH AX\n");
								}
								if(tempVect.size()!=0){
									int retsize = tempVect.size()*2;
									$$->setCode($$->getCode()+"RET "+to_string(retsize)+"\n");
								}
								else{
									$$->setCode($$->getCode()+"RET\n");
								}
								
							}else{
								$$->setCode($$->getCode()+"\nMOV AH, 4CH\nINT 21H\n");
							}	
							$$->setCode($$->getCode()+current_func + " ENDP\n");
						}
		| type_specifier ID LPAREN RPAREN {
			current_func=$2->getName();
			if(st->lookUp(current_func) != NULL){
				SymbolInfo* temp = st->lookUp(current_func);
				if(temp->Get_StructType() != "func"){
					print_error(line_count, "Multiple declaration of "+current_func);
				}
			}
			else{
				SymbolInfo* temp = new SymbolInfo(current_func, "ID");
				temp->Set_StructType("func");
				temp->Set_DataType($1->getName());
				st->Insert(*temp);
			}
			
	} compound_statement	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$6->getName();

							$$ = new SymbolInfo(Name, "");
							completedFunc.insert(current_func);

							$$->setCode($$->getCode()+current_func + " PROC\n");
							if(current_func=="main"){
								$$->setCode($$->getCode()+ "MOV AX, @DATA \nMOV DS, AX\n");
							}	
							else{
								$$->setCode($$->getCode()+"PUSH AX\nPUSH BX\nPUSH CX\nPUSH DX\n");
							}

							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode()+$4->getCode()+$6->getCode());

							if(current_func!="main"){
								$$->setCode($$->getCode()+"POP DX\nPOP CX\nPOP BX\nPOP AX\nRET\n");
							}else{
								$$->setCode($$->getCode()+"\nMOV AH, 4CH\nINT 21H\n");
							}	
							$$->setCode($$->getCode()+current_func + " ENDP\n");
						}
 		;				


parameter_list: parameter_list COMMA type_specifier ID	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName();
							
							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($4->getName(), $4->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType($3->getName());
							bool isFound = false;
							for(auto ind:ParameterList){
								if(ind.getName() == syminfo->getName()){
									print_error(line_count, "Multiple declaration of "+ind.getName()+" in parameter");
									isFound = true;
									break;
								}
							}
							if(isFound == false){
								ParameterList.push_back(*syminfo);
							}
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode()+$4->getCode());

							varList.insert($4->getName());
						}
		| parameter_list COMMA type_specifier	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType($3->getName());
							ParameterList.push_back(*syminfo);
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode());
						}
 		| type_specifier ID	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($2->getName(), $2->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType($1->getName());
							ParameterList.push_back(*syminfo);
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode());

							varList.insert($2->getName());
						}
		| type_specifier	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($1->getName(), $1->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType($1->getName());
							ParameterList.push_back(*syminfo);
							$$->setCode($$->getCode()+$1->getCode());
						}
 		;

 		
compound_statement: LCURL dummy_enterScope statements RCURL	{
							Name = $1->getName()+"\n"+$3->getName()+$4->getName()+"\n";
							$$ = new SymbolInfo(Name, "");

							st->ExitScope();
							$$->setCode($$->getCode()+$1->getCode()+$3->getCode()+$4->getCode());
						}
 		    | LCURL dummy_enterScope RCURL	{
							Name = $1->getName()+" "+$3->getName()+"\n";

							$$ = new SymbolInfo(Name, "");
 
							st->ExitScope();
							$$->setCode($$->getCode()+$1->getCode()+$3->getCode());
						}
 		    ;

dummy_enterScope:	{
						st->EnterScope();
						SymbolInfo* syminfo = st->lookUp(current_func);
						vector<SymbolInfo> v = syminfo->getFuncParams();
						if(ParameterList.size() != 0){
							for(auto i : ParameterList){
								st->Insert(i);
							}
						}
						ParameterList.clear();
					}
	;
var_declaration: type_specifier declaration_list SEMICOLON	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+"\n";
							Type = $1->getType()+" "+$2->getType()+" "+$3->getType()+"\n";
							$$ = new SymbolInfo(Name, "");

							if($1->getName() == "void"){
								print_error(line_count, "Variable type cannot be void");
							}
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode());
						}
 		 ;
 		 
type_specifier: INT	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");

							current_type = "int";
							$$->setCode($$->getCode()+$1->getCode());
						}
 		| FLOAT	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");

							current_type = "float";
							$$->setCode($$->getCode()+$1->getCode());
						}
 		| VOID	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");

							current_type = "void";
							$$->setCode($$->getCode()+$1->getCode());
						}
 		;
 		
declaration_list: declaration_list COMMA ID	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();
							
							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType(current_type);

							ScopeTable* sc = st->getCurrentScope();
							if(sc->lookUpBoolean(syminfo->getName())){
								
								print_error(line_count,  "Multiple declaration of "+syminfo->getName());
							}
							if(current_type != "void"){
								st->Insert(*syminfo);
							}
							
							varList.insert($3->getName());

						}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" "+$6->getName();
							

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($3->getName(), $3->getType());
							syminfo->Set_StructType("array");
							syminfo->Set_DataType(current_type);

							ScopeTable* sc = st->getCurrentScope();
							if(sc->lookUpBoolean(syminfo->getName())){
								
								print_error(line_count, "Multiple declaration of "+syminfo->getName());
							}
							if(current_type != "void"){
								st->Insert(*syminfo);
							}
							arrVarList.insert(make_pair($3->getName(), $5->getName()));
						}
 		  | ID	{
							Name = $1->getName();
							

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo(Name, $1->getType());
							syminfo->Set_StructType("var");
							syminfo->Set_DataType(current_type);

							ScopeTable* sc = st->getCurrentScope();
							if(sc->lookUpBoolean(syminfo->getName())){
								
								print_error(line_count, "Multiple declaration of "+syminfo->getName());
							}
							if(current_type != "void"){
								st->Insert(*syminfo);
							}
							
							varList.insert($1->getName());							
						}
 		  | ID LTHIRD CONST_INT RTHIRD	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName();
							
							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = new SymbolInfo($1->getName(), $1->getType());
							syminfo->Set_StructType("array");
							syminfo->Set_DataType(current_type);
							
							ScopeTable* sc = st->getCurrentScope();
							if(sc->lookUpBoolean(syminfo->getName())){
								
								print_error(line_count, "Multiple declaration of "+syminfo->getName());
							}					
							if(current_type != "void"){
								st->Insert(*syminfo);
							}

							arrVarList.insert(make_pair($1->getName(), $3->getName()));
						}
 		  ;
 		  
statements: statement	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
	   | statements statement	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode());
							
						}
	   ;
	   
statement: var_declaration	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
	  | expression_statement	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
	  | compound_statement	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode());
						}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" "+$6->getName()+" "+$7->getName();
							$$ = new SymbolInfo(Name, "");
							codeSegment = "; for loop index initialization\n";
							codeSegment += $3->getCode();
							string label1 = newLabel();
							string label2 = newLabel();
							codeSegment += label1+":\n";
							codeSegment += "; for loop comparision start\n";
							codeSegment += $4->code;
							codeSegment += "MOV BX, 0\n";
							codeSegment += "CMP AX, BX\n";
							codeSegment += "JE "+label2+"\n";

							codeSegment += $7->code;
							codeSegment += ";index increment/decrement start\n";
							codeSegment += $5->code;
							codeSegment += "JMP "+label1+"\n";
							codeSegment += label2 + ":\n";

							$$->setCode($$->getCode()+codeSegment)
						}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName();

							$$ = new SymbolInfo(Name, "");

							string label = newLabel();
							codeSegment = $3->code;
							codeSegment += "MOV AX, "+$3->getName()+"\t;line:"+ to_string(line_count)+" ->if segment starts\n";
							codeSegment += "CMP AX, 0\n";
							codeSegment += "JE "+label+"\n";
							codeSegment += $5->code;
							codeSegment += label + ":\n";
							$$->setCode($$->getCode()+codeSegment);
						}
	  | IF LPAREN expression RPAREN statement ELSE statement	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+" "+$6->getName()+" "+$7->getName();

							$$ = new SymbolInfo(Name, "");
							string label = newLabel();
							string label2 = newLabel();
							codeSegment = $3->code;
							codeSegment += "MOV AX, "+$3->getName()+"\t;line:"+ to_string(line_count)+" ->if segment ends\n";
							codeSegment += "CMP AX, 0\n";
							codeSegment += "JE "+label+"\n";
							codeSegment += $5->code;
							codeSegment += "JMP "+label2+"\n";
							codeSegment += label + ":\n";
							codeSegment += $7->code;
							codeSegment += label2 + ":\n";
							$$->setCode($$->getCode()+codeSegment);
						}
	  | WHILE LPAREN expression RPAREN statement	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName();

							$$ = new SymbolInfo(Name, "");
						}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName()+" "+$5->getName()+"\n";
							

							$$ = new SymbolInfo(Name, "");

							SymbolInfo* syminfo = st->lookUp($3->getName());
							if(syminfo==NULL){
								print_error(line_count, "Undeclared variable "+$3->getName());
							}
							codeSegment = "MOV AX, "+$3->getName()+"\nCALL OUTDEC\n";
							$$->setCode($$->getCode()+codeSegment);
						}
	  | RETURN expression SEMICOLON	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+"\n";
							SymbolInfo* syminfo = st->lookUp(current_func);
							if(syminfo->Get_DataType()=="void"){
								print_error(line_count, "warning: return with a value, in function returning void");
							}

							else if(syminfo->Get_DataType() != "float" && ($2->Get_DataType()!= syminfo->Get_DataType())){
								print_error(line_count, "Function return type error");
							}
							$$ = new SymbolInfo(Name, "");
						}
	  ;
	  
expression_statement: SEMICOLON	{
							Name = $1->getName()+"\n";

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+"");
						}			
			| expression SEMICOLON	{
							Name = $1->getName();							
							Name += $2->getName();
							Name += "\n";

							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode());
						} 
			;
	  
variable: ID	{
							Name = $1->getName();
							

							SymbolInfo* t = st->lookUp(Name);
							if(t == NULL){
								print_error(line_count, "Undeclared variable "+Name);
								
								$$ = new SymbolInfo(Name, "");
								$$->Set_StructType("var");
								$$->Set_DataType("none");
							}
							else{
								if(t->Get_StructType() == "array"){
									print_error(line_count, "Type mismatch, "+t->getName()+ " is an array");
									
								}
								$$ = new SymbolInfo(Name, "");
								$$ = t;
							}
							$$->setCode($$->getCode()+"");						
						} 		
	 | ID LTHIRD expression RTHIRD	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName()+" "+$4->getName();
							

							SymbolInfo* t = st->lookUp($1->getName());
							
							if(t == NULL){
								print_error(line_count, "Undeclared variable "+Name);
								
								$$ = new SymbolInfo($1->getName(), "array");
								$$->Set_StructType("array");
								$$->Set_DataType("none");
							}else{
								if(t->Get_StructType() != "array"){
									print_error(line_count, t->getName()+" not an array");
									
								}
								$$ = new SymbolInfo(Name, "");
								$$->Set_StructType("array");
								$$->Set_DataType(t->Get_DataType());
								if($3->Get_DataType()=="float"){
									print_error(line_count, "Expression inside third brackets not an integer");
									
								}
							}
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode()+$4->getCode());
							$$->setCode($$->getCode()+"MOV BX, "+$3->getName()+"\nINC BX\nADD BX, BX\nSUB BX, 2\n");
							$$->setName($1->getName()+$2->getName()+"BX"+$4->getName());
						} 
	 ;
	 
 expression: logic_expression	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						}	
	   | variable ASSIGNOP logic_expression	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();

							if($3->Get_DataType() != "none" && $1->Get_DataType() != "none") {
								if($1->Get_DataType()=="void" || $3->Get_DataType()=="void" ){
								print_error(line_count, "Void function used in expression");
								}
								else if($1->Get_DataType()!="float" && ($1->Get_DataType() != $3->Get_DataType())){
									print_error(line_count, "Type Mismatch");	
								}
							}
							
							
							$$ = new SymbolInfo(Name, "");
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode());

							$$->setCode($$->getCode()+"MOV AX, "+$3->getName()+"\n"+"MOV "+$1->getName()+", AX\n");
						} 	
	   ;
			
logic_expression: rel_expression	{
							Name = $1->getName();
							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						} 	
		 | rel_expression LOGICOP rel_expression	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();

							$$ = new SymbolInfo(Name, "");
							$$->Set_DataType("int");

							if($1->Get_DataType()=="void" || $3->Get_DataType()=="void" ){
								print_error(line_count, "Void function used in expression");
							}
							codeSegment = $1->getCode()+$3->getCode();
							codeSegment += "MOV AX, "+$1->getName()+"\n";
							codeSegment += "MOV BX, "+$3->getName()+"\n";
		
							if($2->getName()=="||"){
								string label1 = newLabel();
								string label2 = newLabel();
								string str = newTemp();
								varList.insert(str);

								codeSegment += "CMP AX, 0\n";
								codeSegment += "JNE "+label1+"\n";
								codeSegment += "CMP BX, 0\n";
								codeSegment += "JNE "+label1+"\n";
								codeSegment += "MOV AX, 0\n";
								codeSegment += "MOV "+str+", AX\n";
								codeSegment += "JMP "+label2+"\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV "+str+", 1\n";
								codeSegment += label2 + ":\n";
								$$->setName(str);
							}

							else if($2->getName()=="&&"){
								string label1 = newLabel();
								string label2 = newLabel();
								string str = newTemp();
								varList.insert(str);

								codeSegment += "CMP AX, 0\n";
								codeSegment += "JE "+label1+"\n";
								codeSegment += "CMP BX, 0\n";
								codeSegment += "JE "+label1+"\n";
								codeSegment += "MOV AX, 1\n";
								codeSegment += "MOV "+str+", AX\n";
								codeSegment += "JMP "+label2+"\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, 0\n";
								codeSegment += "MOV "+str+", AX\n";
								codeSegment += label2 + ":\n";
								$$->setName(str);
							}

							$$->setCode($$->getCode()+codeSegment);
						} 	
		 ;
			
rel_expression: simple_expression	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						} 
		| simple_expression RELOP simple_expression	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();;

							$$ = new SymbolInfo(Name, "");
							$$->Set_DataType("int");

							if($1->Get_DataType()=="void" || $3->Get_DataType()=="void" ){
								print_error(line_count, "Void function used in expression");
								
							}
							codeSegment = $1->getCode();
							codeSegment += $3->getCode();

							string temp1 = newTemp();
							varList.insert(temp1);
							string label1 = newLabel();
							string temp2 = newTemp();
							varList.insert(temp2);

							codeSegment += "MOV AX, 0\n";
							codeSegment += "MOV "+temp2+", AX\n";
							codeSegment += "MOV "+temp1+", AX\n";

							codeSegment+= "MOV AX, "+$1->getName()+"\n";
							codeSegment+= "MOV BX, "+$3->getName()+"\n";
							codeSegment += "CMP AX, BX\n";

							if($2->getName()=="<"){
								codeSegment += "JNL "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if less than satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}
							

							else if($2->getName()=="!="){
								codeSegment += "JE "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if not equal satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}

							else if($2->getName()==">="){
								codeSegment += "JNGE "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if greater than or equal satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}

							else if($2->getName()==">"){
								codeSegment += "JNG "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if greater than satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}

							else if($2->getName()=="<="){
								codeSegment += "JNLE "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if less than or equal satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}

							else if($2->getName()=="=="){
								codeSegment += "JNE "+label1+"\n";
								codeSegment += "MOV AX, 1 \t;line:"+ to_string(line_count)+" ->execute if equal satisfies\n";
								codeSegment += "MOV "+temp2+", AX\n";
								codeSegment += "MOV "+temp1+", AX\n";
								codeSegment += label1 + ":\n";
								codeSegment += "MOV AX, "+temp2+"\n";
							}

							$$->setCode($$->getCode()+codeSegment);
							$$->setName(temp1);
						}	
		;
				
simple_expression: term	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						} 
		  | simple_expression ADDOP term	{
							Name = $1->getName();
							Name += $2->getName();
							Name += $3->getName();

							$$ = new SymbolInfo(Name, "");
							if($1->Get_DataType()=="float" || $3->Get_DataType()=="float"){
								$$->Set_DataType("float");
							}
							else if($1->Get_DataType()=="int" || $3->Get_DataType()=="int"){
								$$->Set_DataType("int");
							}

							else if($1->Get_DataType()=="void" || $3->Get_DataType()=="void" ){
								print_error(line_count, "Void function used in expression");
							}

							codeSegment = "MOV AX, "+$1->getName()+"\n";
							codeSegment +="MOV BX, "+$3->getName()+"\n";
							string temp1 = newTemp();

							if($2->getName()=="+"){
								codeSegment+= "ADD AX, BX \t;line:"+ to_string(line_count)+" ->add operation\n";
								codeSegment += "MOV "+temp1+", AX\n";
							}else if($2->getName()=="-"){
								codeSegment+= "SUB AX, BX \t;line:"+ to_string(line_count)+" ->subtruct operation\n";
								codeSegment += "MOV "+temp1+", AX\n";
							}

							$$->setCode($$->getCode()+codeSegment);							
							$$->setName(temp1);
						} 
		  ;
					
term:	unary_expression	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						}
     |  term MULOP unary_expression	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();
							
							$$ = new SymbolInfo(Name, "");

							if($1->Get_DataType()=="void" || $3->Get_DataType()=="void"){
								print_error(line_count, "Void function used in expression");
							}

							if($2->getName()=="%"){
								if($1->Get_DataType()!="int" || $3->Get_DataType()!="int"){
									print_error(line_count, "Non-Integer operand on modulus operator");
									
								}

								if($3->getName()=="0"){
									print_error(line_count, "Modulus by Zero");
									
								}
								$$->Set_DataType("int");
							}
							else{
								if($1->Get_DataType()=="float" || $3->Get_DataType()=="float"){
									$$->Set_DataType("float");
								}
								else{
									$$->Set_DataType("int");
								}
							}
							codeSegment = $1->getCode();
							codeSegment += $3->getCode();
							codeSegment += "MOV AX, "+$1->getName()+"\n";
							codeSegment += "MOV BX, "+$3->getName()+"\n";
							string tempo_var = newTemp();

							if($2->getName()=="/"){
								codeSegment += "XOR DX, DX\n";
								codeSegment += "CWD\n";
								codeSegment += "IDIV BX \t;line:"+ to_string(line_count)+" ->division operation\n";
								codeSegment += "MOV "+tempo_var+", AX\n";
							}

							else if($2->getName()=="*"){
								codeSegment += "MUL BX \t;line:"+ to_string(line_count)+" ->multiplication operation\n";
								codeSegment += "MOV "+tempo_var+", AX\n";
							}

							else if($2->getName()=="%"){
								codeSegment += "XOR DX, DX\n";
								codeSegment += "CWD\n";
								codeSegment += "IDIV BX \t;line:"+ to_string(line_count)+" ->modulus operation\n";
								codeSegment += "MOV "+tempo_var+", DX\n";
							}
							$$->setName(tempo_var);
							$$->setCode($$->getCode()+codeSegment);
						}
     ;

unary_expression: ADDOP unary_expression	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");
							$$->Set_DataType($2->Get_DataType());
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode());
						}  
		 | NOT unary_expression	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");
							$$->Set_DataType($2->Get_DataType());

							string temp = newTemp();

							$$->setCode($$->getCode()+"MOV AX, "+$2->getName()+"\n"+"NOT AX" + "\t;line:"+ to_string(line_count)+" ->negation\n" +"MOV "+temp + ", AX");
						} 
		 | factor	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						} 
		 ;
	
factor: variable	{
							Name = $1->getName();
							$$ = new SymbolInfo(Name, "");
							$$ = $1;	
						} 

	| ID LPAREN {
		current_called = $1->getName();
	} argument_list RPAREN	{
							if($4->getName() != "("){
								Name = $1->getName()+" "+$2->getName()+" "+$4->getName()+" "+$5->getName();
							}
							else{
								Name = $1->getName()+" "+$2->getName()+" "+$5->getName();
							}

							SymbolInfo* t = st->lookUp($1->getName());
							if(t == NULL){
								print_error(line_count, "Undeclared function "+$1->getName());
								
								$$ = new SymbolInfo(Name, "");
							}
							else{
								vector<SymbolInfo> v = t->getFuncParams();
								if(v.size() != ParameterList.size()){
									print_error(line_count, "Total number of arguments mismatch in function "+ current_called);
									
								}
								int size = v.size();
								if(ParameterList.size()<size){
									size = ParameterList.size();
								}
								for(int i=0; i<size; i++){
									
									if(v[i].Get_DataType() != ParameterList[i].Get_DataType()){
										if(v[i].Get_DataType()=="float" && ParameterList[i].Get_DataType()=="int"){
											;
										}
										else{
											print_error(line_count, to_string(i+1) + "th argument mismatch in function "+current_called);
											
											break;
										}
									}
								}
															
								
								$$ = new SymbolInfo(Name, "");
								$$->Set_DataType(t->Get_DataType());
							}
							for(int i=0; i<ParameterList.size(); i++){
									$$->setCode($$->getCode()+"MOV AX, "+ParameterList[i].getName()+"\nPUSH AX\n");
								}
							ParameterList.clear();
							$$->code += "CALL "+current_called+ "\t;line:"+ to_string(line_count)+" ->function calling\n";
							if(t->Get_DataType()!="void"){
								$$->code += "POP AX\n";
								$$->setCode($$->getCode()+"POP AX\n");
							}
						}
	| LPAREN expression RPAREN	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();

							$$ = new SymbolInfo(Name, "");
							$$->Set_DataType($2->Get_DataType());
							$$->setCode($$->getCode()+$2->getCode());
							$$->setName($2->getName());
						}
	| CONST_INT	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "CONST_INT");
							$$->Set_StructType("val");
							$$->Set_DataType("int");

							codeSegment = "MOV AX, "+$1->getName()+"\n";
							$$->setCode($$->getCode()+codeSegment);
						} 
	| CONST_FLOAT	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "CONST_FLOAT");
							$$->Set_StructType("val");
							$$->Set_DataType("float");

							codeSegment = "MOV AX, "+$1->getName()+"\n";
							$$->setCode($$->getCode()+codeSegment);
						}
	| variable INCOP	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");
							codeSegment = "MOV AX, "+$1->getName()+"\t;line:"+to_string(line_count)+" ->incrementing\n";
							codeSegment += "INC AX\n";
							codeSegment += "MOV "+$1->getName()+", AX\n";
							$$->setCode($$->getCode()+codeSegment);
						} 
	| variable DECOP	{
							Name = $1->getName()+" "+$2->getName();

							$$ = new SymbolInfo(Name, "");
							codeSegment = "MOV AX, "+$1->getName()+ "\t;line:"+to_string(line_count)+" ->decrementing\n";
							codeSegment += "DEC AX\n";
							codeSegment += "MOV "+$1->getName()+", AX\n";
							$$->setCode($$->getCode()+codeSegment);
						}
	;
	
argument_list: arguments	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
						}
			| {
							Name = " ";
							$$ = new SymbolInfo(Name, "");
			}
			;
	
arguments: arguments COMMA logic_expression	{
							Name = $1->getName()+" "+$2->getName()+" "+$3->getName();

							$$ = new SymbolInfo(Name, "");
							ParameterList.push_back(*$3);
							$$->setCode($$->getCode()+$1->getCode()+$2->getCode()+$3->getCode());
						}
	      | logic_expression	{
							Name = $1->getName();

							$$ = new SymbolInfo(Name, "");
							$$ = $1;
							ParameterList.push_back(*$1);
						}
	      ;

%%
int main(int argc,char *argv[])
{
	if(argc!=2){
		printf("No input file is given!\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Error openning file!\n");
		return 0;
	}
	
	yyin= fin;
	yyparse();
	fclose(yyin);
	return 0;
}