#!/usr/bin/env bash
# Script para actualizar issues existentes cuando cambian los archivos HdU

set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-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}"
REPO_OWNER="lucianoalvarez-guabun"
PROJECT_REPO="sii-bbrr-control-acceso-context"
REGISTRY_FILE="../registro-hdu.md"

if [ ! -f "$REGISTRY_FILE" ]; then
    echo "❌ No se encuentra $REGISTRY_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq no está instalado"
    exit 1
fi

echo "🔄 Actualizando issues de HdU desde archivos"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Función para obtener nombre de directorio épica
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

# Obtener todos los issues del repositorio
echo "📥 Obteniendo issues existentes..."
ALL_ISSUES=$(curl -s \
    -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues?state=all&per_page=100" \
    | jq -c '.[] | {number: .number, title: .title, body: .body}')

echo "   ✓ $(echo "$ALL_ISSUES" | wc -l | xargs) issues obtenidos"
echo ""

updated=0
not_found=0
no_changes=0

while IFS='|' read -r _ id filename functionality module status _; do
    id=$(echo "$id" | xargs)
    filename=$(echo "$filename" | xargs)
    functionality=$(echo "$functionality" | xargs)
    module=$(echo "$module" | xargs)
    
    if [[ "$id" =~ ^HdU-[0-9]{3}$ ]] && [ "$filename" != "-" ] && [ -n "$filename" ]; then
        module_dir=$(get_module_dir "$module")
        
        if [ -z "$module_dir" ]; then
            continue
        fi
        
        hdu_path="../$module_dir/$filename"
        
        if [ ! -f "$hdu_path" ]; then
            echo "⚠️  Archivo no encontrado: $hdu_path"
            continue
        fi
        
        file_title=$(grep -m 1 "^# " "$hdu_path" | sed 's/^# //' | xargs)
        if [ -z "$file_title" ]; then
            file_title="$functionality"
        fi
        
        issue_title="$id: $file_title"
        new_body="**Épica:** $module_dir

---

$(cat "$hdu_path")"
        
        # Buscar issue existente por título
        issue_data=$(echo "$ALL_ISSUES" | jq -c --arg title "$issue_title" 'select(.title == $title) | {number: .number, body: .body}' | head -1)
        
        if [ -z "$issue_data" ]; then
            echo "⏭️  $id - No encontrado en GitHub (crear con create-all-hdus.sh)"
            ((not_found++))
            continue
        fi
        
        issue_number=$(echo "$issue_data" | jq -r '.number')
        current_body=$(echo "$issue_data" | jq -r '.body // ""')
        
        # Comparar contenido (ignorar espacios al final)
        current_body_normalized=$(echo "$current_body" | sed 's/[[:space:]]*$//')
        new_body_normalized=$(echo "$new_body" | sed 's/[[:space:]]*$//')
        
        if [ "$current_body_normalized" = "$new_body_normalized" ]; then
            echo "✓ $id - Issue #$issue_number sin cambios"
            ((no_changes++))
            continue
        fi
        
        echo "📝 $id - Actualizando issue #$issue_number"
        
        # Actualizar issue
        update_response=$(curl -s -X PATCH \
            -H "Authorization: token $GITHUB_TOKEN" \
            "https://api.github.com/repos/$REPO_OWNER/$PROJECT_REPO/issues/$issue_number" \
            -d "$(jq -n \
                --arg title "$issue_title" \
                --arg body "$new_body" \
                '{title: $title, body: $body}')")
        
        updated_number=$(echo "$update_response" | jq -r '.number')
        
        if [ "$updated_number" = "$issue_number" ]; then
            echo "   ✓ Actualizado"
            ((updated++))
        else
            echo "   ❌ Error actualizando"
            echo "$update_response" | jq -r '.message' | head -1
        fi
        echo ""
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Resumen"
echo "   Actualizados: $updated"
echo "   Sin cambios: $no_changes"
echo "   No encontrados: $not_found"
echo ""

if [ $not_found -gt 0 ]; then
    echo "💡 Para crear los issues faltantes, ejecuta:"
    echo "   ./create-all-hdus.sh"
fi
