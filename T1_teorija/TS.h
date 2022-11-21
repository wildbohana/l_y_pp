// defs.h 

#define SYMBOL_TYPE_LENGTH 64

enum types { NO_TYPE, INT, UINT };
enum kinds { NO_KIND = 0x1, REG = 0x2, LIT = 0x4, FUN = 0x8, VAR = 0x10, PAR = 0x20 };
enum arops { ADD, SUB, MUL, DIV, AROP_NUMBER };
enum relops { LT, GT, LE, GE, EQ, NE, RELOP_NUMBER };

#define err(args...) sprintf(char_buffer, args), \ yyerror(char_buffer)
#define warn(args...) sprintf(char_buffer, args), \ warning(char_buffer)

// symtab.h

// Element tabele simbola
typedef struct sym_entry {
	char *   name; 		// ime simbola
	unsigned kind; 		// vrsta simbola
	unsigned type; 		// tip vrednosti simbola
	unsigned atr1; 		// dodatni attribut simbola
	unsigned atr2; 		// dodatni attribut simbola
} SYMBOL_ENTRY;

SYMBOL_ENTRY symbol_table[SYMBOL_TABLE_LENGTH];
int first_empty = 0;

// Vraca indeks prvog sledeceg praznog elementa ili gresku ako prekoracimo
int get_next_empty_element(void);

// Vraca indeks poslednjeg zauzetog elementa.
int get_last_element(void);

// Ubacuje novi simbol (jedan red u tabeli) i vraca indeks ubacenog 
// elementa u TS ili -1 u slucaju da nema slobodnog elementa u tabeli
int insert_symbol(char *name, unsigned kind, unsigned type, unsigned atr1, unsigned atr2);

// Ubacuje konstantu u tabelu simbola (ako vec ne postoji)
int insert_literal(char *str, unsigned type);

// Vraca indeks pronadjenog simbola ili vraca -1
int lookup_symbol(char *name, unsigned kind);

// set i get metode za polja tabele simbola
void set_name(int index, char *name);
char* get_name(int index);

void set_kind(int index, unsigned kind);
unsigned get_kind(int index);

void set_type(int index, unsigned type);
unsigned get_type(int index);

void set_atr1(int index, unsigned atr1);
unsigned get_atr1(int index);

void set_atr2(int index, unsigned atr2);
unsigned get_atr2(int index);

// Inicijalizacija tabele simbola, koristi se pre parsiranja
void init_symtab(void);
// Brise sve elemente tabele simbola, korisiti se posle parsiranja
void clear_symtab(void);

// Brise elemente tabele od zadatog indeksa, koristi se kad se zavrsi parsiranje funkcije
void clear_symbols(unsigned begin_index);
// Ispisuje sve elemente tabele simbola
void print_symtab(void);



// semantic.y
/* SNIPPETI KOJI MOŽDA DOĐU */

// Svi lokalni identifikatori iste funkcije moraju biti međusobno različiti
variable
	: _TYPE _ID _SEMICOLON
		{
			if (lookup_symbol($2, VAR|PAR) == NO_INDEX)
				insert_symbol($2, VAR, $1, ++var_num, NO_ATR);
			else
				err("redefinition of '%s'", $2);
		}
	;

// Svi globalni identifikatori moraju biti međusobno različiti
// Opseg vidljivosti lokalnih id-a je od definicije do kraja funkcije u kojoj su definisani
function
	: _TYPE _ID
		{
			fun_idx = lookup_symbol($2, FUN);
			if (fun_idx == NO_INDEX)
				fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
			else
				err("redefinition of function '%s'", $2);
		}
	_LPAREN parameter _RPAREN body
		{
			clear_symbols(fun_idx + 1);
			var_num = 0;
		}
	;

parameter
	: /* empty */
		{ set_atr1(fun_idx, 0); }
	| _TYPE _ID
		{
			insert_symbol($2, PAR, $1, 1, NO_ATR);
			set_atr1(fun_idx, 1);
			set_atr2(fun_idx, $1);
		}
	;
