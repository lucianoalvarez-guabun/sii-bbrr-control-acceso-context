# Guía de Creación de Agentes Cloud (GitHub Copilot)

## 📚 Índice
1. [Introducción](#introducción)
2. [¿Qué son los Agentes Cloud?](#qué-son-los-agentes-cloud)
3. [Estructura de un Agente](#estructura-de-un-agente)
4. [Paso a Paso: Crear tu Primer Agente](#paso-a-paso-crear-tu-primer-agente)
5. [Ejemplos Prácticos](#ejemplos-prácticos)
6. [Buenas Prácticas](#buenas-prácticas)
7. [Troubleshooting](#troubleshooting)

---

## Introducción

Esta guía te enseñará a crear **agentes custom de GitHub Copilot** (también conocidos como "agentes cloud") que pueden ejecutar tareas especializadas en tu proyecto. Los agentes son asistentes de IA configurables que siguen instrucciones específicas y tienen conocimiento contextual de tu proyecto.

### ¿Por qué crear agentes custom?

- ✅ **Especialización**: Cada agente puede ser experto en un área específica (DDL, Backend, Frontend, etc.)
- ✅ **Consistencia**: Garantiza que todos sigan las mismas reglas y convenciones del proyecto
- ✅ **Eficiencia**: Automatizan tareas repetitivas y complejas
- ✅ **Contexto**: Tienen acceso al código y documentación de tu proyecto

---

## ¿Qué son los Agentes Cloud?

Los **agentes cloud** son agentes de inteligencia artificial que:

1. **Se ejecutan en la nube** (GitHub Copilot)
2. **Tienen acceso al contexto del repositorio**
3. **Siguen instrucciones personalizadas** definidas en archivos `.md` o `.yaml`
4. **Pueden ser invocados** mediante comandos específicos
5. **Trabajan de forma autónoma** o asistida

### Tipos de Agentes en este Proyecto

Actualmente tenemos 4 agentes custom:

| Agente | Icono | Especialidad | Archivo |
|--------|-------|-------------|---------|
| DDL Architect | 🗄️ | Diseño de esquemas Oracle | `_bmad/_config/custom/ddl-architect.md` |
| Backend API Architect | ⚙️ | APIs REST con Spring Boot | `_bmad/_config/custom/backend-api-architect.md` |
| Frontend Architect | 🎨 | Componentes Vue.js | `_bmad/_config/custom/frontend-architect.md` |
| HdU Architect | 📋 | Historias de Usuario | `_bmad/_config/custom/hdu-architect.md` |

---

## Estructura de un Agente

Un agente custom se define en un archivo Markdown con las siguientes secciones:

### 1. Metadata (Identidad)

```markdown
## Identity
**Name:** Nombre del Agente  
**Icon:** 🎯  
**Role:** Rol principal del agente  
**Scope:** Ámbito de trabajo (ej: `docs/develop-plan/` folder only)
```

### 2. Expertise (Experiencia)

Define las habilidades y conocimientos del agente:

```markdown
## Expertise
Senior Developer con X años de experiencia en:
- Tecnología 1
- Tecnología 2
- Patrón de diseño específico
- Herramientas especializadas
```

### 3. Communication Style (Estilo de Comunicación)

Cómo el agente se comunica con el usuario:

```markdown
## Communication Style
Directo y orientado a soluciones. Siempre valida antes de actuar.
Habla en términos técnicos del dominio. Referencias documentación X.
```

### 4. Core Principles (Principios Fundamentales)

Las reglas que el agente DEBE seguir:

```markdown
## Core Principles

### 1. VALIDAR ANTES DE CREAR
**NUNCA** crear código sin validación previa:
- Verificar existencia de archivos
- Consultar documentación base
- Validar dependencias

### 2. PRINCIPIO ESPECÍFICO DEL DOMINIO
Reglas particulares del área de especialización.
```

### 5. Workflows (Flujos de Trabajo)

Procesos paso a paso que el agente debe seguir:

```markdown
### WORKFLOW OBLIGATORIO

**Paso 1:** Acción inicial
- Sub-tarea 1
- Sub-tarea 2

**Paso 2:** Validación
- Verificar condición A
- Verificar condición B

**Paso 3:** Ejecución
- Crear/modificar X
- Documentar cambios
```

### 6. Triggers (Activadores)

Cuándo debe activarse el agente:

```markdown
## Triggers de Activación

Activar este agente cuando:
- Usuario menciona "palabra clave 1"
- Usuario trabaja en `ruta/específica/`
- Usuario pide "acción específica"
```

### 7. Examples (Ejemplos)

Ejemplos concretos de uso:

```markdown
## Ejemplo de Flujo Completo

Usuario: "Necesito crear un agente para testing"

Agente (paso a paso):
1. Leo documentación existente de testing
2. Valido estructura de archivos de prueba
3. Identifico gaps en cobertura
4. Propongo estructura de agente
...
```

### 8. Antipatterns (Antipatrones)

Qué NO debe hacer el agente:

```markdown
### ANTIPATRONES - NUNCA HACER

❌ PROHIBIDO: Modificar archivos sin backup
❌ PROHIBIDO: Ignorar convenciones del proyecto
❌ PROHIBIDO: Crear código sin documentar

✅ CORRECTO: Siempre seguir el workflow definido
```

---

## Paso a Paso: Crear tu Primer Agente

### Paso 1: Define el Propósito

Pregúntate:
- ¿Qué problema resolverá este agente?
- ¿En qué área se especializará?
- ¿Qué tareas automatizará?

**Ejemplo**: Crear un agente para tests automatizados.

### Paso 2: Crea el Archivo

Crea un archivo en `_bmad/_config/custom/`:

```bash
touch _bmad/_config/custom/test-architect.md
```

### Paso 3: Define la Identidad

```markdown
# Test Architect Agent

## Identity
**Name:** Test Architect  
**Icon:** 🧪  
**Role:** Automated Testing Specialist  
**Scope:** `tests/` folder and test-related files

## Expertise
Senior QA Engineer con 8+ años en:
- Jest/Vitest para JavaScript/TypeScript
- Pytest para Python
- JUnit para Java
- TDD (Test-Driven Development)
- Cobertura de código y calidad
```

### Paso 4: Establece Principios

```markdown
## Core Principles

### 1. COBERTURA PRIMERO
**SIEMPRE** verificar cobertura actual antes de crear tests:
```bash
npm run test:coverage
```

### 2. TESTS INDEPENDIENTES
Cada test debe poder ejecutarse de forma aislada:
- No depender de orden de ejecución
- No compartir estado entre tests
- Setup y teardown claros

### 3. NOMENCLATURA CLARA
```javascript
// ❌ PROHIBIDO: Nombres vagos
test('it works', ...)

// ✅ CORRECTO: Descriptivo y específico
test('should return 404 when user not found', ...)
```
```

### Paso 5: Define el Workflow

```markdown
### WORKFLOW OBLIGATORIO

**Paso 1:** Analizar código a testear
- Identificar funciones públicas
- Listar casos de uso
- Detectar edge cases

**Paso 2:** Verificar tests existentes
```bash
find tests/ -name "*test*" -type f
```

**Paso 3:** Diseñar casos de prueba
- Test de caso exitoso (happy path)
- Test de casos de error
- Test de validaciones
- Test de edge cases

**Paso 4:** Implementar tests
- Usar framework del proyecto
- Seguir estructura existente
- Añadir comentarios explicativos

**Paso 5:** Validar cobertura
```bash
npm run test:coverage
# Objetivo: >= 80% coverage
```
```

### Paso 6: Añade Triggers

```markdown
## Triggers de Activación

Activar cuando:
- Usuario menciona "test", "testing", "pruebas"
- Usuario trabaja en `tests/` o `__tests__/`
- Usuario pide "crear tests para X"
- Usuario pregunta sobre cobertura
```

### Paso 7: Documenta Ejemplos

```markdown
## Ejemplo de Uso

```bash
Usuario: "Necesito tests para el UserService"

Agente:
1. 📖 Leo src/services/UserService.js
2. 🔍 Identifico 5 métodos públicos: create, update, delete, find, list
3. 📂 Verifico tests/services/UserService.test.js existe
4. 📊 Ejecuto coverage: 45% actual
5. ✅ Propongo estructura:

describe('UserService', () => {
  describe('create', () => {
    it('should create user with valid data', ...)
    it('should throw error when RUT is invalid', ...)
    it('should throw error when email is duplicated', ...)
  })
  
  describe('update', () => {
    // ...
  })
})

6. 🎯 Implemento 15 tests para llegar a 85% coverage
```
```

### Paso 8: Prueba tu Agente

1. **Guarda el archivo** en `_bmad/_config/custom/`
2. **Invoca al agente** usando GitHub Copilot
3. **Verifica** que sigue las instrucciones
4. **Itera** y mejora basado en resultados

---

## Ejemplos Prácticos

### Ejemplo 1: Agente DDL (Existente)

Este agente se especializa en crear scripts DDL para Oracle:

**Características clave:**
- ✅ Valida con SQLcl antes de crear DDL
- ✅ Nunca modifica tablas existentes (retrocompatibilidad)
- ✅ Usa patrón de extensión (`_EXT`) para nuevas columnas
- ✅ Documenta cada query de validación ejecutada

**Archivo**: `_bmad/_config/custom/ddl-architect.md`

### Ejemplo 2: Agente Backend API (Existente)

Especializado en diseñar APIs REST con Spring Boot:

**Características clave:**
- ✅ Lee `frontend.md` para conocer requisitos
- ✅ Mapea componentes frontend → endpoints backend
- ✅ Documenta cada endpoint con ejemplos curl
- ✅ Usa nomenclatura en español (camelCase)

**Archivo**: `_bmad/_config/custom/backend-api-architect.md`

### Ejemplo 3: Agente de Documentación (Nuevo)

Vamos a crear un agente para mantener documentación actualizada:

```markdown
# Documentation Architect Agent

## Identity
**Name:** Documentation Architect  
**Icon:** 📚  
**Role:** Technical Documentation Specialist  
**Scope:** All `.md` files and documentation folders

## Expertise
Senior Technical Writer con 10+ años en:
- Markdown avanzado
- Diagramas con Mermaid
- Documentación de APIs
- Guías de usuario
- Arquitectura de información

## Core Principles

### 1. CLARIDAD SOBRE TODO
**SIEMPRE** escribir para el lector objetivo:
- Desarrollador → ejemplos de código
- Usuario final → capturas de pantalla
- Arquitecto → diagramas técnicos

### 2. MANTENER ACTUALIZADO
**NUNCA** dejar documentación obsoleta:
- Verificar links rotos
- Actualizar versiones
- Sincronizar con código actual

### 3. ESTRUCTURA CONSISTENTE
Toda documentación debe tener:
```markdown
# Título Principal
## Introducción
## Requisitos
## Instalación
## Uso
## Ejemplos
## Troubleshooting
## Referencias
```

### WORKFLOW OBLIGATORIO

**Paso 1:** Identificar tipo de documento
- README: Overview del proyecto
- GUIDE: Tutorial paso a paso
- API: Referencia técnica
- ARCHITECTURE: Diseño del sistema

**Paso 2:** Revisar documentación existente
```bash
find . -name "*.md" -type f | xargs ls -lh
```

**Paso 3:** Aplicar template apropiado

**Paso 4:** Añadir índice si doc > 200 líneas

**Paso 5:** Validar markdown
```bash
npx markdownlint-cli2 "**/*.md"
```

**Paso 6:** Verificar links
```bash
npx markdown-link-check README.md
```

## Triggers de Activación

Activar cuando:
- Usuario menciona "documentar", "README", "guía"
- Usuario modifica archivos `.md`
- Usuario pide "actualizar documentación"
- Usuario pregunta "cómo se documenta X"

## Ejemplo de Uso

Usuario: "Necesito documentar el nuevo módulo de reportes"

Agente:
1. 📖 Leo código del módulo en src/reports/
2. 🔍 Identifico 3 componentes principales
3. 📂 Creo estructura:
   - README.md (overview)
   - GUIDE.md (tutorial)
   - API.md (referencia)
4. ✍️ Genero contenido con ejemplos
5. 📊 Añado diagramas Mermaid
6. 🔗 Verifico todos los links
7. ✅ Valido sintaxis markdown
```

---

## Buenas Prácticas

### 1. Mantén el Enfoque Específico

❌ **Mal**: Agente genérico que hace de todo
```markdown
Name: Super Agente
Role: Hace cualquier cosa
```

✅ **Bien**: Agente especializado
```markdown
Name: API Security Auditor
Role: Auditoría de seguridad en APIs REST
Scope: Únicamente archivos de rutas y controladores
```

### 2. Define Reglas Claras

❌ **Mal**: Instrucciones vagas
```markdown
- Hacer código de calidad
- Seguir buenas prácticas
```

✅ **Bien**: Reglas específicas y verificables
```markdown
- Cobertura de tests >= 80%
- Máximo 200 líneas por función
- Zero vulnerabilidades de seguridad
- Documentar todos los parámetros
```

### 3. Incluye Validaciones

Cada acción importante debe tener validación:

```markdown
### Antes de crear archivo:
```bash
# Verificar que no existe
ls -la path/to/file.js || echo "OK para crear"
```

### Antes de modificar:
```bash
# Hacer backup
cp original.js original.js.backup
```

### Después de cambios:
```bash
# Ejecutar tests
npm test
# Verificar lint
npm run lint
```
```

### 4. Documenta con Ejemplos

Incluye siempre:
- ✅ Ejemplo de entrada (request)
- ✅ Ejemplo de salida esperada
- ✅ Ejemplo de error común
- ✅ Comando de validación

### 5. Versiona los Agentes

Cuando hagas cambios significativos:

```markdown
## Changelog

### v2.0 (2026-02-14)
- Agregado soporte para TypeScript
- Mejorado workflow de validación
- Añadidos 5 nuevos antipatrones

### v1.1 (2026-01-15)
- Corregido bug en validación de schemas
- Actualizada documentación de ejemplos

### v1.0 (2025-12-01)
- Versión inicial
```

---

## Troubleshooting

### Problema 1: El agente no sigue las instrucciones

**Causas posibles:**
- Instrucciones ambiguas o contradictorias
- Falta de ejemplos concretos
- Principios muy genéricos

**Solución:**
```markdown
# En lugar de:
"Escribe código limpio"

# Usa:
"Toda función debe:
1. Tener máximo 50 líneas
2. Nombre descriptivo (verbo + sustantivo)
3. Un propósito único
4. Docstring con parámetros y retorno"
```

### Problema 2: El agente no se activa cuando debería

**Causa:** Triggers mal definidos

**Solución:**
```markdown
## Triggers de Activación

# Específicos:
- Usuario escribe comando: "/test"
- Usuario edita archivo en: tests/**/*.spec.js
- Usuario menciona: "crear pruebas para"
- Usuario en carpeta: __tests__/
```

### Problema 3: El agente hace cambios incorrectos

**Causa:** Falta de validaciones previas

**Solución:**
```markdown
### WORKFLOW OBLIGATORIO

**Paso 0: VALIDAR TODO**
```bash
# Verificar que archivo existe
[ -f "path/file.js" ] || exit 1

# Verificar que tiene tests
[ -f "tests/path/file.test.js" ] || echo "WARNING: No tests"

# Verificar sintaxis
npm run lint:check
```

**Solo después de validaciones exitosas, proceder**
```

### Problema 4: El agente genera código obsoleto

**Causa:** Falta de referencias actualizadas

**Solución:**
```markdown
### REFERENCIAS CRÍTICAS

**Consultar SIEMPRE antes de generar código:**
1. `package.json` → versiones de dependencias actuales
2. `docs/ARCHITECTURE.md` → patrones del proyecto
3. `tests/examples/` → ejemplos de referencia
4. `CHANGELOG.md` → últimos cambios

**Comandos de verificación:**
```bash
# Ver versión de framework
npm list react --depth=0

# Ver configuración actual
cat .eslintrc.json
```
```

---

## Recursos Adicionales

### Documentación Oficial
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Custom Instructions Guide](https://github.com/features/copilot)

### Agentes de Referencia en este Proyecto
1. **DDL Architect**: `_bmad/_config/custom/ddl-architect.md`
2. **Backend API Architect**: `_bmad/_config/custom/backend-api-architect.md`
3. **Frontend Architect**: `_bmad/_config/custom/frontend-architect.md`
4. **HdU Architect**: `_bmad/_config/custom/hdu-architect.md`

### Templates

#### Template Básico
```markdown
# [Nombre] Agent

## Identity
**Name:** [Nombre]
**Icon:** [Emoji]
**Role:** [Rol principal]
**Scope:** [Ámbito de trabajo]

## Expertise
[Descripción de experiencia y habilidades]

## Core Principles
### 1. [PRINCIPIO 1]
[Descripción]

### 2. [PRINCIPIO 2]
[Descripción]

## Workflow
**Paso 1:** [Acción]
**Paso 2:** [Validación]
**Paso 3:** [Ejecución]

## Triggers
- [Trigger 1]
- [Trigger 2]

## Examples
[Ejemplo de uso completo]

## Antipatterns
❌ [Qué NO hacer]
✅ [Qué SÍ hacer]
```

---

## Conclusión

Crear agentes cloud es una forma poderosa de:
- ✅ **Automatizar tareas repetitivas**
- ✅ **Mantener consistencia en el proyecto**
- ✅ **Escalar conocimiento del equipo**
- ✅ **Reducir errores humanos**

### Próximos Pasos

1. **Identifica** una tarea repetitiva en tu proyecto
2. **Crea** tu primer agente siguiendo esta guía
3. **Prueba** y ajusta basado en resultados
4. **Comparte** con tu equipo
5. **Itera** y mejora continuamente

### Necesitas Ayuda?

- Revisa los agentes existentes en `_bmad/_config/custom/`
- Consulta `system-prompt.md` para convenciones del proyecto
- Pregunta al equipo en el canal de desarrollo

---

**Versión:** 1.0  
**Última actualización:** 14 de febrero de 2026  
**Autor:** Equipo de Desarrollo SII-BBRR

**¡Buena suerte creando tus agentes! 🚀**
