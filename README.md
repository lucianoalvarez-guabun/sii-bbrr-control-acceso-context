# Contexto de Desarrollo - Control de Acceso

Este directorio contiene la documentación técnica, análisis y Historias de Usuario (HdU) del proyecto Control de Acceso.

## Estructura

```
docs/develop-plan/
├── registro-hdu.md              # Registro centralizado de todas las HdU
├── progress-log.md              # Log de progreso del desarrollo
├── system-prompt.md             # Contexto y prompts del sistema
├── sync-to-github-project.sh    # Script de sincronización con GitHub Project
├── VIII-Mantenedor-Grupos/      # Módulo VIII - HdU y documentación
├── V-Mantenedor-Usuarios-Relacionados/
└── [otros módulos]/
```

## Repositorio Separado

Este directorio está gestionado en un **repositorio separado** del proyecto principal:

- **Repo principal (cefio.sii.cl)**: Código fuente del proyecto
- **Repo de contexto (GitHub)**: `git@github.com:lucianoalvarez-guabun/sii-bbrr-control-acceso-context.git`

### ¿Por qué separado?

1. El contexto de desarrollo no debe estar en el repo empresarial
2. Facilita colaboración abierta en análisis y diseño
3. Permite sincronización con herramientas externas (GitHub Projects)
4. Mantiene el historial de decisiones técnicas accesible

## Sincronización con GitHub Project

Las HdU registradas en [registro-hdu.md](registro-hdu.md) se sincronizan automáticamente con el GitHub Project.

### Configuración inicial

```bash
# Exportar token de GitHub
export GITHUB_TOKEN="tu_token_aqui"

# Verificar que jq está instalado (requerido)
brew install jq  # macOS
```

### Sincronizar HdU

```bash
cd docs/develop-plan
./sync-to-github-project.sh
```

El script:
- ✅ Lee `registro-hdu.md`
- ✅ Crea/actualiza issues en GitHub con las HdU
- ✅ Asigna etiquetas según módulo y estado
- ✅ Mantiene sincronización bidireccional

## Workflow de Trabajo

### 1. Cuando otro agente crea/modifica HdU:

```bash
# Desde docs/develop-plan/
git add .
git commit -m "HdU-XXX: Descripción del cambio"
git push origin main

# Sincronizar con GitHub Project
export GITHUB_TOKEN="..."
./sync-to-github-project.sh
```

### 2. Para agregar nueva HdU:

1. Actualizar `registro-hdu.md` con nuevo ID
2. Crear archivo HdU en directorio del módulo
3. Commit y push
4. Ejecutar sync script

## Comandos Útiles

```bash
# Ver estado del repo de contexto
cd docs/develop-plan && git status

# Hacer commit y push
cd docs/develop-plan
git add .
git commit -m "Mensaje descriptivo"
git push

# Verificar remote configurado
cd docs/develop-plan && git remote -v

# Ver último commit
cd docs/develop-plan && git log -1
```

## Notas Importantes

- ⚠️ Este directorio está **excluido** del `.gitignore` del repo principal
- ✅ Tiene su propio `.git` y se gestiona independientemente
- 🔄 Los commits aquí NO afectan al repo principal de cefio.sii.cl
- 📋 Sincronización con GitHub Project es manual (ejecutar script)

## Gestión de Cambios Paralelos

Cuando hay múltiples agentes trabajando:

```bash
# Antes de hacer cambios, obtener últimos cambios
cd docs/develop-plan && git pull origin main

# Después de hacer cambios
git add .
git commit -m "Descripción"
git push origin main
```

## GitHub Project

URL del proyecto: [agile-board-bbrr-control-acceso](https://github.com/lucianoalvarez-guabun/Projects/agile-board-bbrr-control-acceso)

Las HdU se sincronizan como **issues** con las siguientes etiquetas:
- `HdU`: Todas las historias de usuario
- `Módulo-{N}`: Según el módulo (VIII, V, VI, etc.)
- `done` / `in-progress` / `backlog`: Según estado

## Mantenimiento

- Última sincronización: [Ejecutar script para actualizar]
- Total HdU registradas: Ver [registro-hdu.md](registro-hdu.md)
- Próximo ID disponible: HdU-009
