CC = cc
CFLAGS = -g -Wall
YFLAGS = -v -d
LEX = flex
YACC = yacc
GRAM = gram2

OFILES = lex.yy.o y.tab.o

SRC = gram.y lex.l makefile

spine: $(OFILES)
	$(CC) $(CFLAGS) -o spine  $(OFILES)

tar:
	cd ..; tar cvf spine.tar spine/gram2.y spine/lex.l spine/makefile spine/README

y.tab.o: y.tab.c y.tab.h
	$(CC) -g -c y.tab.c

lex.yy.o: lex.yy.c y.tab.h

lex.yy.c: lex.l
	$(LEX) lex.l

y.tab.h y.tab.c: $(GRAM).y
	$(YACC) $(YFLAGS) $(GRAM).y

clean:
	-rm *core spine y.* lex.yy.c *.o
