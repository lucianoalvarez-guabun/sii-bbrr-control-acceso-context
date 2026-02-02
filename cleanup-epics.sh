#!/usr/bin/env bash
# Script para limpiar épicas duplicadas
# Mantiene solo la primera épica de cada módulo y cierra el resto

set -e

GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: Token requerido"
    exit 1
fi

echo "🧹 Limpiando épicas duplicadas..."
echo ""

# Para cada módulo, mantener solo la primera épica
for module in "VIII" "V" "VI" "VII" "IX" "X" "XI" "XII" "XIII" "XIV" "XV"; do
    echo "Procesando Módulo $module..."
    
    # Obtener todas las épicas de este módulo
    epics=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?labels=epic,Módulo-$module&state=open&per_page=100" \
        | jq -r '.[].number')
    
    count=0
    for epic in $epics; do
        ((count++))
        if [ $count -eq 1 ]; then
            echo "  ✓ Manteniendo épica #$epic"
        else
            echo "  ✗ Cerrando duplicado #$epic"
            curl -s -X PATCH \
                -H "Authorization: token $GITHUB_TOKEN" \
                "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$epic" \
                -d '{"state":"closed"}' > /dev/null
        fi
    done
done

echo ""
echo "✅ Limpieza completada"
