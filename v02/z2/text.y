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

%token _CAPITAL_WORD
%token _WORD

%token _DOT
%token _QUESTION
%token _EXCLAMATION

%token _COMMA

%%

text 
	: sentence
	| text sentence
	;

sentence 
	: words end
	;

end
	: _DOT			{ izjavne++; }
	| _QUESTION		{ upitne++; }
	| _EXCLAMATION	{ uzvicne++; }
	;

words
	: _CAPITAL_WORD
	| words comma _WORD
	| words comma _CAPITAL_WORD
	;

comma 
	:
	| _COMMA
	;

%%

int main() {
	yyparse();

	printf("\nObavestajne: %d", izjavne);
	printf("\nUpitne: %d", upitne);
	printf("\nUzvicne: %d", uzvicne);

	printf("\n");
}

int yyerror(char *s) {
	fprintf(stderr, "line %d: SYNTAX ERROR %s\n", yylineno, s);
} 
