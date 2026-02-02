#!/usr/bin/env bash
# Script para cerrar TODOS los issues del repositorio

GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"

echo "🗑️  Cerrando todos los issues..."
echo ""

closed=0
for page in 1 2 3; do
  curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=open&per_page=100&page=$page" \
    | jq -r '.[].number'
done | while read issue; do
  curl -s -X PATCH \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$issue" \
    -d '{"state":"closed"}' > /dev/null
  echo "✓ Issue #$issue cerrado"
  ((closed++))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Total cerrados: $closed"

# Verificar
open_count=$(curl -s \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=open" \
  | jq -r 'length')

echo "   Issues abiertos restantes: $open_count"
