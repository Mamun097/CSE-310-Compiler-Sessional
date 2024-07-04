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
    SymbolInfo(string str1, string str2)
    {
        Name = str1;
        Type = str2;
        structType = "";
        dataType = "";
    }

string getName()
    {
        return Name;
    }

    void setSymbolName(string str)
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

    string getStructType(){
        return structType;
    }

    void setStructType(string str){
        structType = str;
    }

    string getDataType(){
        return dataType;
    }

    void setDataType(string str){
        dataType = str;
    }

    void addFuncParams(SymbolInfo si){
        funcParams.push_back(si);
    }

    vector<SymbolInfo> getFuncParams(){
        return funcParams;
    }

};