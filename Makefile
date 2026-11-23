CC=gcc
FLEX=flex
BISON=bison

all: compilador

compilador: parser.tab.c lex.yy.c
	$(CC) -o compilador parser.tab.c lex.yy.c -lfl

parser.tab.c parser.tab.h: src/parser.y
	$(BISON) -d -o parser.tab.c src/parser.y

lex.yy.c: src/lexer.l parser.tab.h
	$(FLEX) -o lex.yy.c src/lexer.l

clean:
	rm -f compilador parser.tab.c parser.tab.h lex.yy.c Programa.j Programa.class

.PHONY: all clean
