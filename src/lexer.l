%{
#include "parser.tab.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
extern int erro_lexico_pendente;
extern int erros_detectados;
extern int linha_erro_lexico;

static int indent_stack[256] = {0};
static int indent_top = 0;
static int pending_dedents = 0;
static int eof_newline_emitted = 0;

static int yylex_raw(void);
#define YY_DECL static int yylex_raw(void)
%}

%option noyywrap yylineno

%x NORMAL

DIGITO      [0-9]
LETRA       [a-zA-Z_]
ID          {LETRA}({LETRA}|{DIGITO})*
NUM         {DIGITO}+(\.{DIGITO}+)?

%%

 /* ==================================================
   CONTROLE DE INDENTACAO
   ================================================== */

 /* Linha contendo somente espaços ou comentários */
<INITIAL>^[ \t]*#[^\r\n]* {
    /* Ignora linhas de comentários */
}

<INITIAL>^[ \t]*\r?\n {
    /* Ignora linhas vazias */
}

 /* Identifica o início de uma linha com código */
<INITIAL>^[ \t]*[^ \t\r\n#] {

    int width = 0;
    int i;
    int spaces = 0;
    int tabs = 0;
    int dedents = 0;

    /* Calcula o nível de indentação */
    for (i = 0; i < yyleng - 1; i++) {

        if (yytext[i] == ' ') {
            width++;
            spaces++;
        }
        else if (yytext[i] == '\t') {
            width = ((width / 8) + 1) * 8;
            tabs++;
        }
    }

    /* Devolve o primeiro caractere de código */
    unput(yytext[yyleng - 1]);

    BEGIN(NORMAL);

    /* Verifica indentação */
    if (width > indent_stack[indent_top]) {

        if (indent_top >= 255) {
            fprintf(stderr,
                "Erro: limite de indentação excedido.\n");

            erro_lexico_pendente = 1;
            erros_detectados++;
            linha_erro_lexico = yylineno;
            return INVALID;
        }

        indent_stack[++indent_top] = width;

        return INIDEBL;
    }

    /* Verifica recuo */
    if (width < indent_stack[indent_top]) {

        while (indent_top > 0 &&
               indent_stack[indent_top] > width) {

            indent_top--;
            dedents++;
        }

        /* O recuo precisa corresponder a um nível anterior */
        if (indent_stack[indent_top] != width) {

            fprintf(stderr,
                "Erro de indentação na linha %d.\n",
                yylineno);

            erro_lexico_pendente = 1;
            erros_detectados++;
            linha_erro_lexico = yylineno;
            return INVALID;
        }

        if (dedents > 0) {
            pending_dedents = dedents - 1;
            return FIMDEBL;
        }
    }
}

 /* Espaços no início de arquivo sem código */
<INITIAL>[ \t]+ {
    /* Ignora espaços finais */
}

 /* ==================================================
   PALAVRAS RESERVADAS
   ================================================== */

<NORMAL>"if"       { return IF; }
<NORMAL>"else"     { return ELSE; }
<NORMAL>"while"    { return WHILE; }
<NORMAL>"for"      { return FOR; }
<NORMAL>"in"       { return IN; }
<NORMAL>"def"      { return DEF; }
<NORMAL>"return"   { return RETURN; }
<NORMAL>"import"   { return IMPORT; }
<NORMAL>"print"    { return PRINT; }
<NORMAL>"and"      { return AND; }
<NORMAL>"or"       { return OR; }
<NORMAL>"not"      { return NOT; }

 /* ==================================================
   OPERADORES RELACIONAIS
   ================================================== */

<NORMAL>"=="       { return EQ; }
<NORMAL>"!="       { return NE; }
<NORMAL>"<="       { return LE; }
<NORMAL>">="       { return GE; }
<NORMAL>"<"        { return LT; }
<NORMAL>">"        { return GT; }

 /* ==================================================
   OPERADORES ARITMETICOS
   ================================================== */

<NORMAL>"+"        { return PLUS; }
<NORMAL>"-"        { return MINUS; }
<NORMAL>"*"        { return TIMES; }
<NORMAL>"/"        { return DIVIDE; }

 /* ==================================================
   OUTROS SIMBOLOS
   ================================================== */

<NORMAL>"="        { return ASSIGN; }
<NORMAL>":"        { return COLON; }
<NORMAL>","        { return COMMA; }
<NORMAL>"("        { return LPAREN; }
<NORMAL>")"        { return RPAREN; }

 /* ==================================================
   NUMEROS E IDENTIFICADORES
   ================================================== */

<NORMAL>{NUM} {
    yylval.text = strdup(yytext);
    return NUMBER;
}

<NORMAL>{ID} {
    yylval.text = strdup(yytext);
    return IDENTIFIER;
}

 /* ==================================================
   ESPACOS E COMENTARIOS
   ================================================== */

<NORMAL>[ \t]+ {
    /* Ignora espaços entre tokens */
}

<NORMAL>\#[^\r\n]* {
    /* Ignora comentários */
}

 /* ==================================================
   QUEBRA DE LINHA
   ================================================== */

<NORMAL>\r?\n {
    BEGIN(INITIAL);
    return NEWLINE;
}

 /* ==================================================
   CARACTERES INVALIDOS
   ================================================== */

<NORMAL>. {
    fprintf(stderr,
        "Erro léxico na linha %d: caractere '%s' inválido.\n",
        yylineno, yytext);

    erro_lexico_pendente = 1;
    erros_detectados++;
    linha_erro_lexico = yylineno;
    return INVALID;
}

 /* ==================================================
   FINAL DO ARQUIVO
   ================================================== */

<NORMAL><<EOF>> {

    BEGIN(INITIAL);

    if (!eof_newline_emitted) {
        eof_newline_emitted = 1;
        return NEWLINE;
    }

    return 0;
}

<INITIAL><<EOF>> {

    if (indent_top > 0) {
        indent_top--;
        return FIMDEBL;
    }

    return 0;
}

%%

 /* Função pública utilizada pelo Bison */
int yylex(void) {

    if (pending_dedents > 0) {
        pending_dedents--;
        return FIMDEBL;
    }

    return yylex_raw();
}
