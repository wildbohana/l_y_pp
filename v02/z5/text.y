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

	int lista = 0;
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

%token _NUMBER

%%


start
	: text_prefix text
	;

text_prefix
	: list		{ lista++; }
	|
	;

list
	: _NUMBER _DOT sentence
	| list _NUMBER _DOT sentence
	;

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

	printf("\nParagrafi: %d", paragrafi);

	printf("\nListe: %d", lista);

	printf("\n");
}

int yyerror(char *s) {
	fprintf(stderr, "line %d: SYNTAX ERROR %s\n", yylineno, s);
} 
