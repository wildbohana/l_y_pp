%{
	#include <stdio.h>
	#include <stdlib.h>
	#include "defs.h"
	#include "symtab.h"
	#include "codegen.h"

	int yyparse(void);
	int yylex(void);
	int yyerror(char *s);
	void warning(char *s);

	extern int yylineno;
	int out_lin = 0;
	char char_buffer[CHAR_BUFFER_LENGTH];
	int error_count = 0;
	int warning_count = 0;
	int var_num = 0;
	int fun_idx = -1;
	int fcall_idx = -1;
	int lab_num = -1;
	FILE *output;

	int case_count = 0;
	int case_array[100];
	int switch_id = -1;
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

%token _SWITCH
%token _CASE
%token _BREAK
%token _DEFAULT
%token _COLON

%type <i> default_statement

%type <i> num_exp exp literal
%type <i> function_call argument rel_exp if_part

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

			code("\n%s:", $2);
			code("\n\t\tPUSH\t%%14");
			code("\n\t\tMOV \t%%15,%%14");
		}
	_LPAREN parameter _RPAREN body
		{
			clear_symbols(fun_idx + 1);
			var_num = 0;
			
			code("\n@%s_exit:", $2);
			code("\n\t\tMOV \t%%14,%%15");
			code("\n\t\tPOP \t%%14");
			code("\n\t\tRET");
		}
	;

parameter
	: /* empty */
		{ 
			set_atr1(fun_idx, 0); 
		}

	| _TYPE _ID
		{
			insert_symbol($2, PAR, $1, 1, NO_ATR);
			set_atr1(fun_idx, 1);
			set_atr2(fun_idx, $1);
		}
	;

body
	: _LBRACKET variable_list
		{
			if (var_num)
				code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
			code("\n@%s_body:", get_name(fun_idx));
		}
	statement_list _RBRACKET
	;

variable_list
	: /* empty */
	| variable_list variable
	;

variable
	: _TYPE _ID _SEMICOLON
		{
			if (lookup_symbol($2, VAR|PAR) == NO_INDEX)
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
	| switch_statement
	;

switch_statement
	: _SWITCH _LPAREN _ID
		{
			if ( (switch_id = lookup_symbol($3, VAR)) == -1)
				err("'%s' undeclared", $3);
			lab_num++;
			code("\n@switch%d:", lab_num);
			code("\n\t\tJMP \t@test%d", lab_num);
		}
	_RPAREN _LBRACKET case_statements default_statement _RBRACKET
		{
			code("\n\t\tJMP \t@exit%d", lab_num);
			code("\n@test%d:", lab_num);
			
			int i;
			for (i = 0; i < case_count; i++) {
				gen_cmp(switch_id, case_array[i]);
				case_array[i] = -1; 	//ponisti sadrzaj
				code("\n\t\tJEQ \t");
				code("@case%d_%d", lab_num, i);
			}
			
			if ($8)
				code("\n\t\tJMP \t@default%d", lab_num);
			
			code("\n@exit%d:", lab_num);
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
			// provera jedinstvenosti konstanti
			int i = 0;
			while (i < case_count) {
				if($2 == case_array[i]) { //ako takva konstanta vec postoji u nizu
					err("duplicated constant in case");
					break;
				}
				i++;
			}

			if (i == case_count) { //ako nije duplikat
				case_array[case_count] = $2; //ubaci konstantu u niz
				code("\n@case%d_%d:", lab_num, case_count);
				case_count++;
			}
	
			//provera tipa konstante
			if (get_type($2) != get_type(switch_id))
			err("wrong type of constant");
		}
	statement break_statement
	;

break_statement
	: /* empty */
	| _BREAK _SEMICOLON
		{
			code("\n\t\tJMP \t@exit%d", lab_num);
		}
	;

default_statement
	: /* empty */
		{
			$$ = 0;
		}
	| _DEFAULT _COLON
		{
			code("\n@default%d:", lab_num);
		}
	statement
		{
			$$ = 1;
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
			gen_mov($3, idx);
		}
	;

num_exp
	: exp

	| num_exp _AROP exp
		{
			if (get_type($1) != get_type($3))
				err("invalid operands: arithmetic operation");
			
			int t1 = get_type($1);    
			code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
			
			gen_sym_name($1);
			code(",");
			gen_sym_name($3);
			code(",");
			free_if_reg($3);
			free_if_reg($1);
			
			$$ = take_reg();
			gen_sym_name($$);
			set_type($$, t1);
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
		{
			$$ = take_reg();
			gen_mov(FUN_REG, $$);
		}

	| _LPAREN num_exp _RPAREN
		{ 
			$$ = $2; 
		}
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
				err("wrong number of arguments");
			code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
			
			if ($4 > 0)
				code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
			set_type(FUN_REG, get_type(fcall_idx));

			$$ = FUN_REG;
		}
	;

argument
	: /* empty */
		{ $$ = 0; }

	| num_exp
		{ 
			if(get_atr2(fcall_idx) != get_type($1))
				err("incompatible type for argument");
			free_if_reg($1);
			
			code("\n\t\t\tPUSH\t");
			gen_sym_name($1);
			
			$$ = 1;
		}
	;

if_statement
	: if_part %prec ONLY_IF
		{ code("\n@exit%d:", $1); }

	| if_part _ELSE statement
		{ code("\n@exit%d:", $1); }
	;

if_part
	: _IF _LPAREN
		{
			$<i>$ = ++lab_num;
			code("\n@if%d:", lab_num);
		}
	rel_exp
		{
			code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3);
			code("\n@true%d:", $<i>3);
		}
	_RPAREN statement
		{
			code("\n\t\tJMP \t@exit%d", $<i>3);
			code("\n@false%d:", $<i>3);
			$$ = $<i>3;
		}
	;

rel_exp
	: num_exp _RELOP num_exp
		{
			if (get_type($1) != get_type($3))
				err("invalid operands: relational operator");
			$$ = $2 + ((get_type($1) - 1) * RELOP_NUMBER);
			gen_cmp($1, $3);
		}
	;

return_statement
	: _RETURN num_exp _SEMICOLON
		{
			if (get_type(fun_idx) != get_type($2))
				err("incompatible types in return");
			gen_mov($2, FUN_REG);
			code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
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
	output = fopen("output.asm", "w+");

	synerr = yyparse();

	clear_symtab();
	fclose(output);

	if (warning_count)
		printf("\n%d warning(s).\n", warning_count);

	if (error_count) {
		remove("output.asm");
		printf("\n%d error(s).\n", error_count);
	}

	// syntax error
	if (synerr)
		return -1; 
	// semantic errors
	else if (error_count)
		return error_count & 127;
	// warnings
	else if (warning_count)
		return (warning_count & 127) + 127; 
	// OK
	else
		return 0; 
}

