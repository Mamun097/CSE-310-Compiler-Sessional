%option noyywrap yylineno
%s STATE1
%x MultipleChar
%x SLC
%x MLC
%x MultiLineStr

%{
#include<stdio.h>
#include<stdlib.h>
#include "SymbolTable.cpp"

int bucket_size=7;
SymbolTable* symbolTable=new SymbolTable(bucket_size);
string str;
string str1="";
bool insert_conf;
int error=0;
int newline=0;

FILE *logout;
FILE *tokenout;

string Escape(const string& s){
	string scp="";
	for(auto i=s.begin();i!=s.end();++i){
		if(*i=='\\'){
			++i;
			if(i==s.end()) break;

			if(*i=='a')scp+='\a';
			else if(*i=='0')scp+='\0';
			else if(*i=='b')scp+='\b';
			else if(*i=='f')scp+='\f';
			else if(*i=='n')scp+='\n';
			else if(*i=='r')scp+='\r';
			else if(*i=='t')scp+='\t';
			else if(*i=='v')scp+='\v';
			else if(*i=='\'')scp+='\'';
			else if(*i=='\\')scp+='\\';
			else scp+=*i;

			if(*i=='\r'&& *(i+1)=='\n'){
				++i;
				scp+='\t';
				newline++;
			}
		}
		else scp+=*i;
	}
	return scp;
}

string LineCorrection(const string& s){
	string scp="";
	for(auto i=s.begin();i!=s.end();++i){
		if(*i=='\n'){
			scp+=*i;
			if(i==s.end()) break;

			newline++;
		}
		else scp+=*i;
	}
	return scp;
}

string EscapeNewLine(const string& s){
	string scp="";
	for(auto i=s.begin();i!=s.end();++i){
		if(*i=='\n'){
			scp+='\t';
		}
		else scp+=*i;
	}
	return scp;
}

%}

ALPHANUMERIC [a-zA-Z_][a-zA-Z0-9_]*
DIGIT [0-9]

nl "\r"|"\n"|"\r\n"
bs "\\"
sqt "\'"
dq "\""
escape {bs}({bs}|{sqt}|[ntafrbv0])
point "\."
ds "//"
cmnt_strt "/*"
cmnt_end "*/"

float_num ({DIGIT}*[.]{DIGIT}+)|({DIGIT}*[.]{0,1}{DIGIT}+[E][-]{0,1}{DIGIT}+)
err_mul_point {DIGIT}*{point}{DIGIT}*{point}*[.0-9]*
err_ill {DIGIT}*[.]{0,1}{DIGIT}+[E][-]{0,1}{DIGIT}*[.]{DIGIT}+
err_inv_id {DIGIT}+{ALPHANUMERIC}

_char {sqt}[^\\\r\n]{sqt}
esc_char {sqt}{escape}{sqt}
err_mul_char {sqt}[^\\\r\n]+[^\\\r\n]{sqt}
err_emp_char {sqt}{2}
err_unf_char ({sqt}{bs}{sqt})|({sqt}[^\'\\\r\n]*)

Single_Line_Comment {ds}([^\\\r\n]((\\)+(.|[\r\n]))*)*

%%
[ \t\f\r\v]+ {}
[\n] {}

"if"	{
			fprintf(tokenout," <IF> ");
			fprintf(logout,"\nLine no %d: TOKEN <IF> Lexeme %s found\n",yylineno,yytext);
		}

"else"	{
			fprintf(tokenout," <ELSE> ");
			fprintf(logout,"\nLine no %d: TOKEN <ELSE> Lexeme %s found\n",yylineno,yytext);
		}

"for"	{
			fprintf(tokenout," <FOR> ");
			fprintf(logout,"\nLine no %d: TOKEN <FOR> Lexeme %s found\n",yylineno,yytext);
		}

"while"	{
			fprintf(tokenout," <WHILE> ");
			fprintf(logout,"\nLine no %d: TOKEN <WHILE> Lexeme %s found\n",yylineno,yytext);
		}

"do"	{
			fprintf(tokenout," <DO> ");
			fprintf(logout,"\nLine no %d: TOKEN <DO> Lexeme %s found\n",yylineno,yytext);
		}

"break"	{
			fprintf(tokenout," <BREAK> ");
			fprintf(logout,"\nLine no %d: TOKEN <BREAK> Lexeme %s found\n",yylineno,yytext);
		}

"int"	{
			fprintf(tokenout," <INT> ");
			fprintf(logout,"\nLine no %d: TOKEN <INT> Lexeme %s found\n",yylineno,yytext);
		}

"char"	{
			fprintf(tokenout," <CHAR> ");
			fprintf(logout,"\nLine no %d: TOKEN <CHAR> Lexeme %s found\n",yylineno,yytext);
		}

"float"	{
			fprintf(tokenout," <FLOAT> ");
			fprintf(logout,"\nLine no %d: TOKEN <FLOAT> Lexeme %s found\n",yylineno,yytext);
		}

"double"	{
			fprintf(tokenout," <DOUBLE> ");
			fprintf(logout,"\nLine no %d: TOKEN <DOUBLE> Lexeme %s found\n",yylineno,yytext);
		}

"void"	{
			fprintf(tokenout," <VOID> ");
			fprintf(logout,"\nLine no %d: TOKEN <VOID> Lexeme %s found\n",yylineno,yytext);
		}

"return"	{
			fprintf(tokenout," <RETURN> ");
			fprintf(logout,"\nLine no %d: TOKEN <RETURN> Lexeme %s found\n",yylineno,yytext);
		}

"switch"	{
			fprintf(tokenout," <SWITCH> ");
			fprintf(logout,"\nLine no %d: TOKEN <SWITCH> Lexeme %s found\n",yylineno,yytext);
		}

"case"	{
			fprintf(tokenout," <CASE> ");
			fprintf(logout,"\nLine no %d: TOKEN <CASE> Lexeme %s found\n",yylineno,yytext);
		}

"default"	{
			fprintf(tokenout," <DEFAULT> ");
			fprintf(logout,"\nLine no %d: TOKEN <DEFAULT> Lexeme %s found\n",yylineno,yytext);
		}

"continue"	{
			fprintf(tokenout," <CONTINUE> ");
			fprintf(logout,"\nLine no %d: TOKEN <CONTINUE> Lexeme %s found\n",yylineno,yytext);
		}

{_char} {
			str1=yytext[1];
			fprintf(tokenout," <CONST_CHAR, %s> ",str1.c_str());
			fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",yylineno,str1.c_str());
			insert_conf=symbolTable->Insert(str1.c_str(),"CONST_CHAR");
			if(!insert_conf){
				fprintf(logout,"\n%s already exists in current ScopeTable\n",str1.c_str());
			}
			else{
				str=symbolTable->PrintAll();
				fprintf(logout,str.c_str());
			}
		}

{esc_char}	{
			str1=Escape(yytext);
			str1=str1[1];
			fprintf(tokenout," <CONST_CHAR, %s> ",str1.c_str());
			fprintf(logout,"\nLine no %d: TOKEN <CONST_CHAR> Lexeme %s found --> <CONST_CHAR, %s>\n",yylineno,yytext,str1.c_str());
			insert_conf=symbolTable->Insert(yytext,"CONST_CHAR");
			if(!insert_conf){
				fprintf(logout,"\n%s already exists in current ScopeTable\n",str1.c_str());
			}
			else{
				str=symbolTable->PrintAll();
				fprintf(logout,str.c_str());
			}
		}

{err_mul_char}	{
				fprintf(logout,"\nError at line no %d: Multi character constant error %s\n",yylineno,yytext);
				error++;
			}

{err_emp_char}	{
				fprintf(logout,"\nError at line no %d: Empty character constant error %s\n",yylineno,yytext);
				error++;
			}

{err_unf_char}	{
				str1=yytext;
				BEGIN MultipleChar;
			}
<MultipleChar>{nl} {
				LineCorrection(str1);
				fprintf(logout,"\nError at line no %d: Unterminated character %s\n",yylineno-1,str1.c_str());
				error++;
				BEGIN INITIAL;
			}

{err_inv_id} {
				fprintf(logout,"\nError at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n",yylineno,yytext);
				error++;
			}

{err_ill}	{
				fprintf(logout,"\nError at line no %d: Ill formed number %s\n",yylineno,yytext);
				error++;
			}

{Single_Line_Comment} {
					str1=yytext;
					BEGIN SLC;
				}

<SLC>.|{nl}	{
			fprintf(logout,"\nLine no %d: Token <COMMENT> Lexeme %s found\n",yylineno-newline,str1.c_str());
			newline=0;
			BEGIN INITIAL;
			}

{cmnt_strt} {
			str="";
			str+=yytext;
			BEGIN MLC;
		}

<MLC>.|{nl} {
			str+=yytext;
		}

<MLC>{cmnt_end} {
			str+=yytext;
			LineCorrection(str);
			fprintf(logout,"\nLine no %d: Token <COMMENT> Lexeme %s found\n",yylineno-newline,str.c_str());
			newline=0;
			BEGIN INITIAL;
		}

<MLC><<EOF>> {
			LineCorrection(str);
			fprintf(logout,"\nError at line no %d: Unterminated comment %s\n",yylineno-newline,str.c_str());
			newline=0;
			error++;
			BEGIN INITIAL;
		}

{DIGIT}+	{
			fprintf(tokenout," <CONST_INT, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <CONST_INT> Lexeme %s found\n",yylineno,yytext);
			insert_conf=symbolTable->Insert(yytext,"CONST_INT");
			if(!insert_conf){
				fprintf(logout,"\n%s already exists in current ScopeTable\n",yytext);
			}
			else{
				str=symbolTable->PrintAll();
				fprintf(logout,str.c_str());
			}
			BEGIN STATE1;
		}
{float_num} {

			fprintf(tokenout," <CONST_FLOAT, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <CONST_FLOAT> Lexeme %s found\n",yylineno,yytext);
			insert_conf=symbolTable->Insert(yytext,"CONST_FLOAT");
			if(!insert_conf){
				fprintf(logout,"\n%s already exists in current ScopeTable\n",yytext);
			}
			else{
				str=symbolTable->PrintAll();
				fprintf(logout,str.c_str());
			}
			BEGIN STATE1;
		}

{err_mul_point} {
				fprintf(logout,"\nError at line no %d: Too many decimal points %s\n",yylineno,yytext);
				error++;
			}

{ALPHANUMERIC} {
			fprintf(tokenout," <ID, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ID> Lexeme %s found\n",yylineno,yytext);
			insert_conf=symbolTable->Insert(yytext,"ID");
			if(!insert_conf){
				fprintf(logout,"\n%s already exists in current ScopeTable\n",yytext);
			}
			else{
				str=symbolTable->PrintAll();
				fprintf(logout,str.c_str());
			}
			BEGIN STATE1;
		}

<STATE1>"+"		|
<STATE1>"-"		{
			fprintf(tokenout," <ADDOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ADDOP> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"-"		|
"+"		{}

"*"		|
"/"		|
"%"		{
			fprintf(tokenout," <MULOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <MULOP> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"++"	|
"--"	{
			fprintf(tokenout," <INCOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <INCOP> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"="		{
			fprintf(tokenout," <ASSIGNOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"!"		{
			fprintf(tokenout," <NOT, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <NOT> Lexeme %s found\n",yylineno,yytext);
		}

"("		{
			fprintf(tokenout," <LPAREN, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LPAREN> Lexeme %s found\n",yylineno,yytext);
		}

")"		{
			fprintf(tokenout," <RPAREN, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RPAREN> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"["		{
			fprintf(tokenout," <LTHIRD, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LTHIRD> Lexeme %s found\n",yylineno,yytext);
		}

"]"		{
			fprintf(tokenout," <RTHIRD, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RTHIRD> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

","		{
			fprintf(tokenout," <COMMA, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <COMMA> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

";"		{
			fprintf(tokenout," <SEMICOLON, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <SEMICOLON> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"||"	|
"&&"	{
			fprintf(tokenout," <LOGICOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LOGICOP> Lexeme %s found\n",yylineno,yytext);
		}

"<"		|
">"		|
"<="	|
">="	|
"=="	|
"!="	{
			fprintf(tokenout," <RELOP, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RELOP> Lexeme %s found\n",yylineno,yytext);
			BEGIN INITIAL;
		}

"{"		{
			fprintf(tokenout," <LCURL, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <LCURL> Lexeme %s found\n",yylineno,yytext);
			symbolTable->EnterScope();
		}

"}"		{
			fprintf(tokenout," <RCURL, %s> ",yytext);
			fprintf(logout,"\nLine no %d: TOKEN <RCURL> Lexeme %s found\n",yylineno,yytext);
			symbolTable->ExitScope();
			str=symbolTable->PrintAll();
			fprintf(logout,str.c_str());
		}

{dq}	{
		str="";
		str+=yytext;
		BEGIN MultiLineStr;
	}	

<MultiLineStr>[^\"\\\n\r"]+ {
		str+=yytext;
	}

<MultiLineStr>{bs}{dq}|{bs}({nl})+ {
		str+=yytext;
	}

<MultiLineStr>{bs}. {
		str+=yytext;
	}

<MultiLineStr>{dq} {
		str+=yytext;
		str=LineCorrection(str);
		str1=Escape(str);
		str1=EscapeNewLine(str1);
		fprintf(tokenout,"<STRING ,%s>",str1.c_str());
		fprintf(logout,"\nLine no %d: TOKEN <STRING> Lexeme %s found\n",yylineno-newline,str.c_str());
		BEGIN INITIAL;
	}

<MultiLineStr>{nl} {
		newline=0;
		str+=yytext;
		str=LineCorrection(str);
		fprintf(logout,"\nError at line no %d: Unterminated string %s\n",yylineno-newline,str.c_str());
		newline=0;
		error++;
		BEGIN INITIAL;
	}

<MultiLineStr>. {
		LineCorrection(str);
		fprintf(logout,"\nError at line no %d: Unrecognized string %s\n",yylineno-newline,str.c_str());
		newline=0;
		error++;
		BEGIN INITIAL;
	}

<MultiLineStr><<EOF>> {
		LineCorrection(str);
		fprintf(logout,"\nError at line no %d: Unterminated string %s\n",yylineno-newline,str.c_str());
		newline=0;
		error++;
		BEGIN INITIAL;
	}
. {
		fprintf(logout,"\nError at line no %d: Unrecognized string %s\n",yylineno,yytext);
		error++;
	}
%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	logout= fopen("log.txt","w");
	tokenout= fopen("token.txt","w");

	yyin= fin;
    yylineno=1;
	yylex();
	fprintf(logout,"\nTotal line:%d\n",yylineno);
	fprintf(logout,"Total errors:%d\n",error);
	fclose(yyin);
	fclose(tokenout);
	fclose(logout);
	return 0;
}