%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "defs.h"
	#include "symtab.h"

	int yyparse(void);
	int yylex(void);
	int yyerror(char *s);
	void warning(char *s);

	extern int yylineno;
	char char_buffer[CHAR_BUFFER_LENGTH];
	int error_count = 0;
	int warning_count = 0;
	int var_num = 0;
	int fun_idx = -1;
	int fcall_idx = -1;

	int return_cnt = 0;

	// btw literalima se brojevna vrednost u tabeli simbola
	// upisuje kao ime (vrednost se dobija preko get_name)
	int branch_pom;

	int switch_id_index = 0;
	int case_count = 0;
	int case_array[100];
%}

%union {
	int i;
	char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP

%token _FOR
%token _INC

%token _BRANCH
%token _FIRST
%token _SECOND
%token _THIRD
%token _OTHERWISE

%token _COMMA

%token _SWITCH
%token _CASE
%token _BREAK
%token _DEFAULT
%token _COLON

%type <i> num_exp exp literal function_call argument rel_exp

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
	: function_list
		{  
			if (lookup_symbol("main", FUN) == NO_INDEX)
				err("undefined reference to 'main'");
		}
	;

function_list
	: function
	| function_list function
	;

function
	: _TYPE _ID
		{
			fun_idx = lookup_symbol($2, FUN);
			if (fun_idx == NO_INDEX)
				fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
			else 
				err("redefinition of function '%s'", $2);
		}
	_LPAREN parameter _RPAREN body
		{
			clear_symbols(fun_idx + 1);
			var_num = 0;

			if ((return_cnt == 0) && (get_type(fun_idx) != VOID))
				warn("function should return a value");
			
			return_cnt = 0;
		}
	;

parameter
	: /* empty */
		{ set_atr1(fun_idx, 0); }
	| _TYPE _ID
		{
			if ($1 == VOID)
				err("parameter cannot be of VOID type");
			else
			{
				insert_symbol($2, PAR, $1, 1, NO_ATR);
				set_atr1(fun_idx, 1);
				set_atr2(fun_idx, $1);
			}
		}
	;

body
	: _LBRACKET variable_list statement_list _RBRACKET
	;

variable_list
	: /* empty */
	| variable_list variable
	;

variable
	: _TYPE _ID _SEMICOLON
		{
			if ($1 == VOID)
				err("variable cannot be of VOID type");
			else if (lookup_symbol($2, VAR|PAR) == NO_INDEX)
				insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
			else 
				err("redefinition of '%s'", $2);
		}
	;

statement_list
	: /* empty */
	| statement_list statement
	;

statement
	: compound_statement
	| assignment_statement
	| if_statement
	| return_statement
	| for_statement
	| branch_statement
	| switch_statement
	;

switch_statement
	: _SWITCH _LPAREN _ID
		{
			if ((switch_id_index = lookup_symbol($3, VAR)) == -1)
				err("'%s' undeclared", $3);
		} 
	_RPAREN _LBRACKET case_statements default_statement _RBRACKET 
		{
			case_count = 0;
		}
	;

case_statements	
	: case_statement 
	| case_statements case_statement
	;

case_statement
	: _CASE literal _COLON
		{
			int i = 0;
			while (i < case_count)
			{
				if ($2 == case_array[i])
				{
					err("duplicated constant in case");
					break;
				}
				i++;
			}

			if (i == case_count)
			{
				case_array[case_count] = $2;
				case_count++;
			}

			if (get_type($2) != get_type(switch_id_index))
				err("wrong type of constant");
		} 
	statement break_statement
	;

break_statement
	: 
	| _BREAK _SEMICOLON
	;

default_statement
	:
	| _DEFAULT _COLON statement
	;

branch_statement
	: _BRANCH _LPAREN _ID
		{
			int idx = lookup_symbol($3, VAR|PAR);
			if (idx == NO_INDEX)
				err("'%s' is undeclared", $3);
		} 
	_SEMICOLON literal 
		{
			int idx = lookup_symbol($3, VAR|PAR);
			if (get_type(idx) != get_type($6))
				err("incompatible types...");
			
			branch_pom = atoi(get_name($6));
		}
	_COMMA literal 
		{
			int idx = lookup_symbol($3, VAR|PAR);
			if (get_type(idx) != get_type($9))
				err("incompatible types...");
			
			int pom = atoi(get_name($9));
			if (pom < branch_pom)
				err("const2 must be greater than const1");
			branch_pom = pom;
		}
	_COMMA literal 
		{
			int idx = lookup_symbol($3, VAR|PAR);
			if (get_type(idx) != get_type($12))
				err("incompatible types...");
			
			int pom = atoi(get_name($12));
			if (pom < branch_pom)
				err("const3 must be greater than const2");
			branch_pom = pom;
		}
	_RPAREN _FIRST statement _SECOND statement _THIRD statement _OTHERWISE statement
	;

for_statement
	: _FOR _LPAREN _TYPE _ID
		{
			int i = lookup_symbol($4, PAR|VAR);
			if (i != -1)
				err("redefinition of variable '%s'", $4);
			else 
				$<i>$ = insert_symbol($4, VAR, $3, 1, NO_ATR);
		} 
	_ASSIGN literal
		{
			if ($3 != get_type($7))
				err("incompatible types in assignment!");
		}
	_SEMICOLON rel_exp _SEMICOLON _ID
		{
			$<i>$ = lookup_symbol($12, VAR);
			if ($<i>5 != $<i>$)
				err("wrong var for increment");
		}
	_INC _RPAREN statement
		{
			clear_symbols($<i>5);
		}
	;

compound_statement
	: _LBRACKET statement_list _RBRACKET
	;

assignment_statement
	: _ID _ASSIGN num_exp _SEMICOLON
		{
			int idx = lookup_symbol($1, VAR|PAR);
			if (idx == NO_INDEX)
				err("invalid lvalue '%s' in assignment", $1);
			else
				if (get_type(idx) != get_type($3))
					err("incompatible types in assignment");
		}
	;

num_exp
	: exp
	| num_exp _AROP exp
		{
			if (get_type($1) != get_type($3))
				err("invalid operands : arithmetic operation");
		}
	;

exp
	: literal
	| _ID
		{
			$$ = lookup_symbol($1, VAR|PAR);
			if ($$ == NO_INDEX)
				err("'%s' undeclared", $1);
		}
	| function_call
	| _LPAREN num_exp _RPAREN
		{ $$ = $2; }
	;

literal
	: _INT_NUMBER
		{ $$ = insert_literal($1, INT); }
	| _UINT_NUMBER
		{ $$ = insert_literal($1, UINT); }
	;

function_call
	: _ID 
		{
			fcall_idx = lookup_symbol($1, FUN);
			if (fcall_idx == NO_INDEX)
				err("'%s' is not a function", $1);
		}
	_LPAREN argument _RPAREN
		{
			if (get_atr1(fcall_idx) != $4)
				err("wrong number of args to function '%s'", get_name(fcall_idx));
			set_type(FUN_REG, get_type(fcall_idx));
			$$ = FUN_REG;
		}
	;

argument
	: /* empty */
		{ $$ = 0; }
	| num_exp
		{ 
			if (get_atr2(fcall_idx) != get_type($1))
				err("incompatible type for argument in '%s'", get_name(fcall_idx));
			$$ = 1;
		}
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
		{
			if (get_type($1) != get_type($3))
				err("invalid operands : relational operator");
		}
	;

return_statement
	: _RETURN num_exp _SEMICOLON
		{
			if (get_type(fun_idx) == 0)
				err("function cannot return value");
			else if (get_type(fun_idx) != get_type($2))
				err("incompatible types in return");
			return_cnt++;
		}
	| _RETURN _SEMICOLON
		{
			if (get_type(fun_idx) != VOID)
				warn("function should return a value");
			return_cnt++;
		}
	;

%%

int yyerror(char *s) {
	fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
	error_count++;
	return 0;
}

void warning(char *s) {
	fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
	warning_count++;
}

int main() {
	int synerr;
	init_symtab();

	synerr = yyparse();

	clear_symtab();
	
	if (warning_count)
		printf("\n%d warning(s).\n", warning_count);

	if (error_count)
		printf("\n%d error(s).\n", error_count);

	if (synerr)
		return -1; //syntax error
	else
		return error_count; //semantic errors
}

