#!/bin/bash

# convert-image-urls.sh
# Helper para convertir rutas relativas de imágenes a URLs absolutas de GitHub
# 
# Uso: convert-image-urls.sh <archivo_hdu> <modulo>
# Ejemplo: convert-image-urls.sh HdU-009-Buscar-Usuario.md V-Mantenedor-Usuarios-Relacionados

set -e

REPO_OWNER="lucianoalvarez-guabun"
REPO_NAME="sii-bbrr-control-acceso-context"
BRANCH="main"

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

# Convertir rutas relativas a URLs de GitHub
# Patrones a convertir:
# - ![desc](./images/image-0027.png) → ![desc](https://github.com/.../main/MODULE/images/image-0027.png)
# - ![image-0027](./images/image-0027.png) → ![image-0027](https://github.com/.../main/MODULE/images/image-0027.png)

sed -E "s|\!\[([^]]*)\]\(\./images/([^)]+)\)|![\\1](https://github.com/${REPO_OWNER}/${REPO_NAME}/blob/${BRANCH}/${MODULO}/images/\\2)|g" "$HDU_FILE"
