#!/usr/bin/env bash
# Script simplificado para crear HdU sin asignar a proyecto
# (El usuario puede agregarlos al proyecto manualmente desde la UI de GitHub)

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

echo "🚀 Sincronización de HdU"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

# Crear HdU
echo "📝 Creando HdU issues..."
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
        
        # Agregar el módulo/épica al cuerpo del issue
        body="**Épica:** \`$module_dir\`

---

$(cat "$hdu_path")"
        
        labels='["HdU","Módulo-'$module'"'
        case "$status" in
            *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
            *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
            *) labels="$labels,\"status: backlog\"" ;;
        esac
        labels="$labels]"
        
        echo "📝 $id - $file_title (Épica: $module_dir)"
        
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
        
        if [ "$issue_number" != "null" ]; then
            echo "   ✓ Issue #$issue_number creado"
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
echo "📌 Próximos pasos:"
echo "   1. Abre el proyecto: https://github.com/users/lucianoalvarez-guabun/projects/2"
echo "   2. Selecciona todos los issues recién creados"
echo "   3. Configura el campo 'epica' manualmente (cada issue muestra su épica en el cuerpo)"
echo ""
echo "   O bien:"
echo "   - Genera un nuevo token con permiso 'read:project' en:"
echo "     https://github.com/settings/tokens"
echo "   - Y vuelve a ejecutar el script sync-final.sh con el nuevo token"
