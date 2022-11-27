%option noyywrap yylineno
%{
	#include "text.tab.h"
%}

%%

[ \t]+   	{ /* skip */ }

"."         { return _DOT; }
"?"         { return _QUESTION; }
"!"         { return _EXCLAMATION; }

[A-Z][a-z]* { return _CAPITAL_WORD; }
[a-z]+      { return _WORD; }

","         { return _COMMA; }

\n+			{ return _NEWLINE; }

":" 					{ return _COLON; }
HAMLET|OFELIJA|KLAUDIJE	{ return _CHARACTER; }

"("			{ return _LPAREN; }
")"			{ return _RPAREN; }

.           { printf("\nline %d: LEXICAL ERROR on char %c", yylineno, *yytext); }    
