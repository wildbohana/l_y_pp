/* Sekcije: definicije, pravila, proizvoljan C kod */
/* %% sluzi da razdvoji 3 sekcije programa */

%option noyywrap

%%

[+-]?[0-9]+F { printf("%dC", ((atoi(yytext) - 32) * 5/9 )); }

%%

int main() {
	yylex();
}
