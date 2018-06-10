%{
#include <stdlib.h>
#include <limits.h>

#include "y.tab.h"

int lineno = 1;
%}

%%

[ \t]	{ /* ignore whitespace */ }
"0x"[0-9A-Fa-f]+ {
		yylval.val = strtoul(yytext, NULL, 0x10);
		return CONST;
	}
"0"[0-7]+ {
		yylval.val = strtoul(yytext, NULL, 010);
		return CONST;
	}
[0-9]+	{  yylval.val = strtoul(yytext, NULL, 10); return CONST; }
[01]+"b" { yylval.val = strtoul(yytext, NULL, 2);  return CONST;  /* this seems crappy - trust strtoul() to ingnore the trailing 'b' */ }
\+		{ return TK_PLUS; }
\-		{ return TK_MINUS; }
\*		{ return TK_TIMES; }
\/		{ return TK_DIV; }
\~		{ return TK_COMP; }
\%		{ return TK_MOD; }
\(		{ return TK_LPAREN; }
\)		{ return TK_RPAREN; }
">>"	{ return TK_RIGHT_SHIFT; /* may sign-extend on some architectures? */ }
"<<"	{ return TK_LEFT_SHIFT; }
"&"		{ return TK_BIT_AND; }
"|"		{ return TK_BIT_OR; }
"^"		{ return TK_BIT_XOR; }
\n		{ ++lineno; }
"trace"	{ return TK_TRACE; }
"help"	{ return TK_HELP; }
\;		{ return TK_SEMI; }
.		{ /* Just eat it up */ }
