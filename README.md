# SPINE - a (C) programmer's calculator

## BUILDING AND INSTALLATION

Type `make`.  This should build an executable file named `spine` in current
directory.  Building (uses `bison` and `flex`, as well as a C compiler)
doesn't perform anything tricky.

`spine` consists of a single executable, so you can put it anywhere
in your PATH.

I believe this will compile on almost any Unix-like operating system
(linux, Solaris, NetBSD, etc), since I did most of the development
under NetBSD and finished it under Linux.

## UNARY OPERATORS

This constitutes one of the few tricks in the parser/lexer

Consider an expression like "12-9"

If a `lex` lexical analyzer has an integer constant recognizer line like this:
	"[0-9]+    { yylval.val = atoi(yytext); return CONST; }"

lexer returns the sequence of tokens {CONST, '-', CONST}

If the lexer has this:
	"-*[0-9]+    { yylval.val = atoi(yytext); return CONST; }"

lexer returns the sequence of tokens {CONST, CONST} for these cases.

In essence, this is adding the unary-minus-detection to the lexer.

A simple `yacc` grammar would have problems with one of these cases, and if you
put in productions to do both, you'll probably introduce conflicts into some
other part of the grammar.  For bone-headed grammars:

> Expressions: `12- 9;` and `12 - 9;` both work.

> Expressions: `12-9;` `12 -9;` are syntax errors.

## OPERATOR PRECEDENCE

Least binding

1. unary operators: -, +, ~  (unary minus, unary plus, 1's complement)
2. multiplicative:  *, /, %  (multiply, divide, modulo)
3. additive:        +, -
4. bitwise shift:   <<, >>
5. bitwise AND:     &
6. bitwise XOR:     ^
7. bitwise OR:      |

Most binding

Parentheses group expressions "tighter" than operator precedence.

This directory has a grammar taken from the K&R 2nd ed ANSI-C grammar.
It recognizes several unary operators, and does operator precedence
in the productions.  The lexer recognizes '-' and '[0-9]+' as seperate
lexemes and returns them as such.  The grammar doesn't build up a
an explicit parse tree: it does all the operations as semantic
actions of the productions, feeding values calculated back up
the productions until it hits a "stmnt", at which point it prints
out the ultimate value calculated.

## MISCELLANEOUS

`main()` function (and other C functions) resides in the file `gram2.y`.
It seemed acceptable to confuse the issue by putting yacc productions
and C code in the .y file so as to have fewer source files.

Even though `spine` accepts binary (in the "base 2" sense) input values
(7 == 111b) it does not print out in binary - all output done with
printf(), so `spine` has whatever limitations `printf()` has.

You can type in `trace;` and `help;` during `spine` interaction to toggle
evaluation tracing, and see the help-message over and over again.
