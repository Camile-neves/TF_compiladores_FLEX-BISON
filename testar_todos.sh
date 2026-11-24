#!/bin/bash

DIRETORIO="$(cd "$(dirname "$0")" && pwd)"
TOTAL=0
SUCESSO=0
FALHA=0

echo "=========================================="
echo " TESTES AUTOMATIZADOS DO COMPILADOR"
echo "=========================================="

# Compila o compilador
cd "$DIRETORIO" || exit 1

if ! make; then
    echo "ERRO: Não foi possível compilar o compilador."
    exit 1
fi

echo ""

for arquivo in "$DIRETORIO"/examples/*.py; do

    nome=$(basename "$arquivo")

    # Ignora os exemplos que possuem erros intencionais
    if [[ "$nome" == teste_erro_* || "$nome" == "teste_multiplos_erros.py" ]]; then
        continue
    fi

    TOTAL=$((TOTAL + 1))

    echo ""
    echo "------------------------------------------"
    echo "Testando: $nome"
    echo "------------------------------------------"

    TEMP=$(mktemp -d)

    (
        cd "$TEMP" || exit 1

        "$DIRETORIO/compilador" "$arquivo" Programa.j &&
        jasmin Programa.j &&
        java Programa
    )

    RESULTADO=$?

    rm -rf "$TEMP"

    if [ "$RESULTADO" -eq 0 ]; then
        echo "RESULTADO: EXECUCAO CONCLUIDA"
        SUCESSO=$((SUCESSO + 1))
    else
        echo "RESULTADO: FALHA"
        FALHA=$((FALHA + 1))
    fi

done

echo ""
echo "=========================================="
echo " RESUMO DOS TESTES"
echo "=========================================="
echo "Total de programas: $TOTAL"
echo "Execuções concluídas: $SUCESSO"
echo "Falhas: $FALHA"
echo "=========================================="
