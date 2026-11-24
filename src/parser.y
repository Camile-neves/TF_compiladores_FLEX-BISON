%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
extern FILE *yyin;

int erro_lexico_pendente = 0;
int erros_detectados = 0;
int linha_erro_lexico = 0;

static FILE *out;
static FILE *main_out;
static FILE *function_out;
static FILE *output_file;

static int next_slot = 1;
static int next_label = 0;

typedef struct Var {
    char *name;
    int slot;
    struct Var *next;
} Var;

static Var *variables = NULL;
static Var *saved_variables = NULL;
static int saved_next_slot = 1;

static int get_slot(const char *name) {
    Var *v;

    for (v = variables; v; v = v->next) {
        if (strcmp(v->name, name) == 0)
            return v->slot;
    }

    v = malloc(sizeof(Var));
    v->name = strdup(name);
    v->slot = next_slot++;
    v->next = variables;
    variables = v;

    return v->slot;
}

static int label(void) {
    return next_label++;
}

static void emit_expr(const char *code) {
    if (code)
        fputs(code, out);
}
%}

%define parse.error verbose

%code requires {
    typedef struct LoopInfo {
        int start_label;
        int end_label;
    } LoopInfo;

    typedef struct ForInfo {
        int start_label;
        int end_label;
        int variable_slot;
        int limit_slot;
        int step_slot;
        int negative_label;
        int body_label;
    } ForInfo;
}


%union {
    char *text;
    int number;
    LoopInfo *loop;
    ForInfo *forloop;
}

%token <text> IDENTIFIER NUMBER

%token IF ELSE WHILE FOR IN DEF RETURN IMPORT PRINT
%token AND OR NOT

%token EQ NE LE GE LT GT

%token PLUS MINUS TIMES DIVIDE
%token ASSIGN COLON COMMA LPAREN RPAREN

%token NEWLINE INVALID
%token INIDEBL FIMDEBL

%type <text> expression term factor condition
%type <text> function_head
%type <number> if_head while_start
%type <loop> while_head
%type <forloop> for_head

%left OR
%left AND
%right NOT
%left PLUS MINUS
%left TIMES DIVIDE

%%

program:
    lines
    ;

lines:
      /* vazio */
    | lines NEWLINE
    | lines simple_statement NEWLINE
    | lines if_statement
    | lines while_statement
    | lines for_statement
    | lines function_definition
    | lines error NEWLINE
      {
          yyerrok;
      }
    ;

function_head:
    DEF IDENTIFIER LPAREN RPAREN COLON NEWLINE INIDEBL
    {
        saved_variables = variables;
        saved_next_slot = next_slot;

        variables = NULL;
        next_slot = 1;

        fprintf(function_out,
            ".method public static %s()I\n"
            ".limit stack 100\n"
            ".limit locals 100\n",
            $2
        );

        out = function_out;
        $$ = $2;
    }

    | DEF IDENTIFIER LPAREN IDENTIFIER RPAREN COLON NEWLINE INIDEBL
    {
        saved_variables = variables;
        saved_next_slot = next_slot;

        variables = NULL;
        next_slot = 0;

        get_slot($4);

        fprintf(function_out,
            ".method public static %s(I)I\n"
            ".limit stack 100\n"
            ".limit locals 100\n",
            $2
        );

        out = function_out;

        free($4);
        $$ = $2;
    }

    | DEF IDENTIFIER LPAREN IDENTIFIER COMMA IDENTIFIER RPAREN COLON NEWLINE INIDEBL
    {
        saved_variables = variables;
        saved_next_slot = next_slot;

        variables = NULL;
        next_slot = 0;

        get_slot($4);
        get_slot($6);

        fprintf(function_out,
            ".method public static %s(II)I\n"
            ".limit stack 100\n"
            ".limit locals 100\n",
            $2
        );

        out = function_out;

        free($4);
        free($6);
        $$ = $2;
    }

    | DEF IDENTIFIER LPAREN IDENTIFIER COMMA IDENTIFIER COMMA IDENTIFIER RPAREN COLON NEWLINE INIDEBL
    {
        saved_variables = variables;
        saved_next_slot = next_slot;

        variables = NULL;
        next_slot = 0;

        get_slot($4);
        get_slot($6);
        get_slot($8);

        fprintf(function_out,
            ".method public static %s(III)I\n"
            ".limit stack 100\n"
            ".limit locals 100\n",
            $2
        );

        out = function_out;

        free($4);
        free($6);
        free($8);
        $$ = $2;
    }
    ;

function_definition:
    function_head lines FIMDEBL
    {
        fputs("iconst_0\nireturn\n.end method\n\n", out);

        out = main_out;

        variables = saved_variables;
        next_slot = saved_next_slot;

        free($1);
    }
    ;

simple_statement:
      IDENTIFIER ASSIGN expression
      {
          int s = get_slot($1);

          emit_expr($3);
          fprintf(out, "istore %d\n", s);

          free($1);
          free($3);
      }
    | PRINT LPAREN expression RPAREN
      {
          fputs(
              "getstatic java/lang/System/out Ljava/io/PrintStream;\n",
              out
          );

          emit_expr($3);

          fputs(
              "invokevirtual java/io/PrintStream/println(I)V\n",
              out
          );

          free($3);
      }
    | IDENTIFIER LPAREN RPAREN
      {
          fprintf(out,
              "invokestatic Programa/%s()I\n"
              "pop\n",
              $1
          );

          free($1);
      }

    | IDENTIFIER LPAREN expression RPAREN
      {
          emit_expr($3);

          fprintf(out,
              "invokestatic Programa/%s(I)I\n"
              "pop\n",
              $1
          );

          free($1);
          free($3);
      }

    | RETURN expression
      {
          emit_expr($2);
          fputs("ireturn\n", out);
          free($2);
      }
    ;

if_head:
    IF condition COLON NEWLINE INIDEBL
    {
        $$ = label();

        emit_expr($2);
        fprintf(out, "ifeq L%d\n", $$);

        free($2);
    }
    ;

if_statement:
      if_head lines FIMDEBL
      {
          fprintf(out, "L%d:\n", $1);
      }

    | if_head lines FIMDEBL
      ELSE COLON NEWLINE INIDEBL
      {
          int end_label = label();

          fprintf(out, "goto L%d\n", end_label);
          fprintf(out, "L%d:\n", $1);

          $<number>$ = end_label;
      }
      lines FIMDEBL
      {
          fprintf(out, "L%d:\n", $<number>8);
      }
    ;

while_start:
    WHILE
    {
        $$ = label();
        fprintf(out, "L%d:\n", $$);
    }
    ;

while_head:
    while_start condition COLON NEWLINE INIDEBL
    {
        $$ = malloc(sizeof(LoopInfo));
        $$->start_label = $1;
        $$->end_label = label();

        emit_expr($2);
        fprintf(out, "ifeq L%d\n", $$->end_label);

        free($2);
    }
    ;

while_statement:
    while_head lines FIMDEBL
    {
        fprintf(out, "goto L%d\n", $1->start_label);
        fprintf(out, "L%d:\n", $1->end_label);
        free($1);
    }
    ;

for_head:
    FOR IDENTIFIER IN IDENTIFIER LPAREN expression RPAREN COLON NEWLINE INIDEBL
    {
        if (strcmp($4, "range") != 0) {
            fprintf(stderr, "Erro: o for aceita apenas range().\n");
            free($2);
            free($4);
            free($6);
            YYERROR;
        }

        $$ = malloc(sizeof(ForInfo));
        $$->start_label = label();
        $$->end_label = label();
        $$->variable_slot = get_slot($2);
        $$->limit_slot = next_slot++;
        $$->step_slot = -1;

        emit_expr($6);
        fprintf(out, "istore %d\n", $$->limit_slot);

        fputs("iconst_0\n", out);
        fprintf(out, "istore %d\n", $$->variable_slot);

        fprintf(out, "L%d:\n", $$->start_label);
        fprintf(out, "iload %d\n", $$->variable_slot);
        fprintf(out, "iload %d\n", $$->limit_slot);
        fprintf(out, "if_icmpge L%d\n", $$->end_label);

        free($2);
        free($4);
        free($6);
    }

    | FOR IDENTIFIER IN IDENTIFIER LPAREN expression COMMA expression RPAREN COLON NEWLINE INIDEBL
    {
        if (strcmp($4, "range") != 0) {
            fprintf(stderr, "Erro: o for aceita apenas range().\n");
            free($2);
            free($4);
            free($6);
            free($8);
            YYERROR;
        }

        $$ = malloc(sizeof(ForInfo));
        $$->start_label = label();
        $$->end_label = label();
        $$->variable_slot = get_slot($2);
        $$->limit_slot = next_slot++;
        $$->step_slot = -1;

        emit_expr($6);
        fprintf(out, "istore %d\n", $$->variable_slot);

        emit_expr($8);
        fprintf(out, "istore %d\n", $$->limit_slot);

        fprintf(out, "L%d:\n", $$->start_label);
        fprintf(out, "iload %d\n", $$->variable_slot);
        fprintf(out, "iload %d\n", $$->limit_slot);
        fprintf(out, "if_icmpge L%d\n", $$->end_label);

        free($2);
        free($4);
        free($6);
        free($8);
    }

    | FOR IDENTIFIER IN IDENTIFIER LPAREN expression COMMA expression COMMA expression RPAREN COLON NEWLINE INIDEBL
        {
        if (strcmp($4, "range") != 0) {
            fprintf(stderr, "Erro: o for aceita apenas range().\n");
            free($2);
            free($4);
            free($6);
            free($8);
            free($10);
            YYERROR;
        }

        $$ = malloc(sizeof(ForInfo));

        $$->start_label = label();
        $$->end_label = label();
        $$->negative_label = label();
        $$->body_label = label();

        $$->variable_slot = get_slot($2);
        $$->limit_slot = next_slot++;
        $$->step_slot = next_slot++;

        /* Guarda o valor inicial */
        emit_expr($6);
        fprintf(out, "istore %d\n", $$->variable_slot);

        /* Guarda o limite */
        emit_expr($8);
        fprintf(out, "istore %d\n", $$->limit_slot);

        /* Guarda o passo */
        emit_expr($10);
        fprintf(out, "istore %d\n", $$->step_slot);

        /* 1. Verifica se o passo é zero */
        fprintf(out, "iload %d\n", $$->step_slot);
        fprintf(out, "ifne L%d\n", $$->start_label);

        fputs("getstatic java/lang/System/err Ljava/io/PrintStream;\n", out);
        fputs("ldc \"Erro: range() nao aceita passo zero\"\n", out);
        fputs("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n", out);
        fprintf(out, "goto L%d\n", $$->end_label);

        /* 2. Início do laço */
        fprintf(out, "L%d:\n", $$->start_label);

        /* 3. Verifica se o passo é positivo ou negativo */
        fprintf(out, "iload %d\n", $$->step_slot);
        fprintf(out, "ifle L%d\n", $$->negative_label);

        /* 4. Passo positivo: contador < limite */
        fprintf(out, "iload %d\n", $$->variable_slot);
        fprintf(out, "iload %d\n", $$->limit_slot);
        fprintf(out, "if_icmpge L%d\n", $$->end_label);

        fprintf(out, "goto L%d\n", $$->body_label);

        /* 5. Passo negativo: contador > limite */
        fprintf(out, "L%d:\n", $$->negative_label);
        fprintf(out, "iload %d\n", $$->variable_slot);
        fprintf(out, "iload %d\n", $$->limit_slot);
        fprintf(out, "if_icmple L%d\n", $$->end_label);

        /* 6. Corpo do laço */
        fprintf(out, "L%d:\n", $$->body_label);

        free($2);
        free($4);
        free($6);
        free($8);
        free($10);
    }
    ;

for_statement:
    for_head lines FIMDEBL
    {
        if ($1->step_slot == -1) {
            fprintf(out, "iinc %d 1\n", $1->variable_slot);
        } else {
            fprintf(out, "iload %d\n", $1->variable_slot);
            fprintf(out, "iload %d\n", $1->step_slot);
            fputs("iadd\n", out);
            fprintf(out, "istore %d\n", $1->variable_slot);
        }

        fprintf(out, "goto L%d\n", $1->start_label);
        fprintf(out, "L%d:\n", $1->end_label);

        free($1);
    }
    ;

condition:
      expression LT expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmplt L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | expression GT expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmpgt L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | expression LE expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmple L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | expression GE expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmpge L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | expression EQ expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmpeq L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | expression NE expression
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s%s"
              "if_icmpne L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1, $3,
              true_label, end_label,
              true_label, end_label
          );

          free($1);
          free($3);
      }

    | condition AND condition
      {
          int false_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s"
              "ifeq L%d\n"
              "%s"
              "ifeq L%d\n"
              "iconst_1\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_0\n"
              "L%d:\n",
              $1,
              false_label,
              $3,
              false_label,
              end_label,
              false_label,
              end_label
          );

          free($1);
          free($3);
      }

    | condition OR condition
      {
          int true_label = label();
          int end_label = label();

          asprintf(&$$,
              "%s"
              "ifne L%d\n"
              "%s"
              "ifne L%d\n"
              "iconst_0\n"
              "goto L%d\n"
              "L%d:\n"
              "iconst_1\n"
              "L%d:\n",
              $1,
              true_label,
              $3,
              true_label,
              end_label,
              true_label,
              end_label
          );

          free($1);
          free($3);
      }

    | NOT condition
      {
          asprintf(&$$, "%siconst_1\nixor\n", $2);

          free($2);
      }

    | LPAREN condition RPAREN
      {
          $$ = $2;
      }
    ;

expression:
      expression PLUS term
      {
          asprintf(&$$, "%s%s iadd\n", $1, $3);

          free($1);
          free($3);
      }

    | expression MINUS term
      {
          asprintf(&$$, "%s%s isub\n", $1, $3);

          free($1);
          free($3);
      }

    | term
      {
          $$ = $1;
      }
    ;

term:
      term TIMES factor
      {
          asprintf(&$$, "%s%s imul\n", $1, $3);

          free($1);
          free($3);
      }

    | term DIVIDE factor
      {
          asprintf(&$$, "%s%s idiv\n", $1, $3);

          free($1);
          free($3);
      }

    | factor
      {
          $$ = $1;
      }
    ;

factor:
      NUMBER
      {
          asprintf(&$$, "ldc %s\n", $1);
          free($1);
      }
    | MINUS NUMBER
      {
          asprintf(&$$, "ldc -%s\n", $2);
          free($2);
      }
    
    | IDENTIFIER LPAREN RPAREN
      {
          asprintf(&$$,
              "invokestatic Programa/%s()I\n",
              $1
          );

          free($1);
      }

    | IDENTIFIER LPAREN expression RPAREN
      {
          asprintf(&$$,
              "%sinvokestatic Programa/%s(I)I\n",
              $3,
              $1
          );

          free($1);
          free($3);
      }

    | IDENTIFIER LPAREN expression COMMA expression RPAREN
      {
          asprintf(&$$,
              "%s%sinvokestatic Programa/%s(II)I\n",
              $3,
              $5,
              $1
          );

          free($1);
          free($3);
          free($5);
      }

    | IDENTIFIER
      {
          int s = get_slot($1);

          asprintf(&$$, "iload %d\n", s);
          free($1);
      }
    | IDENTIFIER LPAREN expression COMMA expression COMMA expression RPAREN
      {
          asprintf(&$$,
              "%s%s%sinvokestatic Programa/%s(III)I\n",
              $3,
              $5,
              $7,
              $1
          );

          free($1);
          free($3);
          free($5);
          free($7);
      }

    | LPAREN expression RPAREN
      {
          $$ = $2;
      }
    ;

%%

void yyerror(const char *s) {
    if (erro_lexico_pendente) {
        erro_lexico_pendente = 0;
        return;
    }

    int linha = yylineno;

    if (strstr(s, "unexpected NEWLINE") && linha > 1) {
        linha--;
    }

    fprintf(stderr,
        "Erro sintático na linha %d: %s\n",
        linha, s);

    erros_detectados++;
}

int main(int argc, char **argv) {
    FILE *in = stdin;
    const char *output_name = "Programa.j";

    if (argc > 1) {
        in = fopen(argv[1], "r");

        if (!in) {
            perror("Não foi possível abrir o arquivo de entrada");
            return 1;
        }

        yyin = in;
    }

    if (argc > 2)
        output_name = argv[2];

    output_file = fopen(output_name, "w");

    if (!output_file) {
        perror("Não foi possível criar o arquivo Jasmin");
        return 1;
    }

    main_out = tmpfile();
    function_out = tmpfile();

    if (!main_out || !function_out) {
        perror("Erro ao criar arquivos temporários");
        return 1;
    }

    out = main_out;

    int result = yyparse();

    /* Cabeçalho da classe */
    fputs(
        ".class public Programa\n"
        ".super java/lang/Object\n\n"
        ".method public static main([Ljava/lang/String;)V\n"
        ".limit stack 100\n"
        ".limit locals 100\n",
        output_file
    );

    /* Código do método principal */
    rewind(main_out);

    char buffer[4096];
    size_t bytes;

    while ((bytes = fread(buffer, 1, sizeof(buffer), main_out)) > 0)
        fwrite(buffer, 1, bytes, output_file);

    fputs("return\n.end method\n\n", output_file);

    /* Código das funções */
    rewind(function_out);

    while ((bytes = fread(buffer, 1, sizeof(buffer), function_out)) > 0)
        fwrite(buffer, 1, bytes, output_file);

    fclose(main_out);
    fclose(function_out);
    fclose(output_file);

    if (in != stdin)
        fclose(in);

    if (result == 0 && erros_detectados == 0) {
        printf(
            "Análise concluída. Código Jasmin gerado em: %s\n",
            output_name
        );
    } else {
        fprintf(stderr, "Compilação finalizada com erros.\n");
    }

    return (result != 0 || erros_detectados > 0) ? 1 : 0;
}