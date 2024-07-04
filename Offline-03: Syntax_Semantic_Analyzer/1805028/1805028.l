%option noyywrap

%{
#include "bits/stdc++.h"
#include "lib/SymbolTable.h"
#include "y.tab.h"
using namespace std;

#define YYSTYPE SymbolInfo*

void yyerror(char*);

extern FILE *logFile;

extern int lineCount;
extern int errorCount;
extern SymbolTable st;

%}
/*Shorthands*/
bs "\\"
sqt "\'"
escape {bs}({bs}|{sqt}|[ntafrbv0])

/* Operators */
NEWLINE [\n|\r\n]
WHITESPACE [ \t\f\r\v]+

LPAREN ("(")
RPAREN (")")
LCURL ("{")
RCURL ("}")
LTHIRD ("[")
RTHIRD ("]")
ADDOP [+-]
MULOP [*/%]
INCOP ("++")
DECOP ("--")
RELOP (">"|">="|"<"|"<="|"=="|"!=")
ASSIGNOP ("=")
LOGICOP ("&&"|"||")
NOT ("!")

COMMA [,]
SEMICOLON [;]

/* Numbers and stuff */
DIGIT [0-9]
DIGITS {DIGIT}+

CONST_INT {DIGITS}
CONST_FLOAT ({DIGIT}*[.]{DIGIT}+)|({DIGIT}*[.]{0,1}{DIGIT}+[E][-]{0,1}{DIGIT}+)

/* Chars */
NORMAL_CHAR {sqt}[^\\\r\n]{sqt}
ESCAPE_CHAR {sqt}{escape}{sqt}
CONST_CHAR {NORMAL_CHAR}|{ESCAPE_CHAR}

ID [a-zA-Z_][a-zA-Z0-9_]*

%%

{WHITESPACE} {}
{NEWLINE} { lineCount++; }

"if" { 
	yylval.si=new SymbolInfo(yytext,"token");
	return IF; 
	}

"else" { 
	yylval.si=new SymbolInfo(yytext,"token");
	return ELSE; 
	}

"do" { 
	yylval.si=new SymbolInfo(yytext,"token");
	return DO; 
	}

"while" {
	yylval.si=new SymbolInfo(yytext,"token");
	return WHILE; 
	}
	
"for" {
	yylval.si=new SymbolInfo(yytext,"token");
	return FOR;
	}

"break" {
	yylval.si=new SymbolInfo(yytext,"token");
	return BREAK;
	}

"case" {
	yylval.si=new SymbolInfo(yytext,"token");
	return CASE;
	}

"continue" {
	yylval.si=new SymbolInfo(yytext,"token");
	return CONTINUE;
	}

"default" {
	yylval.si=new SymbolInfo(yytext,"token");
	return DEFAULT;
	}

"return" {
	yylval.si=new SymbolInfo(yytext,"token");
	return RETURN;
	}

"switch" {
	yylval.si=new SymbolInfo(yytext,"token");
	return SWITCH;
	}

"void" {
	yylval.si=new SymbolInfo(yytext,"token");
	return VOID;
	}

"char" {
	yylval.si=new SymbolInfo(yytext,"token");
	return CHAR;
	}

"double" {
	yylval.si=new SymbolInfo(yytext,"token");
	return DOUBLE;
	}

"float" {
	yylval.si=new SymbolInfo(yytext,"token");
	return FLOAT;
	}

"int" {
	yylval.si=new SymbolInfo(yytext,"token");
	return INT;
	}

"printf" {
	yylval.si=new SymbolInfo(yytext,"token");
	return PRINTLN;
	}

{ADDOP} {
	yylval.si=new SymbolInfo(yytext,"ADDOP");
	return ADDOP;
}

{MULOP} {
	yylval.si=new SymbolInfo(yytext,"MULOP");
	return MULOP;
}

{INCOP} {
	yylval.si=new SymbolInfo(yytext,"INCOP");
	return INCOP;
	}

{DECOP} {
	yylval.si=new SymbolInfo(yytext,"DECOP");
	return DECOP;
	}

{RELOP} {
	yylval.si=new SymbolInfo(yytext,"RELOP");
	return RELOP;
}

{ASSIGNOP} {
	yylval.si=new SymbolInfo(yytext,"ASSIGNOP");
	return ASSIGNOP;}

{LOGICOP} {
	yylval.si=new SymbolInfo(yytext,"LOGICOP");
	return LOGICOP;
}

{NOT} 	{
	yylval.si=new SymbolInfo(yytext,"NOT");
	return NOT;
	}

{LPAREN} {
	yylval.si=new SymbolInfo(yytext,"LPAREN");
	return LPAREN;
	}

{RPAREN} {
	yylval.si=new SymbolInfo(yytext,"RPAREN");
	return RPAREN;
	}

{LCURL} {
	yylval.si=new SymbolInfo(yytext,"LCURL");
	return LCURL;
	}

{RCURL} {
	yylval.si=new SymbolInfo(yytext,"RCURL");
	return RCURL;
	}

{LTHIRD} {
	yylval.si=new SymbolInfo(yytext,"LTHIRD");
	return LTHIRD;
	}

{RTHIRD} {
	yylval.si=new SymbolInfo(yytext,"RTHIRD");
	return RTHIRD;
	}

{COMMA} {
	yylval.si=new SymbolInfo(yytext,"COMMA");
	return COMMA;
	}

{SEMICOLON} {
	yylval.si=new SymbolInfo(yytext,"SEMICOLON");
	return SEMICOLON;
	}

{CONST_INT} {
	yylval.si=new SymbolInfo(yytext,"CONST_INT");
	return CONST_INT;
}

{CONST_FLOAT} {
	yylval.si=new SymbolInfo(yytext,"CONST_FLOAT");
	return CONST_FLOAT;
}

{CONST_CHAR} {
	yylval.si=new SymbolInfo(yytext,"CONST_CHAR");
	return CONST_CHAR;
}

{ID} {
	yylval.si=new SymbolInfo(yytext,"ID");
	return ID;
}
%%
