# CSE-310-Compiler-Sessional

This repository includes various components of a compiler: symbol table, lexical analyzer, syntax and semantic analyzer, and intermediate code generation.

## Symbol Table

1. **Definition**: A symbol table is a data structure used by a compiler to keep track of information about the various symbols (such as variables, functions, objects, etc.) used in the source code.
2. **Purpose**: It stores information like the symbol's name, type, scope, and memory location. This helps the compiler in various stages of translation and optimization.
3. **Operations**: Common operations include insertion (adding a new symbol), lookup (retrieving information about a symbol), and deletion (removing a symbol from the table).
4. **Scope Management**: It manages different scopes (like local, global) and ensures that symbols are accessed correctly according to their visibility and lifetime.

## Lexical Analyzer (using Flex)

1. **Definition**: The lexical analyzer (or lexer) is the first phase of a compiler that converts the sequence of characters in the source code into a sequence of tokens.
2. **Flex Tool**: Flex (Fast Lexical Analyzer) is a tool for generating lexical analyzers. It reads a specification file containing regular expressions and generates C code for the lexer.
3. **Functionality**: The lexer scans the input code, matches patterns specified by regular expressions, and produces tokens which are meaningful sequences like keywords, identifiers, literals, etc.
4. **Error Handling**: It detects and reports lexical errors (such as illegal characters) in the source code.

## Syntax and Semantic Analyzer (using Bison)

1. **Syntax Analyzer**: This phase, also known as parsing, checks the token sequence from the lexer against the grammatical rules of the programming language. It builds a parse tree or abstract syntax tree (AST).
2. **Bison Tool**: Bison is a parser generator that takes a context-free grammar specification and generates a parser in C. It works well with Flex to create a full parser.
3. **Semantic Analyzer**: This phase checks the parse tree for semantic consistency, such as type checking, scope resolution, and ensuring that operations are valid (e.g., no division by zero).
4. **Error Handling**: It detects and reports syntactic and semantic errors, ensuring that the code adheres to language rules beyond just syntax.

## Intermediate Code Generation (to Assembly 8086)

1. **Definition**: Intermediate code generation is the process of translating the parse tree or AST into an intermediate representation (IR) that is independent of the target machine.
2. **Purpose**: The IR simplifies optimization and makes the compiler more portable as it can be translated to any target machine code.
3. **8086 Assembly**: In this context, the IR is further translated into assembly language specific to the 8086 microprocessor, which involves generating instructions that the CPU can execute.
4. **Optimization**: During this phase, various optimizations can be applied to improve the performance and efficiency of the generated code before final translation to machine code.

## Getting Started

To get started with this repository, clone it using:

```bash
git clone https://github.com/Mamun097/CSE-310-Compiler-Sessional.git
