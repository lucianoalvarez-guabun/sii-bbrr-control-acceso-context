#!/bin/bash

# convert-image-urls.sh
# Helper para convertir rutas relativas de imágenes a URLs absolutas de GitHub
# y agregar sección de documentación de referencia
# 
# Uso: convert-image-urls.sh <archivo_hdu> <modulo>
# Ejemplo: convert-image-urls.sh HdU-009-Buscar-Usuario.md V-Mantenedor-Usuarios-Relacionados

set -e

REPO_OWNER="lucianoalvarez-guabun"
REPO_NAME="sii-bbrr-control-acceso-context"
BRANCH="main"
BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}"

if [ $# -ne 2 ]; then
    echo "❌ Error: Se requieren 2 parámetros" >&2
    echo "Uso: $0 <archivo_hdu> <modulo>" >&2
    exit 1
fi

HDU_FILE="$1"
MODULO="$2"

if [ ! -f "$HDU_FILE" ]; then
    echo "❌ Error: Archivo $HDU_FILE no existe" >&2
    exit 1
fi

# Convertir rutas relativas a URLs de GitHub (raw para que se vean en Issues)
# Patrones a convertir:
# - ![desc](./images/image-0027.png) → ![desc](https://raw.githubusercontent.com/.../main/MODULE/images/image-0027.png)
# - ![image-0027](./images/image-0027.png) → ![image-0027](https://raw.githubusercontent.com/.../main/MODULE/images/image-0027.png)

content=$(sed -E "s|\!\[([^]]*)\]\(\./images/([^)]+)\)|![\\1](https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${MODULO}/images/\\2)|g" "$HDU_FILE")

# Agregar sección de documentación de referencia
module_dir=$(dirname "$HDU_FILE")

docs_section="

---

## Documentación de Referencia

"

# Verificar y agregar backend-apis.md
if [ -f "${module_dir}/backend-apis.md" ]; then
    docs_section+="- **Backend APIs**: [${MODULO}/backend-apis.md](${BASE_URL}/${MODULO}/backend-apis.md)
"
fi

# Verificar y agregar frontend.md
if [ -f "${module_dir}/frontend.md" ]; then
    docs_section+="- **Frontend**: [${MODULO}/frontend.md](${BASE_URL}/${MODULO}/frontend.md)
"
fi

# Verificar y agregar DDL
if [ -d "${module_dir}/DDL" ]; then
    ddl_files=$(ls "${module_dir}/DDL/"*.sql 2>/dev/null || true)
    if [ -n "$ddl_files" ]; then
        docs_section+="- **DDL (Base de Datos)**:
"
        for sql_file in ${module_dir}/DDL/*.sql; do
            if [ -f "$sql_file" ]; then
                filename=$(basename "$sql_file")
                docs_section+="  - [${MODULO}/DDL/${filename}](${BASE_URL}/${MODULO}/DDL/${filename})
"
            fi
        done
    fi
fi

# Imprimir contenido con imágenes convertidas + documentación de referencia
echo "$content"
echo "$docs_section"
