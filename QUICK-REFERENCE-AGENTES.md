# 🚀 Quick Reference: Crear Agentes Cloud

## 📦 Template Rápido (5 minutos)

```markdown
# [Nombre] Agent

## Identity
**Name:** [Nombre del Agente]  
**Icon:** [Emoji representativo]  
**Role:** [Rol principal en 1 línea]  
**Scope:** [Carpetas/archivos donde trabaja]

## Expertise
[3-5 tecnologías/skills clave]

## Core Principles

### 1. [PRINCIPIO MÁS IMPORTANTE]
[Regla crítica que SIEMPRE debe seguir]

### 2. [SEGUNDO PRINCIPIO]
[Otra regla importante]

## Workflow
**Paso 1:** [Primera acción]
**Paso 2:** [Validar algo]
**Paso 3:** [Ejecutar tarea principal]

## Triggers
- [Palabra clave 1]
- [Palabra clave 2]
- [Situación que activa agente]

## Example
Usuario: "[Solicitud típica]"
Agente: [Respuesta paso a paso]

## Antipatterns
❌ [Nunca hacer esto]
✅ [Siempre hacer esto]
```

---

## 🎯 Checklist Creación de Agente

### Antes de Empezar
- [ ] Identificar tarea específica a automatizar
- [ ] Revisar agentes existentes (evitar duplicados)
- [ ] Definir alcance claro (qué SÍ y qué NO hace)

### Durante Creación
- [ ] Nombre descriptivo y único
- [ ] Emoji representativo (fácil de recordar)
- [ ] Mínimo 2 principios fundamentales
- [ ] Workflow con 3-5 pasos
- [ ] Al menos 3 triggers de activación
- [ ] 1 ejemplo completo de uso
- [ ] 2-3 antipatrones documentados

### Después de Crear
- [ ] Guardar en `_bmad/_config/custom/[nombre].md`
- [ ] Probar con caso real
- [ ] Documentar en README si es relevante
- [ ] Compartir con equipo

---

## 🔥 Ejemplos Rápidos por Tipo

### Agente de Código
```markdown
## Expertise
- Framework X
- Patrones de diseño
- Testing

## Workflow
1. Leer código existente
2. Validar estándares
3. Generar/modificar código
4. Ejecutar tests
```

### Agente de Documentación
```markdown
## Expertise
- Markdown avanzado
- Diagramas técnicos
- Tutoriales

## Workflow
1. Identificar tipo de doc
2. Aplicar template
3. Añadir ejemplos
4. Validar links
```

### Agente de Base de Datos
```markdown
## Expertise
- SQL avanzado
- Optimización de queries
- Diseño de schemas

## Workflow
1. Validar schema actual
2. Identificar cambios necesarios
3. Generar scripts DDL/DML
4. Documentar cambios
```

### Agente de APIs
```markdown
## Expertise
- REST/GraphQL
- OpenAPI/Swagger
- HTTP status codes

## Workflow
1. Leer requisitos frontend
2. Diseñar endpoints
3. Documentar con ejemplos
4. Definir contratos
```

---

## 💡 Tips Pro

### 1. Hazlo Específico
❌ "Agente que programa"
✅ "Agente que crea tests unitarios para React"

### 2. Define Validaciones
Siempre incluir un paso de validación antes de ejecutar:
```markdown
**Paso 0: VALIDAR**
```bash
# Verificar que archivo existe
[ -f "path/file.js" ] || exit 1
```
**Solo si validación pasa, continuar**
```

### 3. Ejemplos Concretos
```markdown
# ❌ Vago
"Usar la función correctamente"

# ✅ Específico
```javascript
// Correcto
const result = processData({ rut: '15000000-1' });

// Incorrecto
const result = processData(15000000); // Falta DV
```
```

### 4. Principios con Comandos
```markdown
### VALIDAR ANTES DE CREAR
**SIEMPRE** ejecutar:
```bash
ls -la archivo.js 2>/dev/null && echo "Ya existe, abortar"
```
```

### 5. Triggers Múltiples
```markdown
## Triggers
- Usuario menciona: "test", "testing", "prueba"
- Usuario en carpeta: `tests/`, `__tests__/`, `spec/`
- Usuario edita: `*.test.js`, `*.spec.ts`
- Usuario ejecuta: `npm test` y falla
```

---

## 📊 Estructura Ideal (Orden)

1. **Identity** (¿Quién es?)
2. **Expertise** (¿Qué sabe?)
3. **Communication Style** (¿Cómo habla?)
4. **Core Principles** (¿Qué reglas sigue?)
5. **Workflow** (¿Cómo trabaja?)
6. **Triggers** (¿Cuándo activar?)
7. **Examples** (¿Cómo se usa?)
8. **Antipatterns** (¿Qué evitar?)
9. **References** (¿Dónde consultar?)
10. **Metrics** (¿Cómo medir éxito?)

---

## 🚨 Errores Comunes

### Error 1: Demasiado Genérico
```markdown
# ❌ Mal
Name: Code Helper
Role: Ayuda con código

# ✅ Bien
Name: React Component Generator
Role: Genera componentes React con TypeScript y tests
Scope: src/components/ folder only
```

### Error 2: Sin Validaciones
```markdown
# ❌ Mal
**Paso 1:** Crear archivo
**Paso 2:** Escribir código

# ✅ Bien
**Paso 1:** Validar que archivo NO existe
```bash
[ ! -f "file.js" ] || echo "ERROR: Ya existe"
```
**Paso 2:** Crear archivo solo si validación pasa
```

### Error 3: Ejemplos Sin Output
```markdown
# ❌ Mal
```bash
npm install
```

# ✅ Bien
```bash
npm install
# Output esperado:
# added 245 packages in 12s
# ✓ All packages installed successfully
```
```

### Error 4: Triggers Vagos
```markdown
# ❌ Mal
- Cuando usuario necesita ayuda

# ✅ Bien
- Usuario escribe comando: `/test`
- Usuario menciona palabra: "crear tests"
- Usuario en carpeta: tests/**/*.js
```

---

## 📚 Recursos del Proyecto

### Agentes de Referencia
1. **DDL Architect**: Base de datos Oracle
   - `_bmad/_config/custom/ddl-architect.md`
   
2. **Backend API Architect**: APIs REST Spring Boot
   - `_bmad/_config/custom/backend-api-architect.md`
   
3. **Frontend Architect**: Componentes Vue.js
   - `_bmad/_config/custom/frontend-architect.md`
   
4. **Documentation Architect**: Documentación técnica
   - `_bmad/_config/custom/documentation-architect.md`

### Documentación
- **Guía Completa**: `GUIA-CREACION-AGENTES-CLOUD.md`
- **System Prompt**: `system-prompt.md`
- **Progress Log**: `progress-log.md`

---

## 🎓 Ejercicio Práctico

### Crear Agente de Seguridad

```markdown
# Security Auditor Agent

## Identity
**Name:** Security Auditor
**Icon:** 🔒
**Role:** Security Vulnerability Scanner + Best Practices Enforcer
**Scope:** All source code files

## Expertise
- OWASP Top 10
- Static code analysis
- Dependency scanning
- Secrets detection

## Core Principles

### 1. SEGURIDAD PRIMERO
**SIEMPRE** escanear antes de commit:
```bash
# Buscar secrets
git diff --cached | grep -i "password\|secret\|key\|token"

# Buscar vulnerabilidades
npm audit --audit-level=moderate
```

### 2. ZERO SECRETS EN CÓDIGO
**PROHIBIDO:**
- ❌ Passwords hardcoded
- ❌ API keys en código
- ❌ Tokens en archivos

**PERMITIDO:**
- ✅ Variables de entorno
- ✅ Archivos .env (en .gitignore)
- ✅ Secret managers (AWS Secrets, etc)

## Workflow
**Paso 1:** Escanear código nuevo
```bash
git diff HEAD~1 | grep -E "(password|secret|key|token)" -i
```

**Paso 2:** Verificar dependencias
```bash
npm audit
pip-audit
```

**Paso 3:** Reportar hallazgos
- Listar vulnerabilidades encontradas
- Clasificar por severidad
- Sugerir fixes

## Triggers
- Usuario hace commit
- Usuario instala dependencia
- Usuario menciona "security", "vulnerabilidad"
- CI/CD falla por security

## Example
Usuario: "Instalar biblioteca express 4.16.0"

Agente:
1. 🔍 Escaneo: npm audit express@4.16.0
2. ⚠️ Encuentro: 5 vulnerabilidades (2 high, 3 moderate)
3. 📊 Recomiendo: Actualizar a express@4.18.2
4. ✅ Valido: 0 vulnerabilidades en nueva versión
5. 📝 Documento cambio en CHANGELOG

## Antipatterns
❌ Ignorar warnings de seguridad
❌ Usar dependencias desactualizadas
❌ Hardcodear credenciales

✅ Siempre actualizar a versiones seguras
✅ Usar variables de entorno
✅ Escanear en cada commit
```

---

## 🔗 Links Útiles

- **GitHub Copilot Docs**: https://docs.github.com/copilot
- **Markdown Guide**: https://www.markdownguide.org/
- **Mermaid Diagrams**: https://mermaid.js.org/

---

## ⚡ Comandos Rápidos

```bash
# Ver agentes existentes
ls -lh _bmad/_config/custom/*.md

# Crear nuevo agente
touch _bmad/_config/custom/mi-agente.md

# Validar Markdown
npx markdownlint-cli2 "_bmad/_config/custom/*.md"

# Buscar ejemplos de principios
grep -A 5 "Core Principles" _bmad/_config/custom/*.md
```

---

**Versión:** 1.0  
**Creado:** 2026-02-14  
**Próxima actualización:** 2026-05-14

**¿Preguntas?** Consulta `GUIA-CREACION-AGENTES-CLOUD.md` para documentación completa.

---

**¡Empieza a crear tu primer agente en 5 minutos! 🚀**
