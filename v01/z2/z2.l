/* Sekcije: definicije, pravila, proizvoljan C kod */
/* %% sluzi da razdvoji 3 sekcije programa */

%option noyywrap

%%

"//".*

%%

int main() {
	yylex();
}
