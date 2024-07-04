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
    void Print();
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
    cout<<endl<<"New ScopeTable with id "<<id<<" created"<<endl;
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
        cout<<endl<<"Inserted in ScopeTable# "<<id<<" at position "<<ind<<", "<<pos<<endl;
        return true;
    } else {
        cout<<endl<<"< "<<name<<" , "<<type<<" >"<<" already exists in current ScopeTable"<<endl;
        return false;
    }
}

SymbolInfo* ScopeTable::LookUp(string name) {
    int pos=0;
    unsigned int ind= sdbm(name);
    SymbolInfo *temp = scopeTable[ind];
    while (temp != nullptr) {
        if(temp->getName()==name) {
            cout<<endl<<"Found in ScopeTable# "<<id<<" at position "<<ind<<", "<<pos<<endl;
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
    cout<<endl<<name<<" not found"<<endl;
    return false;
}

void ScopeTable::Print() {
    cout<<endl<<"ScopeTable # "<<id<<endl;
    for(int i=0;i<Bucket_size;i++) {
        SymbolInfo *temp = scopeTable[i];
        cout<<i<<" --> ";
        while (temp != nullptr) {
            if(temp->getNext()!= nullptr)
                cout<<" < "<< temp->getName()<<" : "<<temp->getType()<<" > ";
            else
                cout<<" < "<< temp->getName()<<" : "<<temp->getType()<<" > ";
            temp = temp->getNext();
        }
        cout<<endl;
    }
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
    cout<<endl<<"ScopeTable with id "<<id<<" removed"<<endl;
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
    void PrintAll();
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
    cout<<endl<<"Not found"<<endl;
    return false;
}

bool SymbolTable::Remove(string s) {
    if(currentScopeTable->LookUp(s)== nullptr)cout<<endl<<"Not Found"<<endl;
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

void SymbolTable::PrintAll() {
    ScopeTable* temp=currentScopeTable;

    while(temp!= nullptr){
        temp->Print();
        temp=temp->getParent();
    }
}

void SymbolTable::ExitScope() {
    if(currentScopeTable== nullptr){
        cout<<endl<<"No Current Scope"<<endl;
        return;
    }
    ScopeTable* temp=currentScopeTable;
    currentScopeTable=temp->getParent();
    delete temp;
}

int main(){
    fstream file;
    file.open("C:\\Users\\dell\\CLionProjects\\untitled\\1805028_input.txt",ios::in);
    if (file.is_open()){
        string str;
        getline(file,str);
        string x=str;
        stringstream func(x);
        int n = 0;
        func >> n;
        SymbolTable* symbolTable=new SymbolTable(n);

        while(getline(file, str)){
            char* s=&str[0];
            char *ptr;
            ptr = strtok(s, " ");
            int i=0;
            string cmd[5];
            while (ptr != NULL)
            {
                cmd[i++]=ptr;
                ptr = strtok (NULL, " ");
            }

            if(cmd[0]=="I"){
                cout<<endl<<str<<endl;
                symbolTable->Insert(cmd[1],cmd[2]);
            }
            else if(cmd[0]=="S"){
                cout<<endl<<str<<endl;
                symbolTable->EnterScope();
            }
            else if(cmd[0]=="E"){
                cout<<endl<<str<<endl;
                symbolTable->ExitScope();
            }
            else if(cmd[0]=="L"){
                cout<<endl<<str<<endl;
                symbolTable->LookUp(cmd[1]);
            }

            else if(cmd[0]=="D"){
                cout<<endl<<str<<endl;
                symbolTable->Remove(cmd[1]);
            }
            else if(cmd[0]=="P"){
                cout<<endl<<str<<endl;
                if(cmd[1]=="C")symbolTable->PrintCurrent();
                else if(cmd[1]=="A")symbolTable->PrintAll();
            }
            else{
                cout<<endl<<str<<endl;
                cout<<"Invalid command"<<endl;
                break;
            }
        }
        file.close();
    }return 0;
}
