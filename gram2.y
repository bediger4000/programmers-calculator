%{
#include <stdio.h>  /* fprintf(), printf() */
#include <unistd.h> /* getopt() */
#include <stdlib.h> /* exit() */

char *default_format = "0x%08x";
char *fmt = NULL;
int   trace = 0;

static char rcsident[] = "$Id: gram2.y,v 1.2 2003/04/08 14:34:26 bediger Exp bediger $";

char outbuf[256];

extern char *optarg;
void help(int exitcode);
int yyerror(char *s1);
extern int yylex(void);

%}

%union {
	char op;
	unsigned int  val;
}

%token <val>CONST
%token TK_LPAREN TK_RPAREN 
%token TK_PLUS TK_MINUS TK_TIMES TK_DIV TK_COMP TK_MOD
%token TK_LEFT_SHIFT TK_RIGHT_SHIFT
%token TK_BIT_AND TK_BIT_OR TK_BIT_XOR
%token TK_TRACE TK_HELP TK_SEMI

%type <val> OR_expression AND_expression XOR_expression
%type <val> value multiplicative_expr  additive_expr 
%type <val> shift_expression
%type <op>  unary_operator

%%

program: stmnt TK_SEMI program 
	|
	;

stmnt
	: OR_expression { snprintf(outbuf, sizeof(outbuf), fmt, $1); printf("%s\n", outbuf); }
	| TK_TRACE		{ trace = !trace;  /* toggle the "trace" output */ fprintf(stderr, "Evaluation trace now %s\n", trace?"on":"off"); }
	| TK_HELP		{ help(0); }
	;

unary_operator
	: TK_PLUS     {$$ = '+';}
	| TK_MINUS    {$$ = '-'; /* even though every value carried around in unsigned int variables */ }
	| TK_COMP     {$$ = '~';}
	;
OR_expression
	:                         XOR_expression { $$ = $1         ;}
	| OR_expression TK_BIT_OR XOR_expression { $$ = $1 | $3; if (trace) printf("%08x = %08x |  %08x\n",$$, $1, $3);}
	;

XOR_expression
	:                           AND_expression  { $$ = $1         ;}
	| XOR_expression TK_BIT_XOR AND_expression  { $$ = $1 ^ $3; if (trace) printf("%08x = %08x ^  %08x\n",$$, $1, $3);}
	;

AND_expression
	:                           shift_expression  { $$ = $1         ;}
	| AND_expression TK_BIT_AND shift_expression  { $$ = $1 & $3;if (trace) printf("%08x = %08x &  %08x\n",$$, $1, $3);}
	;

shift_expression
	:                                 additive_expr { $$ = $1          ; }
	| shift_expression TK_LEFT_SHIFT  additive_expr { $$ = $1 << $3; if (trace) printf("%08x = %08x << %08x\n",$$, $1, $3);}
	| shift_expression TK_RIGHT_SHIFT additive_expr { $$ = $1 >> $3; if (trace) printf("%08x = %08x >> %08x\n",$$, $1, $3);}
	;

additive_expr
	:                        multiplicative_expr  { $$ = $1         ; }
	| additive_expr TK_PLUS  multiplicative_expr  { $$ = $1 + $3; if (trace) printf("%08x = %08x +  %08x\n",$$, $1, $3);}
	| additive_expr TK_MINUS multiplicative_expr  { $$ = $1 - $3; if (trace) printf("%08x = %08x -  %08x\n",$$, $1, $3);}
	;

multiplicative_expr
	:                              value  { $$ = $1         ; }
	| multiplicative_expr TK_TIMES value  { $$ = $1 * $3; if (trace) printf("%08x = %08x *  %08x\n",$$, $1, $3);}
	| multiplicative_expr TK_DIV   value  { $$ = $1 / $3; if (trace) printf("%08x = %08x /  %08x\n",$$, $1, $3);}
	| multiplicative_expr TK_MOD   value  { $$ = $1 % $3; if (trace) printf("%08x = %08x %  %08x\n",$$, $1, $3);}
	;

value
	: CONST                              { $$ = $1; }
	| unary_operator value {
			switch ($1)
			{
			case '+': $$ = $2;     if (trace) printf("%08x = +%08x\n", $$, $2); break;
			case '-': $$ = 0 - $2; if (trace) printf("%08x = -%08x\n", $$, $2); break;
			case '~': $$ = ~($2);  if (trace) printf("%08x = ~%08x\n", $$, $2); break;
			default:
				fprintf(stderr, "value -> unary_operator value: bad unary operator '%c' (%d)\n",
					$1, $1);
			}
		}
/* this production constitutes the only really tricky part: it has to say
 * value -> '(' lowest-precedence-level-operator_expression ')'
 */
	| TK_LPAREN OR_expression TK_RPAREN  { $$ = $2; }
	;

%%

void
usage(int exitcode)
{
	fprintf(stderr,
		"spine: programmer's calculator\n"
		"Performs arithmetic and bitwise operations on unsigned integer\n"
		"values with C order of operation precedence.\n"
		"Usage: spine [-f printf-format] [-t] [-x] [-X] [-h]\n"
		"Flags:\n"
		"     -f printf-format    specify output format (default \"%s\"\n"
		"     -t                  trace evaluation of expressions, printing intermediate results\n"
		"     -x -X               print this message, then exit with 1 status\n"
		"     -h                  print short help message, then exit with 1 status\n"
		"Version %s\n",
		default_format,
		rcsident
	);
	exit(exitcode);
}

void
help(int exitcode)
{
	fprintf(stderr,
		"Spine help\n"
		"Reads arithmetic expressions from stdin, prints calculated results on stdout\n"
		"Arithmetic expressions end with ';' (semicolon) NOT end-of-line, to allow\n"
		"complicated expressions to extend over 1 line in length.\n\n"
		"Calculates in unsigned int variables, so the output does depend on what\n"
		"hardware executes spine.\n\n"
		"Operation precedence:\nLeast\n"
		"unary operators: -, +, ~  (unary minus, unary plus, 1's complement)\n"
		"multiplicative:  *, /, %  (multiply, divide, modulo)\n"
		"additive:        +, -\n"
		"bitwise shift:   <<, >>\n"
		"bitwise AND:     &\n"
		"bitwise XOR:     ^\n"
		"bitwise OR:      |\nMost\n\n"
		"Parentheses group factors over and above operator precedence\n\n"
		"Numeric values in input may appear as octal (0377), decimal (234),\n"
		"or hexadecimal (0x7fab)\n\n"
		"Spine seems most useful in determining what a complicated C-language\n"
		"arithmetic expression actually does, since spine follows C operator\n"
		"precedence, and has operators like left and right bitwise shifts\n"
		"that don't appear in many other calculators.\n\n"
		"Try esoteric arithmetic expressions with \"-t\" option or issue \"trace;\"\n"
		"command during interaction with spine for added clarity,\n"
	);
	if (exitcode) exit(exitcode);
}

int
main(int ac, char **av)
{
	int flag;

	while (-1 != (flag = getopt(ac, av, "f:txXh")))
	{
		switch (flag)
		{
		case 'f':  fmt = optarg; break;
		case 't':  trace = 1;    break;
		case 'x':
		case 'X':  usage(1);     break;
		case 'h':  help(1);     break;
		}
	}

	if (!fmt) fmt = default_format;

	return yyparse();
}

int
yywrap()
{
	return 1;
}

int
yyerror(char *s1)
{
	extern int lineno;

	fprintf(stderr, "line %d, %s\n", lineno, s1);

	return 0;
}
