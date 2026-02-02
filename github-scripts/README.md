# GitHub Scripts para Control de Acceso

Scripts para gestionar issues de HdU en GitHub Project.

## Scripts Disponibles

### Crear Issues

#### `create-hdu-issue.sh` - Crear un solo issue
Crea un issue individual con épica.

```bash
./create-hdu-issue.sh <HdU-ID> <archivo.md> <épica>
```

**Ejemplo:**
```bash
./create-hdu-issue.sh HdU-001 HdU-001-Crear-Grupo.md "VIII-Mantenedor-Grupos"
```

#### `create-all-hdus.sh` - Crear todos los issues
Crea todos los issues desde `registro-hdu.md` con épica en el cuerpo.

```bash
./create-all-hdus.sh
```

### Limpiar Issues

#### `close-all-issues.sh` - Cerrar todos los issues
Cierra todos los issues abiertos del repositorio.

```bash
./close-all-issues.sh
```

⚠️ **Nota:** GitHub no permite ELIMINAR issues por API, solo cerrarlos.

### Scripts Legacy (referencia)

Los siguientes scripts se mantienen como referencia de iteraciones anteriores:

- `sync-to-github-project.sh` - Primera versión con epics como issues
- `sync-with-project-field.sh` - Intento con campo épica en body
- `sync-final.sh` - Script completo con GraphQL (requiere permisos project)
- `sync-simple.sh` - Versión simplificada sin GraphQL
- `cleanup-epics.sh` - Limpieza de epics duplicados
- `delete-all-issues.sh` - Primera versión de limpieza

## Configuración

### Token de GitHub

Configura tu token de GitHub:
```bash
export GITHUB_TOKEN="tu_token_aqui"
```

O pásalo como parámetro al script.

### Proyecto GitHub

- **Repositorio:** `lucianoalvarez-guabun/sii-bbrr-control-acceso-context`
- **Proyecto:** #2 "agile-board-bbrr-control-acceso"
- **URL:** https://github.com/users/lucianoalvarez-guabun/projects/2

## Flujo de Trabajo

### 1. Limpiar issues existentes
```bash
./close-all-issues.sh
```

### 2. Crear todos los issues nuevos
```bash
./create-all-hdus.sh
```

### 3. Configurar en GitHub Project

1. Abre https://github.com/users/lucianoalvarez-guabun/projects/2
2. Agrega los issues al proyecto (botón "+ Add items")
3. Configura el campo "epica" para cada issue (está en el cuerpo del issue)

## Estructura de Épicas

| Módulo | Épica |
|--------|-------|
| V | V-Mantenedor-Usuarios-Relacionados |
| VI | VI-Mantenedor-Unidades-Negocio |
| VII | VII-Mantenedor-Funciones |
| VIII | VIII-Mantenedor-Grupos |
| IX | IX-Mantenedor-Alcance |
| X | X-Mantenedor-Atribuciones |
| XI | XI-Mantenedor-Opciones |
| XII | XII-Mantenedor-Cargos |
| XIII | XIII-Mantenedor-Tipo-Unidad |
| XIV | XIV-Reportes |
| XV | XV-Servicios-Distintas-Arquitecturas |

## Requisitos

- `bash` (zsh compatible)
- `curl`
- `jq` (JSON processor)
- Token de GitHub con permisos `repo`
