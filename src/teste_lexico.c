#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"
YYSTYPE yylval;

extern FILE *yyin;
extern YYSTYPE yylval;

int yylex(void);

int main(int argc, char *argv[]) {

    if (argc < 2) {
        printf("Uso: ./teste_lexico arquivo.py\n");
        return 1;
    }

    yyin = fopen(argv[1], "r");

    if (!yyin) {
        perror("Erro ao abrir arquivo");
        return 1;
    }

    int token;

    printf("\n===== ANALISE LEXICA =====\n\n");

    while ((token = yylex()) != 0) {

        switch (token) {

            case IDENTIFIER:
                printf("IDENTIFIER: %s\n", yylval.text);
                free(yylval.text);
                break;

            case NUMBER:
                printf("NUMBER: %s\n", yylval.text);
                free(yylval.text);
                break;

            case IF: printf("IF\n"); break;
            case ELSE: printf("ELSE\n"); break;
            case WHILE: printf("WHILE\n"); break;
            case FOR: printf("FOR\n"); break;
            case IN: printf("IN\n"); break;
            case DEF: printf("DEF\n"); break;
            case RETURN: printf("RETURN\n"); break;
            case IMPORT: printf("IMPORT\n"); break;
            case PRINT: printf("PRINT\n"); break;

            case PLUS: printf("PLUS\n"); break;
            case MINUS: printf("MINUS\n"); break;
            case TIMES: printf("TIMES\n"); break;
            case DIVIDE: printf("DIVIDE\n"); break;

            case EQ: printf("EQ\n"); break;
            case NE: printf("NE\n"); break;
            case LT: printf("LT\n"); break;
            case GT: printf("GT\n"); break;
            case LE: printf("LE\n"); break;
            case GE: printf("GE\n"); break;

            case ASSIGN: printf("ASSIGN\n"); break;
            case COLON: printf("COLON\n"); break;
            case COMMA: printf("COMMA\n"); break;
            case LPAREN: printf("LPAREN\n"); break;
            case RPAREN: printf("RPAREN\n"); break;

            case NEWLINE: printf("NEWLINE\n"); break;
            case INIDEBL: printf("INIDEBL\n"); break;
            case FIMDEBL: printf("FIMDEBL\n"); break;
            case INVALID: printf("INVALID\n"); break;

            default:
                printf("TOKEN DESCONHECIDO: %d\n", token);
        }
    }

    printf("\n===== FIM DA ANALISE =====\n");

    fclose(yyin);

    return 0;
}
