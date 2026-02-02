#!/usr/bin/env bash
# Script para sincronizar HdU con GitHub Project
# Uso: ./sync-to-github-project.sh [token]

set -e

# Configuración
GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
REGISTRY_FILE="registro-hdu.md"
EPIC_CACHE_FILE="/tmp/epic_numbers_$$"

# Limpiar cache al salir
trap "rm -f $EPIC_CACHE_FILE" EXIT

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

# Funciones para gestionar cache de épicas
save_epic() {
    local module="$1"
    local number="$2"
    echo "$module=$number" >> "$EPIC_CACHE_FILE"
}

get_epic() {
    local module="$1"
    if [ -f "$EPIC_CACHE_FILE" ]; then
        grep "^${module}=" "$EPIC_CACHE_FILE" 2>/dev/null | cut -d= -f2
    fi
}

# Función para obtener nombre completo del módulo
get_module_name() {
    case "$1" in
        "VIII") echo "Módulo VIII: Mantenedor de Grupos" ;;
        "V") echo "Módulo V: Mantenedor de Usuarios Relacionados" ;;
        "VI") echo "Módulo VI: Mantenedor de Unidades de Negocio" ;;
        "VII") echo "Módulo VII: Mantenedor de Funciones" ;;
        "IX") echo "Módulo IX: Mantenedor de Alcance" ;;
        "X") echo "Módulo X: Mantenedor de Atribuciones" ;;
        "XI") echo "Módulo XI: Mantenedor de Opciones" ;;
        "XII") echo "Módulo XII: Mantenedor de Cargos" ;;
        "XIII") echo "Módulo XIII: Mantenedor de Tipo de Unidad" ;;
        "XIV") echo "Módulo XIV: Reportes" ;;
        "XV") echo "Módulo XV: Servicios Distintas Arquitecturas" ;;
        *) echo "Módulo $1" ;;
    esac
}

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

# Función para crear/actualizar épica
ensure_epic() {
    local module="$1"
    local module_name=$(get_module_name "$module")
    local module_dir=$(get_module_dir "$module")
    
    # Buscar épica existente (solo la primera coincidencia)
    local existing_epic=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=all&labels=epic,Módulo-$module&per_page=1" \
        | jq -r 'if length > 0 then .[0].number else empty end' 2>/dev/null || echo "")
    
    if [ -n "$existing_epic" ]; then
        save_epic "$module" "$existing_epic"
        echo "   ✓ Épica #$existing_epic: $module_name (existente)"
        return
    fi
    
    # Crear épica inicial (se actualizará después con las HdU)
    local epic_body="# Épica: $module_name

Agrupa todas las Historias de Usuario (HdU) del $module_name.

## 📁 Documentación
- Directorio: \`docs/develop-plan/$module_dir/\`

## 📋 Historias de Usuario
_Las HdU se vincularán automáticamente aquí..._

---
*Esta épica se sincroniza automáticamente desde el registro de HdU.*"

    local response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -X POST \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues" \
        -d "$(jq -n \
            --arg title "EPIC: $module_name" \
            --arg body "$epic_body" \
            --argjson labels '["epic","Módulo-'$module'"]' \
            '{title: $title, body: $body, labels: $labels}')")
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        local epic_number=$(echo "$response_body" | jq -r '.number')
        save_epic "$module" "$epic_number"
        echo "   📦 Épica #$epic_number creada: $module_name"
    else
        echo "   ❌ Error creando épica para $module"
    fi
}

# Función para actualizar épica con task list de HdU
update_epic_with_hdus() {
    local module="$1"
    local epic_number=$(get_epic "$module")
    
    if [ -z "$epic_number" ]; then
        return
    fi
    
    local module_name=$(get_module_name "$module")
    local module_dir=$(get_module_dir "$module")
    
    # Obtener todas las HdU de este módulo
    local hdus=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?labels=HdU,Módulo-$module&state=all&per_page=100" \
        | jq -r '.[] | "- [ ] #\(.number) - \(.title)"')
    
    if [ -z "$hdus" ]; then
        return
    fi
    
    # Construir body con task list
    local epic_body="# Épica: $module_name

Agrupa todas las Historias de Usuario (HdU) del $module_name.

## 📁 Documentación
- Directorio: \`docs/develop-plan/$module_dir/\`

## 📋 Historias de Usuario

$hdus

---
*Esta épica se sincroniza automáticamente desde el registro de HdU.*  
*Marca las checkboxes según el progreso de cada HdU.*"
    
    # Actualizar épica
    curl -s -X PATCH \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$epic_number" \
        -d "$(jq -n \
            --arg body "$epic_body" \
            '{body: $body}')" > /dev/null
}

# Función para crear issue en GitHub
create_issue() {
    local hdu_id="$1"
    local title="$2"
    local body="$3"
    local labels="$4"
    local epic_number="$5"
    
    # Agregar referencia a la épica en el body
    if [ -n "$epic_number" ]; then
        body="$body

---
**Épica:** #$epic_number"
    fi
    
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
    
    # Obtener número de épica
    local epic_number=$(get_epic "$module")
    
    echo "📝 $hdu_id - $file_title"
    
    # Buscar si existe el issue
    local existing_issue=$(find_issue "$hdu_id")
    
    if [ -n "$existing_issue" ]; then
        # Agregar referencia a épica en body si existe
        if [ -n "$epic_number" ]; then
            body="$body

---
**Épica:** #$epic_number"
        fi
        update_issue "$existing_issue" "$issue_title" "$body" "$labels"
    else
        create_issue "$hdu_id" "$issue_title" "$body" "$labels" "$epic_number"
    fi
}

# Paso 1: Identificar módulos únicos en el registro
echo "🔍 Identificando módulos..."
modules=$(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null | awk -F'|' '{print $5}' | xargs | sort -u)

# Paso 2: Crear épicas para cada módulo
echo ""
echo "📦 Creando/verificando épicas..."
for module in $modules; do
    if [ -n "$module" ] && [ "$module" != "-" ]; then
        ensure_epic "$module"
    fi
done

# Contador de HdU procesadas
processed=0

# Paso 3: Parsear registro-hdu.md y sincronizar HdU
echo ""
echo "📝 Procesando HdU..."
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

# Paso 4: Actualizar épicas con task lists de sus HdU
echo ""
echo "🔗 Vinculando HdU a épicas..."
for module in $modules; do
    if [ -n "$module" ] && [ "$module" != "-" ]; then
        epic_num=$(get_epic "$module")
        if [ -n "$epic_num" ]; then
            echo "   → Actualizando épica #$epic_num ($(get_module_name "$module"))"
            update_epic_with_hdus "$module"
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sincronización completada"
echo "   Épicas: $(wc -l < "$EPIC_CACHE_FILE" 2>/dev/null || echo 0)"
echo "   HdU procesadas: $processed"
echo ""
echo "Ver en GitHub:"
echo "  - Épicas: https://github.com/$REPO_OWNER/$PROJECT_REPO/issues?q=label%3Aepic"
echo "  - HdU: https://github.com/$REPO_OWNER/$PROJECT_REPO/issues?q=label%3AHdU"
echo ""
echo "💡 Las épicas ahora incluyen task lists con links a las HdU"
