#include <iostream>
#include <fstream>
#include <string>
#include <cstring>
#include <sstream>
using namespace std;

class SymbolInfo
{
private:
    string Name;
    string Type;
    SymbolInfo* next= nullptr;
public:
    ~SymbolInfo();
    void setName(string str);
    string getName();
    void setType(string str);
    string getType();
    void setNext(SymbolInfo* n);
    SymbolInfo* getNext();
};
void SymbolInfo::setName(string str) {
    Name=str;
}
void SymbolInfo::setNext(SymbolInfo * n) {
    next=n;
}
string SymbolInfo::getName() {
    return Name;
}
SymbolInfo *SymbolInfo::getNext() {
    return next;
}

void SymbolInfo::setType(string s) {
    Type=s;
}

string SymbolInfo::getType() {
    return Type;
}

SymbolInfo::~SymbolInfo() {
    delete next;
}

class ScopeTable{
private:
    SymbolInfo** scopeTable;
    ScopeTable* parentScope;
    string id;
    int Bucket_size;
    int child;
public:
    ScopeTable(int n);
    ScopeTable(int n, ScopeTable* ptr);
    ~ScopeTable();
    unsigned int sdbm(string s);
    bool Insert(string name, string type);
    SymbolInfo* LookUp(string name);
    bool Delete(string name);
    string Print();
    ScopeTable* getParent();
    string getID();
    int getChild();
    void setChild(int num);
};

ScopeTable::ScopeTable(int n) {
    scopeTable=new SymbolInfo*[n];
    for(int i=0;i<n;i++)
        scopeTable[i]= nullptr;
    Bucket_size=n;
    child=0;
    parentScope= nullptr;
    id="1";
}

unsigned int ScopeTable::sdbm( string s )
{
    unsigned int hash = 0;
    int c;
    char* str;
    str=&s[0];
    while(c=*str++)
    {
        hash = c + (hash << 6) + (hash << 16) - hash;
    }
    return hash%Bucket_size;
}

ScopeTable::ScopeTable(int n, ScopeTable *ptr){
    scopeTable=new SymbolInfo*[n];
    for(int i=0;i<n;i++)
        scopeTable[i]= nullptr;
    Bucket_size=n;
    child=0;
    parentScope= ptr;
    id=parentScope->getID()+"."+ to_string(parentScope->getChild());
}

bool ScopeTable::Insert(string name, string type) {
    if (LookUp(name) == nullptr) {
        SymbolInfo *temp = new SymbolInfo;
        temp->setName(name);
        temp->setType(type);

        int pos=0;
        unsigned int ind = sdbm(name);
        SymbolInfo *current = scopeTable[ind];

        if(current== nullptr)scopeTable[ind] = temp;
        else{
            while(current->getNext()!= nullptr){
                pos++;
                current=current->getNext();
            }
            current->setNext(temp);
            pos++;
        }
        return true;
    } else {
        return false;
    }
}

SymbolInfo* ScopeTable::LookUp(string name) {
    int pos=0;
    unsigned int ind= sdbm(name);
    SymbolInfo *temp = scopeTable[ind];
    while (temp != nullptr) {
        if(temp->getName()==name) {
            return temp;
        }
        else{
            pos++;
            temp = temp->getNext();
        }
    }
    return nullptr;
}

bool ScopeTable::Delete(string name) {
    unsigned int ind= sdbm(name);
    SymbolInfo *current=scopeTable[ind];
    SymbolInfo* head=scopeTable[ind];
    SymbolInfo* prev=scopeTable[ind];

    int pos=0;
    while (current!= nullptr) {
        if(current->getName()==name){
            if(current==head){
                scopeTable[ind]=current->getNext();
            }
            else{
                prev->setNext(current->getNext());
            }
            cout<<endl<<"Deleted Entry "<<ind<<", "<<pos<<" from current ScopeTable"<<endl;
            delete current;
            return true;
        }
        pos++;
        prev=current;
        current=current->getNext();
    }
    return false;
}

string ScopeTable::Print() {
    string str="\nScopeTable # "+id+"\n";
    
    for(int i=0;i<Bucket_size;i++) {
        SymbolInfo *temp = scopeTable[i];
        if(temp != nullptr)
            str=str+std::to_string(i)+" --> ";
        while (temp != nullptr) {
            if(temp->getNext()!= nullptr)
                str=str+" < "+temp->getName()+" : "+temp->getType()+" > ";
            else
                str=str+" < "+temp->getName()+" : "+temp->getType()+" > \n";
            temp = temp->getNext();
        }
    }
    return str;
}


ScopeTable *ScopeTable::getParent() {
    return parentScope;
}

string ScopeTable::getID() {
    return id;
}

int ScopeTable::getChild() {
    return child;
}

void ScopeTable::setChild(int num) {
    child=num;
}

ScopeTable::~ScopeTable() {
    for(int i=0;i<Bucket_size;i++)
        delete scopeTable[i];
    delete[] scopeTable;
}

class SymbolTable{
private:
    ScopeTable* currentScopeTable= nullptr;
public:
    int bucketSize;
    SymbolTable(int num);
    void EnterScope();
    void ExitScope();
    bool Insert(string s1, string s2);
    bool Remove(string s);
    bool LookUp(string s);
    void PrintCurrent();
    string PrintAll();
    ~SymbolTable();
};

SymbolTable::SymbolTable(int num) {
    currentScopeTable=new ScopeTable(num);
    bucketSize=num;
}

bool SymbolTable::LookUp(string s) {
    ScopeTable* temp=currentScopeTable;
    while(temp!= nullptr){
        if(temp->LookUp(s)!= nullptr){
            return true;
        }
        else{
            temp=temp->getParent();
        }
    }
    return false;
}

bool SymbolTable::Remove(string s) {
    return currentScopeTable->Delete(s);
}

void SymbolTable::EnterScope() {
    currentScopeTable->setChild(currentScopeTable->getChild()+1);
    ScopeTable* newScope= new ScopeTable(bucketSize, currentScopeTable);
    currentScopeTable=newScope;
}

bool SymbolTable::Insert(string s1, string s2) {
    if(currentScopeTable== nullptr){
        currentScopeTable=new ScopeTable(bucketSize);
    }
    return currentScopeTable->Insert(s1,s2);
}

void SymbolTable::PrintCurrent() {
    if(currentScopeTable!= nullptr)
        currentScopeTable->Print();
}

SymbolTable::~SymbolTable() {
    delete currentScopeTable;
}

string SymbolTable::PrintAll() {
    ScopeTable* temp=currentScopeTable;
    string str="";

    while(temp!= nullptr){
        str+=temp->Print();
        temp=temp->getParent();
    }
    return str;
}

void SymbolTable::ExitScope() {
    if(currentScopeTable== nullptr){
        return;
    }
    ScopeTable* temp=currentScopeTable;
    currentScopeTable=temp->getParent();
    delete temp;
}