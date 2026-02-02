# System Prompt - Plan de Desarrollo por Módulo

## Objetivo
Crear un plan de desarrollo detallado para cada módulo funcional del Sistema Control de Acceso de Avaluaciones (SCAA), especificando frontend, backend APIs y cambios en el modelo de datos.

## Módulos a Desarrollar
Solo los módulos funcionales (excluir introducción, requerimientos generales):
- V. Mantenedor de Usuarios Relacionados
- VI. Mantenedor de Unidades de Negocio
- VII. Mantenedor de Funciones
- VIII. Mantenedor de Grupos
- IX. Mantenedor de Alcance
- X. Mantenedor de Atribuciones
- XI. Mantenedor de Opciones
- XII. Mantenedor de Cargos
- XIII. Mantenedor de Tipo de Unidad
- XIV. Reportes
- XV. Servicios Distintas Arquitecturas

## Estructura por Módulo
```
docs/develop-plan/
├── [Nombre-Módulo]/
│   ├── README.md (especificación del módulo)
│   ├── frontend.md (componentes para acaj-intra-ui)
│   ├── backend-apis.md (endpoints para acaj-ms)
│   ├── DDL/
│   │   ├── create-tables.sql (nuevas tablas)
│   │   └── alter-tables.sql (modificaciones)
│   └── HdU-[functionality-name].md (historias de usuario)
├── progress-log.md
└── system-prompt.md
```

## Contenido por Archivo

### README.md
- Descripción del módulo
- Objetivos funcionales
- Alcance
- Referencias a docs/PHASE-03-design.md

### frontend.md

**ENFOQUE:** Especificación funcional para frontend developer, NO manual de implementación.

**CONTENIDO REQUERIDO:**

1. **Stack Tecnológico Base:**
   - Framework: Vue 3 + Composition API (acaj-intra-ui existente)
   - UI: Bootstrap 5.2 + Bootstrap Icons
   - State: Vuex 4.1
   - HTTP: Axios con interceptores

2. **Análisis de Imágenes (Mockups):**
   - **PRECISIÓN CRÍTICA:** Describir EXACTAMENTE lo que se ve en la imagen, NO asumir
   - Tabla con número de imagen, descripción visual DETALLADA, propósito funcional
   - **Incluir imágenes reales:** Usar `![descripción](./images/image-XXXX.png)`
   - NO solo referenciar como texto "image-0025.png", sino incluir la imagen con sintaxis Markdown
   - Identificar componentes visuales (SearchBar, Card, Modal, Form, etc)
   - **Ejemplo descripción CORRECTA (detallada):**
     - ❌ "Pantalla con búsqueda de usuario"
     - ✅ "Header verde 'Control de Acceso' con logo puerta izq, info usuario derecha (RUT 15000000-1), tabs horizontal: Usuario relacionado (activa), Unidad de negocio, Funciones, Mantenedores (dropdown). Debajo: SearchBar con input 'Ingrese RUT:', botón lupa, botón verde 'Agregar', icono reloj historial"
   - **INCLUIR en secciones de componentes:**
     ```markdown
     ### 2.2 SearchBar Component
     
     **Imagen Referencia:**
     
     ![SearchBar inicial](./images/image-0027.png)
     
     **Funcionalidad:**
     - Input RUT...
     ```
   - NO escribir código Vue, solo describir QUÉ se ve y QUÉ hace

3. **Mapeo Componentes → APIs:**
   - Tabla: Componente | Acción Usuario | API Endpoint | Método | Respuesta Esperada
   - Ejemplo: `SearchBar | Buscar por RUT | GET /buscar?rut={rut} | 200: Usuario encontrado / 404: No existe`

4. **Flujos de Usuario:**
   - Secuencia paso a paso de interacciones
   - **INCLUIR imágenes de pantallas principales** (SearchBar, Cards, Forms, Tablas)
   - **NO incluir imágenes de alertas/modales genéricos** (SuccessAlert, ErrorAlert, ConfirmDialog)
   - Solo MENCIONAR mensajes específicos: "mostrar alerta: Cargo eliminado correctamente"
   - Validaciones frontend (formato, obligatorios, rangos)
   - Estados de loading, error, éxito
   - Navegación entre vistas

5. **Estructura de Vistas:**
   - Rutas principales (`/usuarios-relacionados`)
   - Componentes reutilizables identificados
   - Estado global Vuex requerido

**LO QUE NO DEBE INCLUIR:**
- ❌ Código Vue completo (script setup, template, style)
- ❌ Implementación de validadores o composables
- ❌ Configuración de Vuex/Pinia/Redux store (acciones, mutations, getters)
- ❌ Especificaciones de "Estado Global" o "Estado Requerido" con código JavaScript
- ❌ Configuración de Axios interceptors
- ❌ Diagramas ASCII de layouts
- ❌ CSS o estilos específicos
- ❌ **Emojis** (usar texto plano solamente)

**OBJETIVO:** Que un frontend developer entienda QUÉ construir, QUÉ APIs consumir y QUÉ flujos implementar, sin prescribir CÓMO escribir el código o gestionar el estado.

**ANÁLISIS CONTEXTUAL DE IMÁGENES (CRÍTICO):**

ANTES de crear frontend.md o HdU, DEBES:
1. **Leer tmp/Requerimineto-Control-Acceso-2/output/requeriments.md** completo del módulo
2. **Para cada imagen PNG referenciada** (image-0025, image-0027, etc):
   - Leer el texto ANTES de `![Imagen X](images/image-XXXX.png)`
   - Leer el texto DESPUÉS de la imagen
   - Determinar QUÉ pantalla/componente representa (búsqueda, formulario, detalle, alerta, etc)
   - Documentar el contexto: "image-0027 = Pantalla de búsqueda/resultado usuario"
3. **Crear tabla de mapeo** en frontend.md explicando cada imagen
4. **Usar contexto para nombrar secciones** correctamente
   - NO asumir que image-0027 es "formulario crear" solo por el nombre
   - Leer especificación para saber QUÉ es image-0027

**Ejemplo Correcto:**
```
Especificación dice: "Para agregar... se debe presionar botón agregar... imagen siguiente:"
→ image-0025 representa: Formulario CREATE vacío
Especificación dice: "El sistema despliega información del usuario... imagen siguiente:"
→ image-0027 representa: Pantalla de BÚSQUEDA/RESULTADO
```

**RESTRICCIÓN - DIAGRAMAS Y ESPECIFICACIONES:**

- ❌ **NO usar diagramas ASCII** para especificar formularios o UI
- ❌ **NO usar tablas ASCII** para describir campos o layouts
- ❌ **NO usar emojis** en documentación técnica
- ✅ **SÍ usar imágenes PNG** del mockup de requerimientos
  - Las imágenes PNG están en la carpeta del módulo: `./image-XXXX.png` o `./images/image-XXXX.png`
  - Cada imagen representa una vista o formulario específico
  - ANTES de referenciar, analizar contexto en requerimientos.md
  - **Incluir imagen real con Markdown:** `![Mockup: Pantalla de Búsqueda](./image-0027.png)` (nombre consistente con análisis)
  - **NO solo texto:** Evitar referenciar como "image-0027.png" sin incluir la imagen
  - Las imágenes son la FUENTE DE VERDAD para diseño y disposición de componentes

**IMPORTANTE - CAMPOS Y ATRIBUTOS:**

- **TODOS los campos** del formulario deben ser:
  1. Parte de las tablas nuevas (creadas en DDL/create-tables.sql), O
  2. Parte de las tablas preexistentes en Oracle AVAL
  3. **VERIFICADO y DOCUMENTADO** en backend-apis.md con exactamente los mismos nombres
- **Mapeo Requerido:**
  - Frontend → muestra campo X con tipo Y
  - Backend APIs → endpoint POST/PUT recibe y valida campo X
  - BD Oracle → tabla T contiene columna X con tipo correspondiente
  - Documentar esta trazabilidad en las secciones de "Campos del Formulario"

### backend-apis.md
**ESPECIFICACIONES CRÍTICAS:**

1. **IDIOMA**: Español (nombres de campos, descripciones, comentarios)

2. **RUTA OBLIGATORIA DEL RUT**: Todas las APIs deben incluir el RUT del usuario autenticado en la ruta
   - Formato: `/{rut}-{dv}/` donde rut incluye puntos, dv es dígito verificador
   - Ejemplo: `/12345678-9/`
   - Debe ser el primer segmento después de `/api/v1/`

3. **Estructura Base de URLs:**
   ```
   GET    /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados
   POST   /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados
   GET    /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados/{id}
   PUT    /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados/{id}
   DELETE /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados/{id}
   ```

4. **Contenido:**
   - Endpoints REST para `backend/acaj-ms`
   - Base URL: `/acaj-ms/api/v1/`
   - Métodos HTTP (GET, POST, PUT, DELETE)
   - Request/Response payloads (EN ESPAÑOL)
   - Validaciones de negocio
   - Códigos HTTP (200, 201, 400, 403, 404, 409, 500)

5. **REGLAS DE CONTENIDO (REFINADAS):**
   - ❌ NO incluir sección "Información General" al inicio
   - ❌ NO incluir secciones "Headers Requeridos" ni "Rate Limiting"  
   - ❌ NO incluir secciones "Lógica Backend" con código SQL detallado completo
   - ✅ SÍ incluir "Tips de SQL" breves (3-5 líneas comentadas) para operaciones complejas
   - ✅ SÍ incluir tabla "Mapeo Frontend/Backend" (renombrar desde "Coherencia Frontend ↔ Backend ↔ BD")
   - ✅ SÍ incluir sección "Validaciones de Negocio" con queries SQL de validación
   - ✅ SÍ incluir "Códigos de Estado HTTP" con tabla de referencia
   - ✅ SÍ incluir secciones Auditoría, Paginación, Seguridad, Testing

### DDL/

**FORMATO DE ENCABEZADO:**
```sql
-- ===========================================================================
-- Script de Creación de Tablas - Módulo X: Nombre del Módulo
-- ===========================================================================
-- Proyecto: Control de Acceso SII
-- Schema: AVAL
-- Base de Datos: Oracle 19c (queilen.sii.cl:1540/koala)
--
-- CRITICAL: Este DDL crea/modifica tablas según análisis previo
-- ===========================================================================
```

**RESTRICCIÓN CRÍTICA - SOLO TABLAS, ÍNDICES Y LLAVES:**

El DDL debe contener **ÚNICAMENTE**:
- ✅ `CREATE TABLE` (solo tablas nuevas)
- ✅ `ALTER TABLE` (solo agregar columnas nuevas, keys nuevas)
- ✅ `CREATE INDEX` (índices nuevos para optimización)
- ✅ `ALTER TABLE ... ADD CONSTRAINT` (foreign keys, check constraints, unique constraints)
- ✅ `CREATE SEQUENCE` (secuencias para IDs)

**PROHIBIDO - NO INCLUIR BAJO NINGUNA CIRCUNSTANCIA:**
- ❌ Stored Procedures (`CREATE PROCEDURE`)
- ❌ Views (`CREATE VIEW`)
- ❌ Triggers (`CREATE TRIGGER`)
- ❌ Functions (`CREATE FUNCTION`)
- ❌ Packages
- ❌ Grants y permisos
- ❌ DROP statements
- ❌ Procedimientos de auditoría automática

**Si NO hay cambios en BD:** El archivo DDL puede estar vacío o contener solo comentarios indicando "Sin cambios en modelo de datos".

**Validación:**

1. **Verificación del Modelo Actual:**
   - Usar SQLcl 25.3 con datos de conexión: `backend/acaj-ms/src/main/resources/application.properties`
   - Conexión: `sql intbrprod/Avalexpl@//queilen.sii.cl:1540/koala`
   - Schema: AVAL
   - Verificar tablas existentes antes de crear

2. **Qué Incluir:**
   - `CREATE TABLE` solo para tablas NUEVAS
   - `ALTER TABLE` solo para MODIFICACIONES a tablas existentes (nuevas columnas, nuevas constraints)
   - Índices solo donde sea necesario para optimización
   - Foreign keys válidas apuntando a tablas existentes
   - NO incluir definiciones de tablas actuales
   - NO incluir DROP statements
   - NO incluir SP, Views, Triggers u otros elementos compilados

3. **Validación:**
   - Todos los scripts deben ser validados con SQLcl
   - Sintaxis correcta (no copiada de otros sistemas)
   - Constraints consistentes con el modelo existente
   - Foreign keys válidas
   - Índices optimizados para búsquedas frecuentes

### HdU-*.md

**ENFOQUE:** Historias de Usuario funcionales, NO especificaciones técnicas.

**CONTENIDO REQUERIDO:**

1. **Información General:**
   - ID (HdU-001, HdU-002, etc)
   - Módulo
   - Prioridad (Alta, Media, Baja)
   - Estimación (puntos de historia)

2. **Historia de Usuario:**
   - Formato: Como [actor], Quiero [acción], Para [beneficio]
   - Debe ser comprensible para usuarios de negocio

3. **Mockups de Referencia:**
   - Listar imágenes PNG relevantes (image-0027.png, image-0135.png)
   - Breve descripción de cada mockup

4. **Criterios de Aceptación:**
   - AC-001, AC-002, etc
   - Comportamiento esperado del sistema
   - Validaciones de negocio (NO implementación técnica)
   - Mensajes de error/éxito
   - Estados del sistema

5. **Flujos Principales:**
   - Secuencia paso a paso desde perspectiva del usuario
   - **INCLUIR IMÁGENES VISUALES** en cada flujo usando `![descripción](./images/image-XXXX.png)`
   - Mostrar pantallas ANTES de describir acciones sobre ellas
   - **PROHIBIDO incluir imágenes de alertas/modales genéricos:**
     - ❌ NO incluir imágenes de SuccessAlert, ErrorAlert, ConfirmDialog
     - ❌ NO incluir imágenes de mensajes "Registro guardado correctamente"
     - ✅ SÍ usar imágenes de pantallas principales (SearchBar, Cards, Forms, Tablas)
     - ✅ SÍ indicar mensajes específicos en TEXTO: "mostrar alerta: Usuario eliminado correctamente"
   - Ejemplo CORRECTO:
     ```markdown
     1. Usuario abre pantalla inicial
     2. Sistema muestra SearchBar vacío:
     
     ![SearchBar inicial](./images/image-0027.png)
     
     3. Usuario ingresa RUT...
     4. Usuario presiona botón lupa
     5. Sistema muestra resultado:
     
     ![Usuario encontrado](./images/image-0025.png)
     
     6. Usuario hace clic en eliminar
     7. Sistema muestra alerta "Usuario eliminado correctamente"
     ```
   - Flujo principal (happy path)
   - Flujos alternativos (errores, cancelaciones)
   - NO incluir código, solo acciones del usuario y respuestas del sistema con imágenes de referencia

6. **Notas Técnicas (Descriptivas):**
   - API consumida (endpoint, método HTTP)
   - Validaciones backend (descripción, NO código)
   - Tablas BD afectadas (operación: INSERT/UPDATE/DELETE)
   - Secuencias utilizadas (si aplica)

7. **Dependencias:**
   - Funcionales solamente (otros módulos, datos maestros)

8. **Glosario:**
   - Definiciones de términos de negocio

**LO QUE NO DEBE INCLUIR:**
- ❌ **Código fuente** (JavaScript, Java, SQL, etc)
- ❌ **Bloques de código** (```javascript, ```java, ```sql)
- ❌ **Implementación técnica** (funciones, clases, queries)
- ❌ **Configuraciones** (Redux, Spring Boot, DTO)
- ❌ **Tests** (Vitest, JUnit, Mockito)
- ❌ **Diagramas ASCII** para describir procesos o campos
- ❌ **Tablas ASCII** para listar campos o validaciones
- ❌ **Referencias técnicas específicas** (librerías, frameworks)
- ❌ **Emojis**

**OBJETIVO:** Que un analista de negocio o PO entienda QUÉ hace la funcionalidad, sin necesitar conocimientos técnicos.

**RESTRICCIÓN - DOCUMENTACIÓN EN HdU:**

- ✅ **SÍ usar imágenes PNG** del mockup cuando sea relevante
- ✅ **SÍ referenciar backend-apis.md** para detalles de campos/validaciones
- **Campos en Criterios de Aceptación:**
  - Deben coincidir exactamente con nombres en backend-apis.md
  - Deben coincidir con columnas en tablas Oracle AVAL
  - Incluir trazabilidad: "Campo X (BD: tabla.columna, API: POST body.campo)"

## Conexión Base de Datos (para validar modelo)

**SQLcl 25.3 (instalado)**

```
Conexión BBRR KOALA:
- Host: queilen.sii.cl
- Puerto: 1540
- Servicio: koala
- Usuario: intbrprod
- Password: Avalexpl
- Driver: Oracle Thin
- Schema: AVAL

Comando de conexión:
sql intbrprod/Avalexpl@//queilen.sii.cl:1540/koala

Validaciones a realizar:
- Tablas existentes: BR_RELACIONADOS, BR_UNIDADES_NEGOCIO, BR_CARGOS, 
  BR_FUNCIONES, BR_OPCIONES, BR_GRUPOS, BR_JURISDICCIONES, BR_TITULOS
- Estructura actual de campos y tipos
- Constraints e índices
- Secuencias disponibles
- Foreign keys
```

## FLUJO DE TRABAJO PARA CADA MÓDULO - MODULARIZACIÓN + IMÁGENES

### Paso 0: Modularización Automática (PREVIO - Ejecutar Yo)

**Objetivo:** Preparar la estructura y recursos del módulo ANTES de que usuario proporcione imágenes.

#### 0.1 Extraer Especificación del Módulo
1. Leer `tmp/Requerimineto-Control-Acceso-2/output/requeriments.md`
2. Localizar sección del módulo (ej: "## VI. MÓDULO MANTENEDOR DE UNIDADES DE NEGOCIO")
3. Extraer texto desde encabezado hasta siguiente módulo (sección ##)
4. Guardar especificación en variable para referencia

#### 0.2 Crear Estructura de Carpetas
```bash
mkdir -p docs/develop-plan/[Nombre-Módulo]/DDL/
```

Donde `[Nombre-Módulo]` sigue formato: `VI-Mantenedor-Unidades-Negocio`

#### 0.3 Identificar y Extraer Imágenes del Módulo
1. Buscar todas las referencias `![Imagen XX](images/image-XXXX.png)` en la sección del módulo
2. Extraer lista de image-XXXX.png asociadas a este módulo
3. Copiar desde `tmp/Requerimineto-Control-Acceso-2/output/images/image-XXXX.png` → `docs/develop-plan/[Módulo]/image-XXXX.png`
4. Crear tabla de mapeo: `image-XXXX.png → contexto en requerimientos`

**Ejemplo para Módulo VI:**
```
Imágenes encontradas:
- image-0029: Pantalla búsqueda unidad negocio
- image-0030: Formulario crear unidad
- image-0031: Sección cargos/funciones unidad
- image-0032: Alerta éxito grabado
```

#### 0.4 Crear README.md Inicial
Crear `docs/develop-plan/[Módulo]/README.md` con estructura:

```markdown
# [Nombre Módulo Completo]

## 1. Especificación

[Texto completo del módulo desde requerimientos.md]

## 2. Imágenes de Referencia

| Imagen | Ubicación | Contexto (Pendiente Análisis) |
|--------|-----------|------|
| image-0029 | ./image-0029.png | Pantalla inicial/búsqueda (verificar) |
| image-0030 | ./image-0030.png | Formulario crear (verificar) |
| image-0031 | ./image-0031.png | Sección detalles (verificar) |

## 3. Estructura de Archivos

- **frontend.md** - Componentes React (pendiente)
- **backend-apis.md** - Endpoints REST (pendiente)
- **HdU-*.md** - Historias de usuario (pendiente)
- **DDL/** - Scripts SQL (pendiente)
  - create-tables.sql
  - alter-tables.sql

## 4. Estado

- [x] Carpeta y archivos creados
- [ ] Imágenes extraídas y analizadas
- [ ] frontend.md finalizado
- [ ] backend-apis.md finalizado
- [ ] HdU-*.md finalizado
- [ ] DDL finalizado
```

#### 0.5 Crear Plantilla de Checklist en progress-log.md
Agregar entrada:
```markdown
### VI. Mantenedor de Unidades de Negocio

**Estado:** Modularización completada ✓

**Archivos Creados:**
- [x] docs/develop-plan/VI-Mantenedor-Unidades-Negocio/
- [x] README.md (especificación + tabla imágenes)
- [x] image-0029.png, image-0030.png, image-0031.png, image-0032.png
- [ ] Análisis contextual imágenes (pendiente usuario)
- [ ] frontend.md (pendiente)
- [ ] backend-apis.md (pendiente)
- [ ] HdU-*.md (pendiente)
- [ ] DDL/ (pendiente)

**Próximo Paso:** Usuario adjunta imágenes por chat → inicio Paso 1
```

---

### Paso 1: Usuario Proporciona Imágenes (Por Chat)

El usuario adjunta las imágenes PNG de mockups para el módulo actual. Estas imágenes:
- Son la **FUENTE DE VERDAD** para diseño UI
- Serán guardadas en la carpeta del módulo: `docs/develop-plan/[Módulo]/image-XXXX.png`
- Se usarán como referencia visual directa al crear frontend.md y HdU

### Paso 2: Análisis Contextual de Imágenes

Para cada imagen adjuntada:
1. **Leer el texto de requerimientos** que describe la imagen
   - Buscar en `tmp/Requerimineto-Control-Acceso-2/output/requeriments.md`
   - Leer párrafos ANTES y DESPUÉS de cada `![](image-XXXX.png)`
2. **Determinar el tipo de pantalla/componente:**
   - ¿Es búsqueda? ¿Formulario? ¿Detalle? ¿Alerta? ¿Resultado?
   - Documentar el propósito exacto
3. **Extraer campos visibles:**
   - RUT, Email, Nombre, etc.
   - Determinar si son editables o read-only
   - Notar botones de acción
4. **Mapear a tablas Oracle AVAL:**
   - Campo "RUT" → tabla BR_RELACIONADOS columna RELA_RUT
   - Campo "Email" → tabla BR_RELACIONADOS columna RELA_CORREO
   - Crear tabla de coherencia: Image → Frontend → Backend API → BD Oracle

### Paso 3: Refinar frontend.md Basado en Imágenes

- Referenciar cada imagen como: `![Descripción](./image-XXXX.png)`
- **Sección de Mapeo de Imágenes:**
  ```
  | Imagen | Componente | Descripción |
  |--------|-----------|-------------|
  | image-0025 | UserDetailCard | Muestra datos usuario encontrado |
  | image-0027 | SearchBar | Pantalla inicial búsqueda |
  ```
- Cada componente debe tener:
  - Referencia a imagen que lo muestra
  - Campos exactos visibles en imagen
  - Validaciones necesarias
  - Botones de acción

### Paso 4: Refinar HdU Basado en Imágenes

- Criterios de Aceptación (AC) deben:
  - Referenciar la imagen correspondiente: `(Ver image-0025)`
  - Listar campos exactos del mockup
  - Especificar comportamiento esperado
  - Incluir flujo visual: "Usuario ve image-0027 → presiona X → ve image-0028"

### Paso 5: VALIDACIÓN DE APIs - Coherencia Frontend ↔ Backend ↔ BD

**CRÍTICO:** Después de crear frontend.md y backend-apis.md, VALIDAR:

1. **Tabla de Coherencia (crear en backend-apis.md):**
   ```
   | Frontend Campo | API Endpoint | API Param | BD Tabla | BD Columna | Tipo | Validación |
   |---|---|---|---|---|---|---|
   | RUT Input | POST /crear | body.rut | BR_RELACIONADOS | RELA_RUT | VARCHAR2(12) | XX.XXX.XXX-X, módulo 11 |
   | Email Input | POST /crear | body.correo | BR_RELACIONADOS | RELA_CORREO | VARCHAR2(100) | RFC 5322, único |
   | Botón Guardar | POST /acaj-ms/api/v1/{rut}-{dv}/crear | — | — | — | — | Transacción atómica |
   ```

2. **Validaciones Requeridas por Campo:**
   - ✓ Si frontend pide campo X editable, API debe aceptarlo (POST/PUT)
   - ✓ Si frontend muestra campo X read-only, API **NO** debe permitir modificarlo
   - ✓ Si frontend requiere validar formato (RUT, email), backend debe revalidar
   - ✓ Si API guarda en tabla T columna C, table.column DEBE existir en Oracle AVAL

3. **Operaciones Necesarias Validar:**
   - **CREATE:** ¿Qué tabla/s se insert-an? ¿Hay transacción? ¿Se audita?
   - **READ:** ¿Qué tabla/s se consultan? ¿Hay índice para performance?
   - **UPDATE:** ¿Qué columna/s se actualizan? ¿Cuáles son read-only?
   - **DELETE:** ¿Se elimina físicamente o marca inactivo (soft-delete)?

4. **Validar en SQLcl (si aplica):**
   ```sql
   -- Verificar que tabla existe
   SELECT * FROM user_tables WHERE table_name = 'BR_RELACIONADOS';
   
   -- Verificar columna existe
   SELECT column_name, data_type FROM user_tab_columns 
   WHERE table_name = 'BR_RELACIONADOS' AND column_name = 'RELA_CORREO';
   
   -- Verificar índice para búsquedas
   SELECT * FROM user_indexes WHERE table_name = 'BR_RELACIONADOS';
   ```

5. **Matriz de Validación (incluir en backend-apis.md):**
   ```
   ✓ Todos los campos del formulario existen en BD
   ✓ Tipos de datos coinciden (string/email/date)
   ✓ Campos read-only NO se aceptan en PUT/POST
   ✓ Validaciones en API coinciden con tipo BD
   ✓ Foreign keys son válidas
   ✓ Operaciones tienen sentido de negocio
   ✓ Sin campos innecesarios
   ```

### Paso 6: Crear DDL/create-tables.sql

- Solo si hay **NUEVAS** tablas o cambios necesarios
- Validar que tabla/columna NO existe ya en Oracle AVAL
- Si tabla ya existe: No incluir en create-tables.sql, solo en alter-tables.sql

### Paso 7: Documentar Coherencia en README.md

Agregar sección "Validación de Coherencia":
```
## Validación de Coherencia Frontend-Backend-BD

### Mapeo de Componentes a Imágenes
- image-0025: UserDetailCard muestra usuario encontrado
- image-0027: SearchBar estado inicial

### Mapeo de Campos (Frontend → Backend → BD)
- RUT Input (Frontend) → POST /crear body.rut (Backend) → BR_RELACIONADOS.RELA_RUT (BD)
- Email Input (Frontend, read-only si Interno) → PUT /actualizar body.correo (Backend) → BR_RELACIONADOS.RELA_CORREO (BD)

### Operaciones Validadas
- CREATE usuario: INSERT en BR_RELACIONADOS + BR_CARGOS_RELACIONADOS + BR_FUNCIONES_RELACIONADOS
- READ usuario: SELECT desde BR_RELACIONADOS + JOINs
- UPDATE vigencias: UPDATE BR_CARGOS_RELACIONADOS + BR_FUNCIONES_RELACIONADOS
- DELETE (soft): UPDATE BR_RELACIONADOS SET estado = 'I'

### Validación en BD
- [x] Todas las tablas existen en Oracle AVAL
- [x] Todas las columnas tienen tipos correctos
- [x] Foreign keys son válidas
- [x] Sin columnas innecesarias
```

## Proceso Completo

1. ✅ Leer datos de conexión en `backend/acaj-ms/src/main/resources/application.properties`
2. ✅ Conectar con SQLcl y validar modelo existente
3. ✅ Revisar `docs/PHASE-03-design.md` para especificaciones nuevas

4. 🔄 **Para cada módulo - FLUJO COMPLETO:**

   **FASE 1: MODULARIZACIÓN AUTOMÁTICA (Yo)**
   - Paso 0.1: Extraer especificación del módulo de requeriments.md
   - Paso 0.2: Crear carpeta `docs/develop-plan/[Módulo]/`
   - Paso 0.3: Extraer imágenes PNG asociadas a la carpeta
   - Paso 0.4: Crear README.md inicial con especificación + tabla imágenes
   - Paso 0.5: Actualizar progress-log.md
   - ✅ **Notificar:** "Módulo VI preparado, carpeta y imágenes listas"

   **FASE 2: ANÁLISIS Y REFINAMIENTO (Tú + Yo)**
   - Paso 1: **Usuario adjunta imágenes PNG** (por chat, confirmar que están en carpeta)
   - Paso 2: Realizar **análisis contextual** de imágenes (leo requerimientos + extraigo campos)
   - Paso 3: Generar **frontend.md** referenciando imágenes
   - Paso 4: Generar **HdU-*.md** con imágenes en criterios de aceptación
   - Paso 5: **VALIDAR coherencia Frontend ↔ Backend ↔ BD**
   - Paso 6: Generar DDL/ con scripts SQL validados
   - Paso 7: Documentar coherencia en README.md
   - ✅ **Notificar:** "Módulo VI completado y validado"

5. ⏳ Actualizar progress-log.md al finalizar cada módulo

## Referencias
- Especificación: `tmp/Requerimineto-Control-Acceso-2/output/requeriments.md`
- Diseño: `docs/PHASE-03-design.md`
- Frontend: `frontend/acaj-intra-ui`
- Backend: `backend/acaj-ms` (context-path: `/acaj-ms`)
- Conexión BD: intbrprod/Avalexpl@queilen.sii.cl:1540/koala (Schema: AVAL)
- Modelo SQL: Validar con `sql` (SQLcl 25.3)
