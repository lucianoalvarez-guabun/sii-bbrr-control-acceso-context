#!/usr/bin/env bash
# Script completo para sincronizar HdU con GitHub Project usando GraphQL
# Uso: ./sync-complete.sh [token]

set -e

GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
PROJECT_NUMBER="2"
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
    | jq -r '.[] | select(.labels[].name | test("HdU|epic")) | .number')

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

# Paso 2: Obtener Project ID
echo "📊 Paso 2: Obteniendo Project ID..."
project_query='query { 
  user(login: "'$REPO_OWNER'") { 
    projectV2(number: '$PROJECT_NUMBER') { 
      id 
      title
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
          }
          ... on ProjectV2SingleSelectField {
            id
            name
          }
        }
      }
    } 
  } 
}'

project_data=$(curl -s -X POST \
    -H "Authorization: bearer $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    https://api.github.com/graphql \
    -d "$(jq -n --arg query "$project_query" '{query: $query}')")

PROJECT_ID=$(echo "$project_data" | jq -r '.data.user.projectV2.id')
PROJECT_TITLE=$(echo "$project_data" | jq -r '.data.user.projectV2.title')

if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: No se pudo obtener el Project ID"
    echo "Response: $project_data"
    exit 1
fi

echo "  ✓ Project ID: $PROJECT_ID"
echo "  ✓ Título: $PROJECT_TITLE"
echo ""

# Paso 3: Obtener Field ID del campo "epica"
echo "🔍 Paso 3: Obteniendo Field ID del campo 'epica'..."
FIELD_ID=$(echo "$project_data" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name == "epica") | .id')

if [ "$FIELD_ID" = "null" ] || [ -z "$FIELD_ID" ]; then
    echo "❌ Error: No se encontró el campo 'epica'"
    echo "Campos disponibles:"
    echo "$project_data" | jq -r '.data.user.projectV2.fields.nodes[].name'
    exit 1
fi

echo "  ✓ Field ID: $FIELD_ID"
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
echo "📝 Paso 4: Creando HdU..."
echo ""

processed=0

while IFS='|' read -r _ id filename functionality module status _; do
    id=$(echo "$id" | xargs)
    filename=$(echo "$filename" | xargs)
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
        issue_title="$id: $file_title"
        body=$(cat "$hdu_path")
        
        labels='["HdU","Módulo-'$module'"'
        case "$status" in
            *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
            *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
            *) labels="$labels,\"status: backlog\"" ;;
        esac
        labels="$labels]"
        
        echo "📌 $id - $file_title"
        
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
        
        if [ "$issue_number" = "null" ]; then
            echo "  ❌ Error creando issue"
            continue
        fi
        
        echo "  ✓ Issue #$issue_number creado"
        
        # Agregar al proyecto
        add_mutation='mutation { 
          addProjectV2ItemById(input: {
            projectId: "'$PROJECT_ID'", 
            contentId: "'$issue_node_id'"
          }) { 
            item { id } 
          } 
        }'
        
        add_result=$(curl -s -X POST \
            -H "Authorization: bearer $GITHUB_TOKEN" \
            -H "Content-Type: application/json" \
            https://api.github.com/graphql \
            -d "$(jq -n --arg query "$add_mutation" '{query: $query}')")
        
        item_id=$(echo "$add_result" | jq -r '.data.addProjectV2ItemById.item.id')
        
        if [ "$item_id" = "null" ] || [ -z "$item_id" ]; then
            echo "  ⚠️  No se pudo agregar al proyecto"
        else
            echo "  ✓ Agregado al proyecto (Item ID: ${item_id:0:20}...)"
            
            # Asignar campo "epica"
            update_mutation='mutation { 
              updateProjectV2ItemFieldValue(input: {
                projectId: "'$PROJECT_ID'", 
                itemId: "'$item_id'", 
                fieldId: "'$FIELD_ID'", 
                value: {text: "'"$module_dir"'"}
              }) { 
                projectV2Item { id } 
              } 
            }'
            
            curl -s -X POST \
                -H "Authorization: bearer $GITHUB_TOKEN" \
                -H "Content-Type: application/json" \
                https://api.github.com/graphql \
                -d "$(jq -n --arg query "$update_mutation" '{query: $query}')" > /dev/null
            
            echo "  ✓ Campo epica: $module_dir"
        fi
        
        ((processed++))
        echo ""
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null || true)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sincronización completada"
echo "   HdU procesadas: $processed"
echo ""
echo "Ver proyecto en:"
echo "https://github.com/users/$REPO_OWNER/projects/$PROJECT_NUMBER"
