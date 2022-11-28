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

	int paragrafi = 0;

	int drama = 0;
%}

%token _CAPITAL_WORD
%token _WORD

%token _DOT
%token _QUESTION
%token _EXCLAMATION

%token _COMMA

%token _NEWLINE

%token _COLON
%token _CHARACTER

%token _LPAREN
%token _RPAREN

%%

text 
	: paragraph _NEWLINE		{ paragrafi++; }
	| text paragraph _NEWLINE	{ paragrafi++; }
	;
          
paragraph
	: sentence
	| paragraph sentence
	;

sentence 
	: words end
	| character sentence		{ drama++; }
	| words character sentence	{ drama++; }
	;

end
	: _DOT			{ izjavne++; }
	| _QUESTION		{ upitne++; }
	| _EXCLAMATION	{ uzvicne++; }
	;

character
	: _CHARACTER _COLON
	;

words
	: left_prefix _CAPITAL_WORD right_postfix
	| words left_prefix _WORD right_postfix
	| words left_prefix _CAPITAL_WORD right_postfix	
	| words _LPAREN _RPAREN
	;

left_prefix
	: _LPAREN
	|
	;

right_postfix
	: _RPAREN
	|
	;

%%

int main() {
	yyparse();

	printf("\nObavestajne: %d", izjavne);
	printf("\nUpitne: %d", upitne);
	printf("\nUzvicne: %d", uzvicne);

	printf("\nZarezi: %d", zarez);

	printf("\nParagrafi: %d", paragrafi);

	printf("\n");
}

int yyerror(char *s) {
	fprintf(stderr, "line %d: SYNTAX ERROR %s\n", yylineno, s);
} 
