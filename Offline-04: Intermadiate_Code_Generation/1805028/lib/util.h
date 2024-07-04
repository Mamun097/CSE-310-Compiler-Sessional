#include<bits/stdc++.h>
#include<iostream>
#include<cstdlib>
#include<cstring>

using namespace std;


string InitializeAssembly(set<string> varList, set<pair<string, string>> arrVarList ,string codeSegment){
	string Code = 
".MODEL SMALL\n\
.STACK 100H\n\n\
.DATA\n\
";
	for(auto i : varList){
		Code+=i+" DW '?'\n";
	}
	for(auto i : arrVarList){
		Code+=i.first+" DW DUP "+i.second+" (?)\n";
	}
	Code+=
"\n\n.CODE\n\
"
+codeSegment;

string outdec = 
"\n;OUTDEC PROC starts\
\nOUTDEC PROC\n\
PUSH AX\n\
PUSH BX\n\
PUSH CX\n\
PUSH DX\n\
OR AX, AX\n\
JGE @END_IF1\n\
\n\
PUSH AX\n\
MOV DL, '-'\n\
MOV AH, 2\n\
INT 21H\n\
POP AX\n\
NEG AX\n\
@END_IF1:\n\
XOR CX, CX\n\
MOV BX, 10D\n\
@REPEAT1:\n\
XOR DX, DX\n\
DIV BX\n\
PUSH DX\n\
INC CX\n\
OR AX, AX\n\
JNE @REPEAT1\n\
\n\
MOV AH, 2\n\
@PRINT_LOOP:\n\
POP DX\n\
OR DL, 30H\n\
INT 21H\n\
LOOP @PRINT_LOOP\n\
POP DX\n\
POP CX\n\
POP BX\n\
POP AX\n\
RET\n\
OUTDEC ENDP\n";
Code+= outdec;
Code+="\nEND MAIN";
return Code;
}

