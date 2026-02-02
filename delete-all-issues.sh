#!/usr/bin/env bash
# Script para borrar todos los issues de HdU y épicas

set -e

GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: Token requerido"
    exit 1
fi

echo "🗑️  Borrando todos los issues de HdU y épicas..."
echo ""

# Obtener todos los issues con etiquetas HdU o epic
all_issues=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=all&per_page=100" \
    | jq -r '.[] | select(.labels[].name | test("HdU|epic")) | .number' | sort -u)

count=0
for issue in $all_issues; do
    ((count++))
    echo "Cerrando issue #$issue..."
    curl -s -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$issue" \
        -d '{"state":"closed"}' > /dev/null
done

echo ""
echo "✅ $count issues cerrados"
echo ""
echo "Esperando 2 segundos antes de eliminar..."
sleep 2

echo ""
echo "🗑️  Ahora eliminando issues cerrados (requiere permisos)..."
echo "⚠️  Nota: GitHub no permite eliminar issues via API, solo cerrarlos"
echo "   Los issues quedarán cerrados pero seguirán en el repo"
echo ""
echo "Si deseas eliminarlos completamente, debes hacerlo manualmente desde:"
echo "https://github.com/$REPO_OWNER/$PROJECT_REPO/issues?q=is%3Aclosed"
