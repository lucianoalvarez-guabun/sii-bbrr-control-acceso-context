#!/bin/bash
# Script para sincronizar HdU con GitHub Project
# Uso: ./sync-to-github-project.sh [token]

set -e

# Configuración
GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
REGISTRY_FILE="registro-hdu.md"

# Verificar token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: Token de GitHub no proporcionado"
    echo "Uso: ./sync-to-github-project.sh <github_token>"
    echo "   o: export GITHUB_TOKEN=<token> && ./sync-to-github-project.sh"
    exit 1
fi

# Verificar jq
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq no está instalado"
    echo "Instalar con: brew install jq"
    exit 1
fi

echo "📋 Sincronizando HdU con GitHub Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Proyecto: $REPO_OWNER/$PROJECT_REPO"
echo ""

# Función para mapear módulo a directorio
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

# Función para crear issue en GitHub
create_issue() {
    local hdu_id="$1"
    local title="$2"
    local body="$3"
    local labels="$4"
    
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -X POST \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues" \
        -d "$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            --argjson labels "$labels" \
            '{title: $title, body: $body, labels: $labels}')")
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        local issue_number=$(echo "$response_body" | jq -r '.number')
        echo "   ✅ Issue #$issue_number creado"
        return 0
    else
        echo "   ❌ Error HTTP $http_code"
        echo "$response_body" | jq -r '.message // "Error desconocido"' >&2
        return 1
    fi
}

# Función para buscar issue existente por ID
find_issue() {
    local hdu_id="$1"
    
    curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=all&labels=HdU&per_page=100" \
        | jq -r ".[] | select(.title | startswith(\"$hdu_id:\")) | .number" \
        | head -n1
}

# Función para actualizar issue
update_issue() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local labels="$4"
    
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -X PATCH \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$issue_number" \
        -d "$(jq -n \
            --arg title "$title" \
            --arg body "$body" \
            --argjson labels "$labels" \
            '{title: $title, body: $body, labels: $labels}')")
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" = "200" ]; then
        echo "   🔄 Issue #$issue_number actualizado"
        return 0
    else
        echo "   ❌ Error HTTP $http_code al actualizar"
        return 1
    fi
}

# Función principal para sincronizar una HdU
sync_hdu() {
    local hdu_id="$1"
    local filename="$2"
    local functionality="$3"
    local module="$4"
    local status="$5"
    
    # Construir ruta al archivo
    local module_dir=$(get_module_dir "$module")
    if [ -z "$module_dir" ]; then
        echo "⚠️  $hdu_id: Módulo desconocido '$module' (saltando)"
        return
    fi
    
    local hdu_path="$module_dir/$filename"
    
    if [ ! -f "$hdu_path" ]; then
        echo "⚠️  $hdu_id: Archivo no encontrado '$hdu_path' (saltando)"
        return
    fi
    
    # Leer título del archivo
    local file_title=$(grep -m 1 "^# " "$hdu_path" | sed 's/^# //' | xargs)
    if [ -z "$file_title" ]; then
        file_title="$functionality"
    fi
    
    # Construir título del issue
    local issue_title="$hdu_id: $file_title"
    
    # Leer contenido completo
    local body=$(cat "$hdu_path")
    
    # Construir etiquetas
    local labels='["HdU","Módulo-'$module'"'
    case "$status" in
        *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
        *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
        *"Pendiente"*|*"⏳"*) labels="$labels,\"status: backlog\"" ;;
    esac
    labels="$labels]"
    
    echo "📝 $hdu_id - $file_title"
    
    # Buscar si existe el issue
    local existing_issue=$(find_issue "$hdu_id")
    
    if [ -n "$existing_issue" ]; then
        update_issue "$existing_issue" "$issue_title" "$body" "$labels"
    else
        create_issue "$hdu_id" "$issue_title" "$body" "$labels"
    fi
}

# Contador de HdU procesadas
processed=0
created=0
updated=0
skipped=0

# Parsear registro-hdu.md
echo "Procesando $REGISTRY_FILE..."
echo ""

while IFS='|' read -r _ id filename functionality module status _; do
    # Limpiar espacios
    id=$(echo "$id" | xargs)
    filename=$(echo "$filename" | xargs)
    functionality=$(echo "$functionality" | xargs)
    module=$(echo "$module" | xargs)
    status=$(echo "$status" | xargs)
    
    # Validar formato HdU-XXX
    if [[ "$id" =~ ^HdU-[0-9]{3}$ ]] && [ "$filename" != "-" ] && [ -n "$filename" ]; then
        sync_hdu "$id" "$filename" "$functionality" "$module" "$status"
        ((processed++))
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sincronización completada"
echo "   HdU procesadas: $processed"
echo ""
echo "Ver issues en:"
echo "https://github.com/$REPO_OWNER/$PROJECT_REPO/issues?q=label%3AHdU"
