#!/usr/bin/env bash
# Script para crear TODOS los issues de HdU con épica desde registro-hdu.md

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

echo "🚀 Creando issues de HdU desde registro"
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
        body="**Épica:** $module_dir

---

$(cat "$hdu_path")"
        
        labels='["HdU","Módulo-'$module'"'
        case "$status" in
            *"Completado"*|*"✅"*) labels="$labels,\"status: done\"" ;;
            *"desarrollo"*|*"🔄"*) labels="$labels,\"status: in progress\"" ;;
            *) labels="$labels,\"status: backlog\"" ;;
        esac
        labels="$labels]"
        
        echo "📝 $id - $file_title"
        echo "   Épica: Módulo $module: $module_dir"
        
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
        else
            echo "   ❌ Error"
            echo "$issue_response" | jq -r '.message'
        fi
        echo ""
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE" 2>/dev/null || true)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Completado"
echo "   HdU procesadas: $processed"
echo ""
echo "📌 Próximos pasos:"
echo "   1. Abre el proyecto: https://github.com/users/$REPO_OWNER/projects/2"
echo "   2. Agrega los issues recién creados al proyecto"
echo "   3. Configura el campo 'epica' desde la interfaz del proyecto"
echo "      (cada issue muestra su épica en el cuerpo)"
