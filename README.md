# Compilador de uma Linguagem Simplificada Baseada em Python

Projeto acadêmico desenvolvido em C utilizando Flex e Bison para implementar um compilador de uma linguagem simplificada baseada em Python.

O compilador realiza análise léxica e sintática dos programas de entrada e gera código Jasmin, que é convertido em bytecode Java e executado pela JVM.

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
│   └── parser.y
├── examples/
│   ├── entrega_atribuicao.py
│   ├── entrega_else.py
│   ├── entrega_for.py
│   ├── entrega_funcao.py
│   ├── entrega_funcao_parametros.py
│   ├── entrega_if_else.py
│   ├── entrega_operadores.py
│   └── entrega_while.py
├── Makefile
├── README.md
├── exemplos.txt
├── testar_todos.sh
└── .gitignore
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
./compilador examples/entrega_atribuicao.py Programa.j
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

- Reconhecimento de identificadores e números;
- Reconhecimento de palavras reservadas;
- Reconhecimento de operadores aritméticos e relacionais;
- Controle de indentação e desindentação para delimitação de blocos;
- Análise sintática utilizando Bison;
- Identificação de erros léxicos e sintáticos.

### Variáveis e expressões

- Atribuição de variáveis;
- Operações aritméticas: adição, subtração, multiplicação e divisão;
- Utilização de parênteses;
- Respeito à precedência dos operadores;
- Impressão de expressões inteiras com `print()`.

### Estruturas condicionais

- `if`;
- `else`;
- Operadores relacionais: `<`, `>`, `<=`, `>=`, `==` e `!=`;
- Operadores lógicos: `and`, `or` e `not`.

### Estruturas de repetição

- `while`;
- `for` utilizando a função `range()`;
- `range()` com um, dois ou três argumentos;
- Suporte a intervalos crescentes e decrescentes;
- Suporte a diferentes valores de passo;
- Tratamento de passo zero em `range()`.

### Funções

- Declaração de funções com `def`;
- Funções sem parâmetros;
- Funções com um, dois ou três parâmetros inteiros;
- Chamadas de funções;
- Chamadas de funções dentro de expressões;
- Chamadas encadeadas;
- Retorno de valores inteiros com `return`.

## Relação com a gramática proposta

O projeto foi desenvolvido considerando uma gramática simplificada de Python fornecida para a atividade.

As principais construções previstas na gramática foram implementadas, incluindo atribuições, expressões aritméticas, estruturas condicionais, estruturas de repetição, funções, parâmetros, retorno de valores, operadores relacionais e controle de indentação.

Existem, entretanto, algumas diferenças entre a gramática apresentada e a implementação:

- **Comando `for`:** a gramática apresenta `for identificador in expressão`, enquanto a implementação atual aceita exclusivamente a utilização de `range()`.
- **Comando `import`:** o compilador aceita sintaticamente declarações no formato `import nome_modulo`. Entretanto, o carregamento e a utilização efetiva das bibliotecas importadas ainda não estão implementados.
- **Recursos adicionais:** o compilador também implementa `print()`, chamadas de funções e operadores lógicos, que não estão explicitamente descritos na gramática fornecida.

O arquivo `exemplos.txt` reúne trechos de código que demonstram as construções da linguagem e os recursos adicionais implementados.

## Exemplos e testes

A pasta `examples/` contém oito programas preparados para demonstrar as principais funcionalidades do compilador:

- `entrega_atribuicao.py`: atribuição de variáveis e expressões aritméticas;
- `entrega_else.py`: estrutura condicional `else`;
- `entrega_for.py`: estrutura de repetição `for`;
- `entrega_funcao.py`: declaração e chamada de funções;
- `entrega_funcao_parametros.py`: funções com parâmetros;
- `entrega_if_else.py`: estruturas condicionais `if/else`;
- `entrega_operadores.py`: utilização de operadores;
- `entrega_while.py`: estrutura de repetição `while`.

O projeto também possui o script `testar_todos.sh`, que automatiza a compilação e a execução de todos os programas presentes na pasta `examples/`.

Para executar os testes automatizados:

```bash
./testar_todos.sh
```

Na última execução, os oito programas foram compilados e executados sem falhas.

## Limitações

O projeto implementa um subconjunto simplificado da linguagem Python, não possuindo compatibilidade completa com a linguagem original.

Entre as limitações estão:

- Operações e valores tratados como inteiros;
- Funções limitadas a três parâmetros;
- Utilização de `range()` obrigatória na estrutura `for`;
- O comando `import` é reconhecido sintaticamente, mas não realiza o carregamento de módulos ou bibliotecas;
- Ausência de suporte a diversos recursos da linguagem Python original.

A implementação foi desenvolvida de forma incremental, com testes individuais durante o desenvolvimento para verificar o funcionamento dos recursos implementados.
