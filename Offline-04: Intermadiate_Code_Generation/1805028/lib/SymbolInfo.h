#include <bits/stdc++.h>
using namespace std;

class SymbolInfo
{
    string Name;
    string Type;
    string structType;
    string dataType;
    vector<SymbolInfo> funcParams;

public:
    string code;
    SymbolInfo(string str1, string str2)
    {
        Name = str1;
        Type = str2;
        code="";
        structType = "";
        dataType = "";
    }

void setCode(string _code){
    code=_code;
}

string getCode(){
    return code;
}

string getName()
    {
        return Name;
    }

    void setName(string str)
    {
        Name = str;
    }

string getType()
    {
        return Type;
    }

    void setSymbolType(string str)
    {
        Type = str;
    }

    string Get_StructType(){
        return structType;
    }

    void Set_StructType(string str){
        structType = str;
    }

    string Get_DataType(){
        return dataType;
    }

    void Set_DataType(string str){
        dataType = str;
    }

    void addFuncParams(SymbolInfo si){
        funcParams.push_back(si);
    }

    vector<SymbolInfo> getFuncParams(){
        return funcParams;
    }

};