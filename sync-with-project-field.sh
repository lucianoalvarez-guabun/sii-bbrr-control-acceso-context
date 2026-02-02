#!/usr/bin/env bash
# Script para sincronizar HdU con GitHub Project usando campo custom "epica"
# Uso: ./sync-with-project-field.sh [token]

set -e

GITHUB_TOKEN="${1:-${GITHUB_TOKEN}}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
REGISTRY_FILE="registro-hdu.md"

# Verificar token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: Token de GitHub no proporcionado"
    exit 1
fi

# Verificar jq
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq no está instalado"
    exit 1
fi

echo "📋 Sincronizando HdU con GitHub Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Repositorio: $REPO_OWNER/$PROJECT_REPO"
echo ""

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

# Función para crear issue con campo epica
create_issue_with_epic_field() {
    local hdu_id="$1"
    local title="$2"
    local body="$3"
    local labels="$4"
    local epic_value="$5"  # Valor del campo epica (ej: "VIII-Mantenedor-Grupos")
    
    # Crear issue
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
        echo "   ✅ Issue #$issue_number creado (epica: $epic_value)"
        
        # Nota: El campo custom "epica" se asignará desde la interfaz del proyecto
        # o mediante GraphQL API si se implementa
        
        return 0
    else
        echo "   ❌ Error HTTP $http_code"
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
    
    # Leer contenido completo y agregar info del campo epica
    local body=$(cat "$hdu_path")
    body="$body

---
**Módulo:** $module_dir  
**Campo epica:** \`$module_dir\`"
    
    # Construir etiquetas
    local labels='["HdU","Módulo-'$module'"'
    case "$status" in
        *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
        *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
        *"Pendiente"*|*"⏳"*) labels="$labels,\"status: backlog\"" ;;
    esac
    labels="$labels]"
    
    echo "📝 $hdu_id - $file_title"
    
    create_issue_with_epic_field "$hdu_id" "$issue_title" "$body" "$labels" "$module_dir"
}

# Contador de HdU procesadas
processed=0

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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Sincronización completada"
echo "   HdU procesadas: $processed"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Ve al GitHub Project: https://github.com/users/$REPO_OWNER/projects"
echo "   2. Agrega los issues al proyecto"
echo "   3. El campo 'epica' se debe asignar manualmente por ahora"
echo "   4. Valor a usar en campo epica: {MODULO}-Mantenedor-{NOMBRE}"
echo ""
echo "Ver issues en:"
echo "https://github.com/$REPO_OWNER/$PROJECT_REPO/issues?q=label%3AHdU"
