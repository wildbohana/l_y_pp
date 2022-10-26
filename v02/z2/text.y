%{
	#include <stdio.h>
	int yylex(void);
	int yyparse(void);
	int yyerror(char *);
	extern int yylineno;

	int izjavne = 0;
	int upitne = 0;
	int uzvicne = 0;

	int zarez = 0;
%}

%token _DOT
%token _QUESTION
%token _EXCLAMATION
%token _CAPITAL_WORD
%token _WORD
%token _COMMA

%%

text 
	: sentence
	| text sentence
	;
          
sentence 
	: words _DOT			{ izjavne++; }
	| words _QUESTION		{ upitne++; }
	| words _EXCLAMATION	{ uzvicne++; }
	;

words 
	: _CAPITAL_WORD
	| words _WORD
	| words _CAPITAL_WORD    
	| words _COMMA _WORD			{ zarez++; }
	| words _COMMA _CAPITAL_WORD	{ zarez++; }
	;

%%

int main() {
	yyparse();

	printf("\nObavestajne: %d", izjavne);
	printf("\nUpitne: %d", upitne);
	printf("\nUzvicne: %d", uzvicne);

	printf("\nZarezi: %d", zarez);
	
	printf("\n");
}

int yyerror(char *s) {
	fprintf(stderr, "line %d: SYNTAX ERROR %s\n", yylineno, s);
} 
