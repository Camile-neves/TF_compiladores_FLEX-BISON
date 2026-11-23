# Compilador de uma Linguagem Simplificada Baseada em Python

Projeto acadêmico desenvolvido em C utilizando Flex e Bison para implementar um compilador de uma linguagem simplificada baseada em Python. O compilador realiza análise léxica e sintática e gera código intermediário em Jasmin, que é convertido em bytecode Java pela JVM.

## Tecnologias utilizadas

- **C:** implementação do compilador.
- **Flex:** geração do analisador léxico.
- **Bison:** geração do analisador sintático.
- **Jasmin:** geração de bytecode Java.
- **Java (JVM):** execução dos programas compilados.

## Estrutura do projeto

```text
compilador_python_simples/
├── src/
│   ├── lexer.l
│   ├── parser.y
│   ├── lexer_backup.l
│   ├── parser_backup.y
│   └── teste_lexico.c
├── examples/
│   ├── exemplo.py
│   ├── teste_if.py
│   ├── teste_else.py
│   ├── teste_while.py
│   ├── teste_for.py
│   ├── teste_logico.py
│   └── ...
├── Makefile
└── README.md
```

## Dependências

No Ubuntu, instale as dependências com:

```bash
sudo apt update
sudo apt install build-essential flex bison default-jdk
```

O Jasmin deve estar instalado separadamente e disponível no PATH para utilização pelo comando `jasmin`.

## Compilação do projeto

Na pasta raiz do projeto, execute:

```bash
make
```

Para limpar os arquivos gerados e realizar uma nova compilação:

```bash
make clean
make
```

## Como executar

### 1. Compilar um programa

```bash
./compilador examples/exemplo.py Programa.j
```

O compilador recebe o arquivo de entrada e gera o código Jasmin correspondente.

### 2. Gerar o bytecode Java

```bash
jasmin Programa.j
```

### 3. Executar o programa

```bash
java Programa
```

## Funcionalidades implementadas

### Análise léxica e sintática
- Identificadores e números inteiros;
- reconhecimento de palavras reservadas;
- tratamento de indentação e desindentação para delimitação de blocos;
- análise sintática por meio de gramática definida em Bison.

### Variáveis e expressões
- Atribuição de variáveis;
- operações aritméticas: adição, subtração, multiplicação e divisão;
- utilização de parênteses;
- respeito à precedência dos operadores;
- impressão de expressões inteiras com `print()`.

### Estruturas condicionais
- `if`;
- `else`;
- operadores relacionais: `<`, `>`, `<=`, `>=`, `==` e `!=`;
- operadores lógicos: `and`, `or` e `not`.

### Estruturas de repetição
- `while`;
- `for`;
- função `range()` com um, dois ou três argumentos;
- suporte a intervalos crescentes e decrescentes;
- suporte a diferentes valores de passo;
- tratamento de passo zero em `range()`.

### Funções
- Declaração de funções com `def`;
- funções sem parâmetros;
- funções com um, dois ou três parâmetros inteiros;
- chamadas de funções;
- chamadas de funções dentro de expressões;
- chamadas encadeadas;
- retorno de valores inteiros com `return`.

## Exemplos de testes

A pasta `examples/` contém programas utilizados para validar as funcionalidades do compilador, incluindo:

- Operações aritméticas e precedência;
- estruturas condicionais;
- estruturas de repetição;
- operadores lógicos;
- diferentes formas de utilização de `range()`;
- funções com diferentes quantidades de parâmetros;
- chamadas encadeadas de funções;
- estruturas condicionais e de repetição dentro de funções.

## Limitações

O projeto implementa um subconjunto simplificado da linguagem Python. Portanto, não possui compatibilidade completa com a linguagem original.

Entre as limitações estão:

- Tratamento de valores inteiros;
- funções limitadas a três parâmetros;
- ausência de suporte à importação de módulos (`import`);
- ausência de implementação de diversos recursos da linguagem Python original.

A implementação foi desenvolvida de forma incremental, com testes individuais para verificar o funcionamento dos recursos implementados.