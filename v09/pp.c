// inkrement - ručno moraš
if(get_type(i) == INT)
    code("\n\t\tADDS\t");
else
    code("\n\t\tADDU\t");
gen_sym_name(i);
code(",$1,");
gen_sym_name(i);

// labelu koristi uvek
$<i>$ = ++lab_num;

// opp_jumps se generiše u odnosu na rel_exp
rel_exp _SEMICOLON;
{
code("\n\t\t%s\t@exit%d", opp_jumps[$1], lab_num);
}

// i ovo će ti možda trebati
// u case_array se postavljaju svi literali koji su u switch-u
// za svaki case_statement se proverava da li je novi literal već u tom nizu
// (a to ne sme da se desi jer konstante trebaju da budu jedinstvene)
int case_count = 0;
int case_array[100];
// switch_id se dobija kao lookup_symbol, i može se iskoristiti za get_type()
int switch_id = -1;

// možeš definisati novi tip pojma
%type <i> default_statement

// skokove za literale i za ID moraš ovako
int i = lookup_symbol(_ID, VAR|PAR);
gen_cmp(i, literal);
if(get_type(i) == INT)
	code("\n\t\tJGTS \t");
else
	code("\n\t\tJGTU \t");
code("@labela_end%d", lab_num);

// za literale - samo $, za ID ide lookup_symbol kod gen_sym_name
gen_sym_name(lookup_symbol($2, VAR|PAR));
gen_sym_name($4);

// za poređenje važi isto
gen_cmp(lookup_symbol($2, VAR|PAR), $4);

