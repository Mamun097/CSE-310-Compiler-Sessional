#include <bits/stdc++.h>
#include "ScopeTable.h"
using namespace std;

class SymbolTable
{
    vector<ScopeTable> scope;

    ScopeTable* current;
    ScopeTable* temp;

    int totalBucket;
    string previousCount;
    int currentCount;

public:
    SymbolTable(int N)
    {
        totalBucket = N;
        previousCount = "1";
        current = new ScopeTable(totalBucket, previousCount);
        current->makeParentScope(NULL);
        temp = NULL;
    }

    ScopeTable* getCurrentScope()
    {
        return current;
    }

    SymbolInfo* Lookup(string Name)
    {
        SymbolInfo* x;
        temp = current;
        while(temp != NULL)
        {
            x = temp->Lookup(Name);
            if(x != NULL)
                break;
            else
                temp = temp->getParentScope();
        }

        return x;
    }

    bool Insert(SymbolInfo symbol)
    {
        return current->Insert(symbol);
    }

    bool Remove(string Name)
    {
        return current->Delete(Name);
    }

    void EnterScope()
    {
        string newId = current->getId() + "." + to_string(current->getChildCount()+1);
        current->setChildCount(current->getChildCount()+1);
        temp = new ScopeTable(totalBucket, newId);
        temp->makeParentScope(current);
        current = temp;
    }

    void ExitScope()
    {
        temp = current->getParentScope();
        delete current;
        current = temp;
    }

    void PrintCurrentTable(ScopeTable* st, ofstream& logFile)
    {
        st->Print(logFile);
    }

    void PrintAllTables(ofstream& logFile)
    {
        temp = current;
        while(temp != NULL)
        {
            PrintCurrentTable(temp, logFile);
            temp = temp->getParentScope();
        }
    }

    ~SymbolTable()
    {
        delete current;
    }
};