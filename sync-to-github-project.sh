#!/bin/bash
# Script para sincronizar HdU con GitHub Project
# Uso: ./sync-to-github-project.sh

set -e

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
REPO_OWNER="lucianoalvarez-guabun"
REPO_NAME="agile-board-bbrr-control-acceso"
REGISTRY_FILE="registro-hdu.md"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN no está configurado"
    echo "Configura la variable de entorno: export GITHUB_TOKEN=tu_token"
    exit 1
fi

echo "📋 Sincronizando HdU con GitHub Project..."
echo "Repositorio: $REPO_OWNER/$REPO_NAME"
echo ""

# Función para crear o actualizar issue desde HdU
sync_hdu() {
    local hdu_id="$1"
    local hdu_file="$2"
    local module="$3"
    local status="$4"
    
    if [ ! -f "$hdu_file" ]; then
        echo "⚠️  Archivo no encontrado: $hdu_file (saltando)"
        return
    fi
    
    # Extraer título del archivo
    local title=$(grep -m 1 "^# " "$hdu_file" | sed 's/^# //')
    if [ -z "$title" ]; then
        title="$hdu_id"
    fi
    
    # Leer contenido del archivo
    local body=$(cat "$hdu_file")
    
    # Determinar etiquetas según estado
    local labels="[\"HdU\",\"Módulo-$module\""
    case "$status" in
        *"Completado"*) labels="$labels,\"done\"" ;;
        *"desarrollo"*) labels="$labels,\"in-progress\"" ;;
        *) labels="$labels,\"backlog\"" ;;
    esac
    labels="$labels]"
    
    echo "📝 $hdu_id: $title"
    
    # Buscar si ya existe el issue
    existing_issue=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues?labels=HdU&state=all" \
        | jq -r ".[] | select(.title | contains(\"$hdu_id\")) | .number")
    
    if [ -n "$existing_issue" ]; then
        echo "   ↻ Actualizando issue #$existing_issue"
        curl -s -X PATCH \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$existing_issue" \
            -d "{\"title\":\"$hdu_id: $title\",\"body\":$(echo "$body" | jq -Rs .),\"labels\":$labels}" \
            > /dev/null
    else
        echo "   + Creando nuevo issue"
        curl -s -X POST \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues" \
            -d "{\"title\":\"$hdu_id: $title\",\"body\":$(echo "$body" | jq -Rs .),\"labels\":$labels}" \
            > /dev/null
    fi
}

# Parsear registro-hdu.md y sincronizar cada HdU
echo "Procesando $REGISTRY_FILE..."
echo ""

# Módulo VIII
while IFS='|' read -r id file func module status; do
    # Limpiar espacios
    id=$(echo "$id" | xargs)
    file=$(echo "$file" | xargs)
    module=$(echo "$module" | xargs)
    status=$(echo "$status" | xargs)
    
    # Validar que sea una fila de datos
    if [[ "$id" =~ ^HdU-[0-9]{3}$ ]]; then
        # Construir ruta al archivo
        module_dir="${module}-Mantenedor-"
        case "$module" in
            "VIII") module_dir="VIII-Mantenedor-Grupos" ;;
            "V") module_dir="V-Mantenedor-Usuarios-Relacionados" ;;
            "VI") module_dir="VI-Mantenedor-Unidades-Negocio" ;;
            "VII") module_dir="VII-Mantenedor-Funciones" ;;
            "IX") module_dir="IX-Mantenedor-Alcance" ;;
            "X") module_dir="X-Mantenedor-Atribuciones" ;;
            "XI") module_dir="XI-Mantenedor-Opciones" ;;
            "XII") module_dir="XII-Mantenedor-Cargos" ;;
            "XIII") module_dir="XIII-Mantenedor-Tipo-Unidad" ;;
            "XIV") module_dir="XIV-Reportes" ;;
            "XV") module_dir="XV-Servicios-Distintas-Arquitecturas" ;;
        esac
        
        hdu_path="$module_dir/$file"
        sync_hdu "$id" "$hdu_path" "$module" "$status"
    fi
done < <(grep "^| HdU-" "$REGISTRY_FILE")

echo ""
echo "✅ Sincronización completada"
