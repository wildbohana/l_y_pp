/* Sekcije: definicije, pravila, proizvoljan C kod */
/* %% sluzi da razdvoji 3 sekcije programa */

%option noyywrap

%%

0|[+-]?[1-9][0-9]* 		{ printf("broj: %s\n", yytext); }
0[xX][0-9a-fA-F]{1,4} 	{ printf("heksa broj: %s\n", yytext); }
[+-]?[0-9]+\.[0-9]* 	{ printf("realni broj: %s\n", yytext); }
(?i:break)			 	{ printf("kljucna rec: %s\n", yytext); }

%%

int main() {
	yylex();
}
