#!/usr/bin/env bash
# Script para crear un solo issue de HdU con épica en GitHub Project

set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
PROJECT_NUMBER=2

# Validar parámetros
if [ "$#" -lt 3 ]; then
    echo "Uso: $0 <HdU-ID> <archivo.md> <épica>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 HdU-001 HdU-001-Crear-Grupo.md 'VIII-Mantenedor-Grupos'"
    exit 1
fi

HDU_ID="$1"
ARCHIVO="$2"
EPICA="$3"

# Determinar módulo por ID
if [[ "$HDU_ID" =~ HdU-00[1-8] ]]; then
    MODULO="VIII"
    MODULO_DIR="VIII-Mantenedor-Grupos"
elif [[ "$HDU_ID" =~ HdU-0(09|1[0-6]) ]]; then
    MODULO="V"
    MODULO_DIR="V-Mantenedor-Usuarios-Relacionados"
else
    echo "❌ ID no reconocido: $HDU_ID"
    exit 1
fi

ARCHIVO_PATH="$MODULO_DIR/$ARCHIVO"

if [ ! -f "$ARCHIVO_PATH" ]; then
    echo "❌ Archivo no encontrado: $ARCHIVO_PATH"
    exit 1
fi

echo "📝 Creando issue para $HDU_ID"
echo "   Archivo: $ARCHIVO_PATH"
echo "   Épica: $EPICA"
echo ""

# Extraer título del archivo
TITLE=$(grep -m 1 "^# " "$ARCHIVO_PATH" | sed 's/^# //')
if [ -z "$TITLE" ]; then
    TITLE="$HDU_ID"
fi

ISSUE_TITLE="$HDU_ID: $TITLE"
BODY=$(cat "$ARCHIVO_PATH")

# Crear issue
echo "1️⃣ Creando issue..."
ISSUE_RESPONSE=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    -X POST \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues" \
    -d "$(jq -n \
        --arg title "$ISSUE_TITLE" \
        --arg body "$BODY" \
        --argjson labels "[\"HdU\",\"Módulo-$MODULO\"]" \
        '{title: $title, body: $body, labels: $labels}')")

ISSUE_NUMBER=$(echo "$ISSUE_RESPONSE" | jq -r '.number')
ISSUE_NODE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.node_id')

if [ "$ISSUE_NUMBER" = "null" ] || [ -z "$ISSUE_NUMBER" ]; then
    echo "❌ Error creando issue"
    echo "$ISSUE_RESPONSE" | jq '.'
    exit 1
fi

echo "   ✓ Issue #$ISSUE_NUMBER creado"
echo ""

# Obtener usuario y Project ID
echo "2️⃣ Obteniendo Project ID..."
USER_LOGIN=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query":"query { viewer { login } }"}' \
    https://api.github.com/graphql \
    | jq -r '.data.viewer.login')

PROJECT_QUERY='{
  "query": "query($login: String!, $number: Int!) { user(login: $login) { projectV2(number: $number) { id title } } }",
  "variables": {"login": "'$USER_LOGIN'", "number": '$PROJECT_NUMBER'}
}'

PROJECT_DATA=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PROJECT_QUERY" \
    https://api.github.com/graphql)

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')

if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
    echo "   ⚠️  No se pudo obtener Project ID (el issue fue creado)"
    echo "   Puedes agregarlo manualmente al proyecto"
    exit 0
fi

echo "   ✓ Project ID: $PROJECT_ID"
echo ""

# Agregar al proyecto
echo "3️⃣ Agregando al proyecto..."
ADD_MUTATION='{
  "query": "mutation($projectId: ID!, $contentId: ID!) { addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) { item { id } } }",
  "variables": {"projectId": "'$PROJECT_ID'", "contentId": "'$ISSUE_NODE_ID'"}
}'

ITEM_RESPONSE=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$ADD_MUTATION" \
    https://api.github.com/graphql)

ITEM_ID=$(echo "$ITEM_RESPONSE" | jq -r '.data.addProjectV2ItemById.item.id')

if [ "$ITEM_ID" = "null" ] || [ -z "$ITEM_ID" ]; then
    echo "   ⚠️  No se pudo agregar al proyecto"
    echo "   Issue #$ISSUE_NUMBER creado pero debes agregarlo manualmente"
    exit 0
fi

echo "   ✓ Agregado al proyecto"
echo ""

# Obtener Field ID del campo "epica"
echo "4️⃣ Asignando campo épica..."
FIELDS_QUERY='{
  "query": "query($projectId: ID!) { node(id: $projectId) { ... on ProjectV2 { fields(first: 20) { nodes { ... on ProjectV2Field { id name } ... on ProjectV2SingleSelectField { id name } } } } } }",
  "variables": {"projectId": "'$PROJECT_ID'"}
}'

FIELDS=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$FIELDS_QUERY" \
    https://api.github.com/graphql)

EPIC_FIELD_ID=$(echo "$FIELDS" | jq -r '.data.node.fields.nodes[] | select(.name == "epica") | .id')

if [ -z "$EPIC_FIELD_ID" ] || [ "$EPIC_FIELD_ID" = "null" ]; then
    echo "   ⚠️  Campo 'epica' no encontrado en el proyecto"
    echo "   Issue #$ISSUE_NUMBER creado y agregado al proyecto"
    echo "   Debes configurar el campo épica manualmente"
    exit 0
fi

# Asignar valor del campo épica
UPDATE_MUTATION='{
  "query": "mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) { updateProjectV2ItemFieldValue(input: {projectId: $projectId, itemId: $itemId, fieldId: $fieldId, value: {text: $value}}) { projectV2Item { id } } }",
  "variables": {"projectId": "'$PROJECT_ID'", "itemId": "'$ITEM_ID'", "fieldId": "'$EPIC_FIELD_ID'", "value": "'$EPICA'"}
}'

curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$UPDATE_MUTATION" \
    https://api.github.com/graphql > /dev/null

echo "   ✓ Campo 'epica' = $EPICA"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Completado"
echo "   Issue #$ISSUE_NUMBER: $ISSUE_TITLE"
echo "   Épica: $EPICA"
echo "   Ver: https://github.com/$REPO_OWNER/$PROJECT_REPO/issues/$ISSUE_NUMBER"
