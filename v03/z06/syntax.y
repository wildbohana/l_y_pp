%{
	#include <stdio.h>
	#include "defs.h"

	int yyparse(void);
	int yylex(void);
	int yyerror(char *s);
	extern int yylineno;
%}

%token _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token _ID
%token _INT_NUMBER
%token _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token _AROP
%token _RELOP

%token _COMMA

%token _SELECT
%token _FROM
%token _WHERE

%token _DO
%token _WHILE

%token _INC

%token _FOR
%token _NEXT
%token _STEP
%token _DIRECTION

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
	: function_list
	;

function_list
	: function
	| function_list function
	;

function
	: type _ID _LPAREN parameter _RPAREN body
	;

type
	: _TYPE
	;

parameter
	: /* empty */
	| type _ID
	;

body
	: _LBRACKET variable_list statement_list _RBRACKET
	;

variable_list
	: /* empty */
	| variable_list variable
	;

variable
	: type vars _SEMICOLON
	;

vars
	: _ID
	| vars _COMMA _ID
	;

statement_list
	: /* empty */
	| statement_list statement
	;

statement
	: compound_statement
	| assignment_statement
	| if_statement
	| select_statement
	| do_statement
	| inc_statement
	| for_statement
	| return_statement
	;

select_statement
	: _SELECT vars _FROM _ID _WHERE _LPAREN rel_exp _RPAREN _SEMICOLON
	;

do_statement
	: _DO statement _WHILE _LPAREN rel_exp _RPAREN _SEMICOLON
	;

compound_statement
	: _LBRACKET statement_list _RBRACKET
	;

assignment_statement
	: _ID _ASSIGN num_exp _SEMICOLON
	;

inc_statement
	: _ID _INC _SEMICOLON
	;

num_exp
	: exp
	| num_exp _AROP exp
	;

for_statement
	: _FOR _ID _ASSIGN literal _DIRECTION literal step statement _NEXT _ID
	;

step
	:
	| _STEP literal
	;

exp
	: literal
	| _ID
	| _ID _INC
	| function_call
	| _LPAREN num_exp _RPAREN
	;

literal
	: _INT_NUMBER
	| _UINT_NUMBER
	;

function_call
	: _ID _LPAREN argument_list _RPAREN
	;

argument_list
	:
	| arguments
	;

arguments
	: num_exp
	| arguments _COMMA num_exp
	;

function
	: type _ID _LPAREN parameter_list _RPAREN body
	;

parameter_list
	:
	| parameters
	;

parameters
	: parameter
	| parameters _COMMA parameter
	;

parameter
	: type _ID
	;

argument
	: /* empty */
	| num_exp
	;

if_statement
	: if_part %prec ONLY_IF
	| if_part _ELSE statement
	;

if_part
	: _IF _LPAREN rel_exp _RPAREN statement
	;

rel_exp
	: num_exp _RELOP num_exp
	;

return_statement
	: _RETURN num_exp _SEMICOLON
	;

%%

int yyerror(char *s) {
	fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
	return 0;
}

int main() {
	return yyparse();
}
