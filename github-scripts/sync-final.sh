#!/usr/bin/env bash
# Script completo para sincronizar HdU con GitHub Project usando GraphQL

set -e

GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
REGISTRY_FILE="registro-hdu.md"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: Token requerido"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq no está instalado"
    exit 1
fi

echo "🚀 Sincronización completa con GitHub Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paso 1: Cerrar todos los issues existentes
echo "🗑️  Paso 1: Cerrando issues existentes..."
all_issues=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=open&per_page=100" \
    | jq -r '.[].number')

count=0
for issue in $all_issues; do
    ((count++))
    curl -s -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$issue" \
        -d '{"state":"closed"}' > /dev/null
    echo "  ✓ Issue #$issue cerrado"
done
echo "  Total cerrados: $count"
echo ""

# Paso 2: Obtener información del proyecto
echo "📊 Paso 2: Obteniendo Project ID..."

PROJECT_NUMBER=2

user_login=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query":"query { viewer { login } }"}' \
    https://api.github.com/graphql \
    | jq -r '.data.viewer.login')

echo "  Usuario: $user_login"

project_query='{
  "query": "query($login: String!, $number: Int!) { user(login: $login) { projectV2(number: $number) { id title } } }",
  "variables": {"login": "'$user_login'", "number": '$PROJECT_NUMBER'}
}'

project_data=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$project_query" \
    https://api.github.com/graphql)

project_id=$(echo "$project_data" | jq -r '.data.user.projectV2.id')
project_title=$(echo "$project_data" | jq -r '.data.user.projectV2.title')

if [ "$project_id" = "null" ] || [ -z "$project_id" ]; then
    echo "❌ No se pudo obtener el proyecto #$PROJECT_NUMBER"
    exit 1
fi

echo "  ✓ Proyecto: $project_title"
echo "  ✓ Project ID: $project_id"
echo ""

# Paso 3: Obtener el Field ID del campo "epica"
echo "🔍 Paso 3: Obteniendo Field ID del campo 'epica'..."

fields_query='{
  "query": "query($projectId: ID!) { node(id: $projectId) { ... on ProjectV2 { fields(first: 20) { nodes { ... on ProjectV2Field { id name } ... on ProjectV2SingleSelectField { id name } } } } } }",
  "variables": {"projectId": "'$project_id'"}
}'

fields=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$fields_query" \
    https://api.github.com/graphql)

epic_field_id=$(echo "$fields" | jq -r '.data.node.fields.nodes[] | select(.name == "epica") | .id')

if [ -z "$epic_field_id" ] || [ "$epic_field_id" = "null" ]; then
    echo "❌ No se encontró el campo 'epica'"
    exit 1
fi

echo "  ✓ Campo 'epica' ID: $epic_field_id"
echo ""

# Funciones auxiliares
get_module_dir() {
    case "$1" in
        "VIII") echo "VIII-Mantenedor-Grupos" ;;
        "V") echo "V-Mantenedor-Usuarios-Relacionados" ;;
        "VI") echo "VI-Mantenedor-Unidades-Negocio" ;;
        "VII") echo "VII-Mantenedor-Funciones" ;;
        "IX") echo "IX-Mantenedor-Alcance" ;;
        "X") echo "X-Mantenedor-Atribuciones" ;;
        "XI") echo "XI-Mantenedor-Opciones" ;;
        "XII") echo "XII-Mantenedor-Cargos" ;;
        "XIII") echo "XIII-Mantenedor-Tipo-Unidad" ;;
        "XIV") echo "XIV-Reportes" ;;
        "XV") echo "XV-Servicios-Distintas-Arquitecturas" ;;
        *) echo "" ;;
    esac
}

# Paso 4: Crear HdU
echo "📝 Paso 4: Creando HdU y asignando al proyecto..."
echo ""

processed=0

while IFS='|' read -r _ id filename functionality module status _; do
    id=$(echo "$id" | xargs)
    filename=$(echo "$filename" | xargs)
    functionality=$(echo "$functionality" | xargs)
    module=$(echo "$module" | xargs)
    status=$(echo "$status" | xargs)
    
    if [[ "$id" =~ ^HdU-[0-9]{3}$ ]] && [ "$filename" != "-" ] && [ -n "$filename" ]; then
        module_dir=$(get_module_dir "$module")
        
        if [ -z "$module_dir" ]; then
            continue
        fi
        
        hdu_path="$module_dir/$filename"
        
        if [ ! -f "$hdu_path" ]; then
            continue
        fi
        
        file_title=$(grep -m 1 "^# " "$hdu_path" | sed 's/^# //' | xargs)
        if [ -z "$file_title" ]; then
            file_title="$functionality"
        fi
        
        issue_title="$id: $file_title"
        body=$(cat "$hdu_path")
        
        labels='["HdU","Módulo-'$module'"'
        case "$status" in
            *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
            *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
            *) labels="$labels,\"status: backlog\"" ;;
        esac
        labels="$labels]"
        
        echo "📝 $id - $file_title"
        
        # Crear issue
        issue_response=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            -X POST \
            "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues" \
            -d "$(jq -n \
                --arg title "$issue_title" \
                --arg body "$body" \
                --argjson labels "$labels" \
                '{title: $title, body: $body, labels: $labels}')")
        
        issue_number=$(echo "$issue_response" | jq -r '.number')
        issue_node_id=$(echo "$issue_response" | jq -r '.node_id')
        
        if [ "$issue_number" != "null" ]; then
            echo "   ✓ Issue #$issue_number creado"
            
            # Agregar al proyecto
            add_mutation='{
              "query": "mutation($projectId: ID!, $contentId: ID!) { addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) { item { id } } }",
              "variables": {"projectId": "'$project_id'", "contentId": "'$issue_node_id'"}
            }'
            
            item_response=$(curl -s -X POST \
                -H "Authorization: bearer $GITHUB_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$add_mutation" \
                https://api.github.com/graphql)
            
            item_id=$(echo "$item_response" | jq -r '.data.addProjectV2ItemById.item.id')
            
            if [ "$item_id" != "null" ] && [ -n "$item_id" ]; then
                echo "   ✓ Agregado al proyecto"
                
                # Asignar campo epica
                update_mutation='{
                  "query": "mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) { updateProjectV2ItemFieldValue(input: {projectId: $projectId, itemId: $itemId, fieldId: $fieldId, value: {text: $value}}) { projectV2Item { id } } }",
                  "variables": {"projectId": "'$project_id'", "itemId": "'$item_id'", "fieldId": "'$epic_field_id'", "value": "'$module_dir'"}
                }'
                
                curl -s -X POST \
                    -H "Authorization: bearer $GITHUB_TOKEN" \
                    -H "Content-Type: application/json" \
                    -d "$update_mutation" \
                    https://api.github.com/graphql > /dev/null
                
                echo "   ✓ Campo 'epica' = $module_dir"
            fi
            
            ((processed++))
        fi
        echo ""
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sincronización completada"
echo "   HdU procesadas: $processed"
echo ""
echo "Ver proyecto en:"
echo "https://github.com/users/$user_login/projects/$PROJECT_NUMBER"
