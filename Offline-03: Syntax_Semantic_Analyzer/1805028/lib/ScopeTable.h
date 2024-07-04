#include <bits/stdc++.h>
#include "SymbolInfo.h"
using namespace std;

class ScopeTable
{
    string id;
    int totalBuckets;
    int child;
    ScopeTable* parentScope;
    vector<SymbolInfo> *hashTable;

public:
    ScopeTable(int num, string str)
    {
        totalBuckets = num;
        id = str;
        hashTable = new vector<SymbolInfo>[totalBuckets];
        parentScope = NULL;
        child = 0;
    }

    string getId()
    {
        return id;
    }

    void makeParentScope(ScopeTable* st)
    {
        parentScope = st;
    }

    ScopeTable* getParentScope()
    {
        return parentScope;
    }

    void setChildCount(int n)
    {
        child = n;
    }

    void setHashTableSize(int num)
    {
        totalBuckets = num;
    }

    int getChildCount()
    {
        return child;
    }

    int sdbm(string s)
    {
        unsigned int hash = 0;
        int c;
        char* str;
        str=&s[0];
        while(c=*str++)
        {
           hash = c + (hash << 6) + (hash << 16) - hash;
        }
        return hash%totalBuckets;
    }

    bool LookupBoolean(string str)
    {
        bool isFound = false;
        int hash = sdbm(str);
        for(int i=0; i<hashTable[hash].size(); i++)
        {
            if(hashTable[hash][i].getName() == str)
            {
                isFound = true;
                break;
            }
        }
        return isFound;
    }

    bool Insert(SymbolInfo si)
    {
        bool isFound = LookupBoolean(si.getName());

        if(isFound == false)
        {
            int hash = sdbm(si.getName());
            hashTable[hash].push_back(si);
            return true;
        }
        else return false;
    }

    bool Delete(string Name)
    {
        int hash= sdbm(Name);
        SymbolInfo* pos = Lookup(Name);
        int index = -1;
        if(pos != NULL)
        {
            for(int i=0; i<hashTable[hash].size(); i++)
            {
                if(hashTable[hash][i].getName()==Name)
                    index = i;

            }
            swap(*pos, hashTable[hash][hashTable[hash].size()-1]);
            hashTable[hash].pop_back();
            return true;
        }
        else return false;

    }

    SymbolInfo* Lookup(string str)
    {
        int hash = sdbm(str);
        SymbolInfo* temp = NULL;
        for(int i=0; i<hashTable[hash].size(); i++)
        {
            if(hashTable[hash][i].getName() == str)
            {
                temp = &hashTable[hash][i];
                break;
            }
        }
        return temp;
    }

    void Print(ofstream& logFile)
    {
        logFile << "ScopeTable # " << id << endl;
        for(int i=0; i<totalBuckets; i++)
        {
            if(hashTable[i].size()==0)
                continue;
            logFile << i << " --> ";
            for(auto j : hashTable[i])
            {
                logFile<< " < " << j.getName() << " , " << j.getType() << " >  ";
            }
            logFile<<endl;
        }
        logFile<<endl;
    }

    ~ScopeTable()
    {
        delete [] hashTable;
    }

};