# Módulo V: Mantenedor de Usuarios Relacionados

## 1. Descripción

Este mantenedor es el **módulo central** del Sistema Control de Acceso de Avaluaciones (SCAA) y permite administrar usuarios internos (funcionarios SII) y externos (OCM, notarios, CBR, CDE, municipalidades). Gestiona la asignación de unidades de negocio, cargos, funciones, y jurisdicción (simple o ampliada).

**Estado del Modelo de Datos:** ⚠️ Tabla BR_RELACIONADOS EXISTE (requiere ALTER TABLE para nuevas columnas)
- BR_RELACIONADOS: EXISTE → agregar columnas nuevas (RELA_TIPO_USUARIO, RELA_JURISDICCION, etc.)
- BR_CARGOS_USUARIO: NO EXISTE → crear
- BR_FUNCIONES_USUARIO: NO EXISTE → crear
- BR_JURISDICCION_USUARIO: NO EXISTE → crear

## 2. Objetivos Funcionales

- Administrar usuarios relacionados internos y externos con validación RUT único
- Consultar automáticamente SIGER para usuarios SII (datos read-only) y RIAC para externos (editable)
- Gestionar unidades de negocio asignadas (principal + apoyo multi-jurisdicción)
- Asignar cargos vigentes a usuarios por unidad
- Asignar funciones específicas bajo cada cargo
- Controlar jurisdicción simple (solo región de la unidad) o ampliada (todo el país)
- Mantener historial completo de cambios con auditoría

## 3. Perfiles Requeridos

| Perfil | Alcance | Permisos |
|--------|---------|----------|
| Administrador Nacional | Nacional | Consulta y administra usuarios sin restricciones |
| Administrador Regional | Regional | Administra usuarios de su región |
| Administrador de Unidad | Unidad | Administra usuarios de su unidad específica |
| Consulta | Nacional/Regional | Consulta información sin modificar |

## 4. Análisis Visual de Imágenes

### 4.1 Mapeo Completo de Imágenes

| # | Imagen | Análisis Visual | Contexto Requerimientos | Componente |
|---|--------|-----------------|------------------------|------------|
| 1 | image-0027.png | Pantalla inicial vacía: SearchBar con input RUT + lupa, botón "Agregar usuario nuevo" (+). Estado sin búsqueda realizada. | "Inicialmente la pantalla aparece solo como se muestra en la imagen... Para buscar un usuario relacionado se debe ingresar el Rut" | SearchBar + EmptyState |
| 2 | image-0028.png | Alerta verde "Registro guardado correctamente" con botón "Aceptar" | "se alerta de grabado exitoso. Al presionar el botón Aceptar... se guarda la información y se cierra el mensaje" | SuccessAlert |
| 3 | image-0025.png | Card "Usuario Relacionado" con datos completos: RUT 15.000.000-1, Tipo SII, Nombre "María de los Ángeles Moscoso Aldumate", Email, Teléfono, Jurisdicción Simple, Vigencias. Botones editar (lápiz) y eliminar (basurero). Sección "Unidad de Negocio" expandida con cargos y funciones. | "Se despliega la información del usuario relacionado buscado como: RUT, tipo de unidad, Nombre del usuario, email, fono, tipo de jurisdicción (simple o múltiple) y vigencia inicial y final" | UserDetailCard + UnidadSection |
| 4 | image-0020.png | Modal "Agregar Cargo": Dropdown "Seleccione Cargo", inputs Vigencia Inicio/Fin (calendarios), sección "Funciones del cargo" con dropdown "Seleccione la Función" + icono (+) para más, botón "Agregar" | "se abre una ventana para ingresar el cargo y seleccionar las funciones... Si se requiere agregar más funciones se presiona el icono más" | AddCargoModal |
| 5 | image-0022.png | Modal "Agregar Función del cargo": Muestra "Cargo: Jefe de Departamento" (read-only), dropdown "Seleccione la Función", icono (+) para más funciones, botón "Agregar" | "Se muestra el cargo al que se le debe agregar una función y se debe seleccionar de una lista desplegable con las funciones disponibles" | AddFuncionModal |
| 6 | image-0010.png | Alerta confirmación eliminar: "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada." Botones "Aceptar" (verde) y "Cancelar" (blanco) | "debe haber una alerta de confirmación de la acción" para eliminar cargo/función/usuario | ConfirmDialog |

### 4.2 Mapeo Frontend → Backend → BD

| Visual Campo | Componente | API Endpoint | BD Tabla.Columna | Tipo | Validación |
|--------------|-----------|--------------|-----------------|------|------------|
| Input "Ingrese RUT" | SearchBar | GET /buscar?rut={rut} | BR_RELACIONADOS.RELA_RUT | NUMBER(9) | Obligatorio, único, módulo 11 |
| "RUT: 15.000.000-1" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_RUT + RELA_DV | NUMBER(9)+VARCHAR2(1) | Read-only después de crear |
| "Tipo: SII" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_TIPO_USUARIO | VARCHAR2(10) | INTERNO/EXTERNO |
| "Nombre: María..." | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_NOMBRE + RELA_PATERNO + RELA_MATERNO | VARCHAR2(40)+VARCHAR2(20)+VARCHAR2(20) | **⚠️ RELA_NOMBRE límite 40 chars** en BD. Read-only si SII (desde SIGER) |
| "Email: maria.moscoco@sii.cl" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_EMAIL | VARCHAR2(80) | Read-only si SII, formato email |
| "Teléfono: +56912345678" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_FONO | VARCHAR2(15) | **⚠️ BD usa RELA_FONO** (no RELA_TELEFONO). Read-only si SII, formato +56 |
| Toggle "Simple/Ampliada" | UserDetailCard | PUT /{rut}/jurisdiccion | BR_RELACIONADOS.RELA_JURISDICCION | VARCHAR2(10) | SIMPLE/AMPLIADA |
| "Vigencia Inicio" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_VIGENCIA_INICIO | DATE | Obligatorio, <= hoy |
| "Vigencia Fin" | UserDetailCard | GET /buscar | BR_RELACIONADOS.RELA_VIGENCIA_FIN | DATE | Opcional, > inicio |
| Dropdown "Seleccione Cargo" | AddCargoModal | POST /{rut}/cargos | BR_CARGOS_USUARIO.CAUS_CARGO_CODIGO | NUMBER(3) | **FK a BR_CARGOS.CARG_CODIGO NUMBER(3)** |
| Dropdown "Seleccione la Función" | AddFuncionModal | POST /{rut}/cargos/{cargoId}/funciones | BR_FUNCIONES_USUARIO.FUUS_FUNC_CODIGO | NUMBER(3) | **FK a BR_FUNCIONES.FUNS_CODIGO NUMBER(3), CASCADE** |

## 5. Funcionalidades Principales

### 5.1 Búsqueda de Usuario Relacionado

**Pantalla inicial** (image-0027):
- SearchBar con input RUT + icono lupa
- Botón "+ Agregar usuario nuevo"
- Estado vacío sin resultados

**Flujo:**
1. Usuario ingresa RUT en formato XX.XXX.XXX-X
2. Sistema valida formato y dígito verificador (módulo 11)
3. Al presionar lupa: GET /buscar?rut={rut}
4. Si existe: muestra UserDetailCard (image-0025) con datos completos
5. Si no existe: error "Usuario no encontrado"

### 5.2 Visualización de Datos Usuario

**Card Usuario Relacionado** (image-0025):
- **Sección Usuario:** RUT, Tipo (SII/Externo), Nombre, Email, Teléfono
- **Jurisdicción:** Toggle Simple/Ampliada
- **Vigencias:** Fecha inicio (obligatoria), Fecha fin (opcional)
- **Botones acción:** Editar (lápiz), Eliminar (basurero)

**Reglas:**
- Si Tipo = SII: Nombre, Email, Teléfono son **read-only** (desde SIGER)
- Si Tipo = Externo: Nombre, Email, Teléfono son **editables** (desde RIAC)
- Tipo de usuario **NO se puede cambiar** después de crear

### 5.3 Gestión de Unidades de Negocio

**Sección Unidad de Negocio** (image-0025 parte inferior):
- Lista de unidades asignadas (principal + apoyo multi-jurisdicción)
- Cada unidad muestra: Nombre, Región, Estado
- Botón "+ Agregar unidad" (solo para multi-jurisdicción)
- Por cada unidad: lista de cargos con funciones

### 5.4 Gestión de Cargos

**Modal Agregar Cargo** (image-0020):
- Dropdown "Seleccione Cargo" (filtrado por unidad)
- Input "Vigencia Inicio" (calendario, obligatorio)
- Input "Vigencia Fin" (calendario, opcional)
- Sección "Funciones del cargo":
  - Dropdown "Seleccione la Función"
  - Icono (+) para agregar más funciones
  - Mínimo 1 función requerida
- Botón "Agregar" (habilitado si campos completos)
- Icono X (cancelar)

**Modificar Cargo:**
- Solo se puede cambiar vigencia con toggle Vigente/No Vigente
- Vigente: botón verde oscuro
- No Vigente: botón naranjo

**Eliminar Cargo:**
- Icono basurero al lado del cargo
- Alerta confirmación (image-0010)
- DELETE CASCADE: elimina cargo + funciones + relaciones

### 5.5 Gestión de Funciones

**Modal Agregar Función** (image-0022):
- Campo "Cargo: Jefe de Departamento" (read-only, muestra cargo seleccionado)
- Dropdown "Seleccione la Función" (solo funciones NO asignadas a ese cargo)
- Icono (+) para agregar más funciones en batch
- Botón "Agregar" (guarda todas las funciones seleccionadas)
- Icono X (cancelar)

**Eliminar Función:**
- Icono basurero al lado de cada función
- Alerta confirmación (image-0010)
- DELETE relación BR_FUNCIONES_USUARIO (NO elimina de BR_FUNCIONES)
- Validación: no eliminar si es última función del cargo (mínimo 1)

### 5.6 Jurisdicción Simple vs Ampliada

**Toggle Jurisdicción** (en UserDetailCard):
- **Simple:** Usuario solo puede trabajar en región de su unidad principal
- **Ampliada:** Usuario puede trabajar en cualquier región del país

**Efecto en asignación de comunas:**
- Simple: dropdown regiones muestra SOLO región de la unidad
- Ampliada: dropdown regiones muestra TODAS las regiones

### 5.7 Crear Nuevo Usuario

**Flujo:**
1. Click en botón "+ Agregar usuario nuevo"
2. Sistema muestra formulario vacío con campos editables
3. Ingresa RUT → valida que NO exista en BR_RELACIONADOS
4. Selecciona Tipo: Radio buttons "SII" / "Externo"
5. Si SII:
   - Sistema consulta SIGER: GET /siger/buscar?rut={rut}
   - Autocompleta Nombre, Email, Teléfono (read-only)
6. Si Externo:
   - Sistema consulta RIAC (opcional): GET /riac/buscar?rut={rut}
   - Permite editar todos los campos manualmente
7. Completa datos obligatorios: Vigencia Inicio
8. Selecciona Unidad de Negocio (obligatorio, será unidad principal)
9. Click icono ✓ → POST /crear
10. Sistema muestra alerta verde (image-0028)
11. Luego debe agregar cargos y funciones

### 5.8 Eliminar Usuario Relacionado

**Flujo:**
1. Click en icono basurero del UserDetailCard
2. Sistema valida: no tiene permisos activos críticos
3. Muestra alerta confirmación (image-0010): "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."
4. Al presionar "Aceptar":
   - DELETE CASCADE BR_RELACIONADOS
   - Elimina automáticamente: cargos, funciones, jurisdicción, multi-jurisdicción
   - Registra en auditoría
5. Al presionar "Cancelar": cierra alerta sin cambios

## 6. Arquitectura

### Frontend
```
UserRelatedPage (Pantalla Principal)
├── SearchBar (image-0027)
│   ├── Input RUT
│   ├── Button Lupa (buscar)
│   └── Button Agregar (+)
├── EmptyState (sin búsqueda)
├── UserDetailCard (image-0025)
│   ├── Section Usuario Relacionado
│   │   ├── RUT (read-only)
│   │   ├── Tipo (read-only)
│   │   ├── Nombre (condicional)
│   │   ├── Email (condicional)
│   │   ├── Teléfono (condicional)
│   │   ├── Toggle Jurisdicción
│   │   ├── Vigencia Inicio/Fin
│   │   ├── Button Editar
│   │   └── Button Eliminar
│   └── Section Unidad de Negocio
│       ├── UnidadItem (por cada unidad)
│       │   ├── Nombre Unidad
│       │   ├── Button Agregar Cargo (+)
│       │   └── CargosAccordion
│       │       ├── CargoItem (por cargo)
│       │       │   ├── Nombre Cargo
│       │       │   ├── Toggle Vigente
│       │       │   ├── Button Eliminar
│       │       │   ├── Button Agregar Función (+)
│       │       │   └── FuncionList
│       │       │       └── FuncionItem (por función)
│       │       │           ├── Nombre Función
│       │       │           └── Button Eliminar
│       └── Button Agregar Unidad (multi-jurisdicción)
├── AddCargoModal (image-0020)
├── AddFuncionModal (image-0022)
├── SuccessAlert (image-0028)
└── ConfirmDialog (image-0010)
```

### Backend
```
Base URL: /acaj-ms/api/v1/{rut}-{dv}/usuarios-relacionados

Endpoints:
1. GET /buscar?rut={rut} - Buscar usuario por RUT
2. POST /crear - Crear nuevo usuario (interno o externo)
3. PUT /{rut}/datos - Modificar datos personales (solo externos)
4. PUT /{rut}/jurisdiccion - Cambiar jurisdicción simple/ampliada
5. DELETE /{rut} - Eliminar usuario (CASCADE)
6. GET /{rut}/cargos - Listar cargos del usuario
7. POST /{rut}/cargos - Agregar cargo con funciones
8. PUT /{rut}/cargos/{cargoId}/vigencia - Toggle vigencia cargo
9. DELETE /{rut}/cargos/{cargoId} - Eliminar cargo (CASCADE funciones)
10. POST /{rut}/cargos/{cargoId}/funciones - Agregar funciones a cargo
11. DELETE /{rut}/cargos/{cargoId}/funciones/{funcionId} - Eliminar función
12. GET /siger/buscar?rut={rut} - Consultar datos en SIGER
13. GET /riac/buscar?rut={rut} - Consultar datos en RIAC
```

### Modelo de Datos
```
BR_RELACIONADOS (tabla existente + nuevas columnas)
├── RELA_RUT (PK NUMBER(9))
├── RELA_DV (VARCHAR2(1))
├── RELA_TIPO_USUARIO (NEW: VARCHAR2(10) INTERNO/EXTERNO)
├── RELA_NOMBRE (VARCHAR2(40)) ⚠️ Límite 40 caracteres en BD real
├── RELA_PATERNO (VARCHAR2(20))
├── RELA_MATERNO (VARCHAR2(20))
├── RELA_EMAIL (VARCHAR2(80))
├── RELA_FONO (VARCHAR2(15)) ⚠️ BD usa RELA_FONO (no RELA_TELEFONO)
├── RELA_FAX (VARCHAR2(15))
├── RELA_CODIGO (NUMBER(4)) ⚠️ Columna existente en BD (propósito TBD)
├── RELA_JURISDICCION (NEW: VARCHAR2(10) SIMPLE/AMPLIADA)
├── RELA_VIGENCIA_INICIO (NEW: DATE)
├── RELA_VIGENCIA_FIN (NEW: DATE)
└── RELA_UNIDAD_PRINCIPAL (NEW: NUMBER(4))

BR_CARGOS (tabla existente)
├── CARG_CODIGO (PK NUMBER(3)) ⚠️ Tipo específico NUMBER(3)
├── CARG_DESCRIPCION (VARCHAR2(50))
└── CARG_VIGENTE (NUMBER(1)) ⚠️ Es NUMBER(1): 1=vigente, 0=no vigente

BR_FUNCIONES (tabla existente)
├── FUNS_CODIGO (PK NUMBER(3)) ⚠️ Tipo específico NUMBER(3)
├── FUNS_DESCRIPCION (VARCHAR2(60))
└── FUNS_VIGENTE (NUMBER(1)) ⚠️ Es NUMBER(1): 1=vigente, 0=no vigente

BR_CARGOS_USUARIO (nueva tabla)
├── CAUS_ID (PK NUMBER(10), sequence)
├── CAUS_RELA_RUT (FK BR_RELACIONADOS.RELA_RUT NUMBER(9))
├── CAUS_CARGO_CODIGO (FK BR_CARGOS.CARG_CODIGO NUMBER(3))
├── CAUS_UNIDAD_CODIGO (NUMBER(4))
├── CAUS_VIGENTE (VARCHAR2(1) S/N)
├── CAUS_FECHA_INICIO (DATE)
└── CAUS_FECHA_FIN (DATE)

BR_FUNCIONES_USUARIO (nueva tabla)
├── FUUS_ID (PK NUMBER(10), sequence)
├── FUUS_CAUS_ID (FK BR_CARGOS_USUARIO.CAUS_ID, CASCADE)
├── FUUS_FUNC_CODIGO (FK BR_FUNCIONES.FUNS_CODIGO NUMBER(3))
├── FUUS_FECHA_ASIGNACION (DATE)
└── FUUS_USUARIO_ASIGNADOR (VARCHAR2(20))

BR_JURISDICCION_USUARIO (nueva tabla para multi-jurisdicción)
├── JUUR_ID (PK NUMBER(10), sequence)
├── JUUR_RELA_RUT (FK BR_RELACIONADOS.RELA_RUT NUMBER(9))
├── JUUR_UNIDAD_APOYO (NUMBER(4))
├── JUUR_FECHA_INICIO (DATE)
├── JUUR_FECHA_FIN (DATE)
└── JUUR_MOTIVO (VARCHAR2(200))

**⚠️ NOTAS CRÍTICAS DEL MODELO:**
1. **RELA_NOMBRE**: Límite de 40 caracteres en BD real (no 100)
2. **RELA_FONO**: Nombre correcto en BD (no RELA_TELEFONO)
3. **Vigencias CARG_VIGENTE/FUNS_VIGENTE**: Son NUMBER(1) en BD, queries deben filtrar `WHERE CARG_VIGENTE = 1`
4. **PKs específicos**: CARG_CODIGO y FUNS_CODIGO son NUMBER(3), no genérico NUMBER
5. **RELA_CODIGO**: Columna NUMBER(4) existe en BD, propósito por definir
```
├── JUUR_ID (PK, sequence)
├── JUUR_RELA_RUT (FK BR_RELACIONADOS)
├── JUUR_UNNE_ID_APOYO (FK BR_UNIDADES_NEGOCIO)
├── JUUR_FECHA_INICIO
└── JUUR_FECHA_FIN
```

## 7. Validación de Coherencia

### Ejemplo 1: Búsqueda de Usuario

| Frontend | Backend API | BD Query | Resultado |
|----------|-------------|----------|-----------|
| Input RUT "15.000.000-1" | GET /buscar?rut=15000000 | SELECT * FROM BR_RELACIONADOS WHERE RELA_RUT=15000000 | UserDetailCard con datos completos |
| Button Lupa click | Valida formato + módulo 11 | JOIN BR_CARGOS_USUARIO, BR_FUNCIONES_USUARIO | Muestra unidades, cargos, funciones |

### Ejemplo 2: Agregar Cargo con 3 Funciones

| Frontend | Backend API | BD Transaction | Validación |
|----------|-------------|----------------|------------|
| Select "Jefe Depto" + 3 funciones | POST /{rut}/cargos body: {cargoId, funciones: [15, 23, 45]} | BEGIN; INSERT BR_CARGOS_USUARIO; INSERT BR_FUNCIONES_USUARIO (3x); COMMIT; | Cargo existe, Funciones vigentes, No duplicados |
| Click "Agregar" | Response 201 | SEQ_CARGO_USUARIO_ID.NEXTVAL | Alerta verde (image-0028) |

### Ejemplo 3: Eliminar Función (última del cargo)

| Frontend | Backend API | BD Validation | Error |
|----------|-------------|---------------|-------|
| Click basurero en función | DELETE /{rut}/cargos/{cid}/funciones/{fid} | SELECT COUNT(*) FROM BR_FUNCIONES_USUARIO WHERE FUUS_CAUS_ID=? | COUNT=1 → Error 409 "No se puede eliminar última función del cargo" |
| Modal confirmación | Validación pre-delete | - | Button "Aceptar" deshabilitado si última |

## 8. Estado del Desarrollo

### Checklist Documentación

- [x] README.md con análisis visual de 6 imágenes
- [ ] frontend.md con 15+ componentes React
- [ ] backend-apis.md con 13 endpoints REST
- [ ] HdU-009: Buscar Usuario Relacionado
- [ ] HdU-010: Crear Usuario Interno (SII)
- [ ] HdU-011: Crear Usuario Externo
- [ ] HdU-012: Modificar Datos Usuario
- [ ] HdU-013: Agregar Cargo con Funciones
- [ ] HdU-014: Eliminar Cargo
- [ ] HdU-015: Agregar Función a Cargo
- [ ] HdU-016: Eliminar Función de Cargo
- [ ] DDL/alter-tables.sql (modificar BR_RELACIONADOS)
- [ ] DDL/create-tables.sql (3 tablas nuevas)

### Próximos Pasos

1. Verificar estructura actual de BR_RELACIONADOS en Oracle AVAL
2. Crear frontend.md con mapeo de 6 imágenes a componentes
3. Crear 8 HdU con criterios de aceptación detallados
4. Actualizar DDL con ALTER TABLE y CREATE TABLE
5. Validar coherencia Frontend ↔ Backend ↔ BD

## Referencias

- Documento de requerimientos: `tmp/Requerimineto-Control-Acceso-2/output/requeriments.md` (Módulo V)
- Diseño Fase 3: `docs/PHASE-03-design.md`
- Análisis Fase 3: `docs/PHASE-03-analisis.md`
- Imágenes: 6 PNG en carpeta del módulo (0010, 0020, 0022, 0025, 0027, 0028)
