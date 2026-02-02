# Módulo VIII: Mantenedor de Grupos

## 1. Descripción

Este mantenedor es **NUEVO** y permite administrar los distintos grupos de aplicativos que se despliegan en el menú principal de usuarios relacionados. Los grupos tendrán títulos bajo los cuales se desplegarán las opciones de las funciones asignadas a los usuarios del sistema.

**Estado del Modelo de Datos:** ✅ Tablas NO EXISTEN en Oracle AVAL (verificado 01/02/2026)
- BR_GRUPOS: NO EXISTE → crear
- BR_TITULOS: NO EXISTE → crear
- BR_TITULOS_FUNCIONES: NO EXISTE → crear
- BR_USUARIO_GRUPO: NO EXISTE → crear

## 2. Objetivos Funcionales

- Administrar grupos de aplicativos del menú principal
- Gestionar títulos de cada grupo con correlativo automático
- Asignar funciones a cada título
- Controlar vigencia de grupos (vigente/no vigente)
- Visualizar usuarios asociados a cada grupo
- Mantener historial completo de cambios con trazabilidad

## 3. Perfiles Requeridos

| Perfil | Alcance | Permisos |
|--------|---------|----------|
| Administrador Nacional | Nacional | Consulta y administra grupos sin restricciones |
| Consulta | Nacional | Consulta información de grupos sin modificar |

## 4. Análisis Visual de Imágenes

### 4.1 Mapeo Completo de Imágenes

| # | Imagen | Análisis Visual | Contexto Requerimientos | Componente |
|---|--------|-----------------|------------------------|------------|
| 1 | image-0127.png | Pantalla principal expandida: grupo "Sistema OT" (100 usuarios), toggle vigente, 2 títulos colapsables con funciones, iconos basurero y (+) | "Se muestra el Grupo, la cantidad de usuarios que tienen este grupo, la vigencia, títulos y funciones del grupo" | GroupsMainPage + TitulosAccordion |
| 2 | Imagen 4 (inline) | Formulario inline expandido: input "Ingrese nombre del Grupo", input "Ingrese nombre del Título", dropdown "Seleccione Función", botones X y ✓. Aparece entre SearchBar y GroupSection | "Para agregar un nuevo Grupo... Nombre del grupo, Título, Función" | CreateGroupForm (inline, NO modal) |
| 3 | image-0027.png | Alerta verde "Registro guardado correctamente" con botón "Aceptar" | "se alerta de grabado exitoso. Al presionar el botón Aceptar... se guarda la información" | SuccessAlert |
| 4 | image-0132.png | Modal "Usuarios por Grupo": tabla con Rut, Nombre, Vigencia Inicial/Final, 100 usuarios, icono Excel | "Al presionar la cantidad de usuarios se abre ventana con el listado de usuarios, cantidad total... posibilidad de descargar a Excel" | UserListModal |
| 5 | image-0135.png | Header: dropdown "Grupo" vacío, lupa de búsqueda, toggle No Vigente/Vigente | "Inicialmente la pantalla aparece... Para buscar un grupo se debe seleccionar: vigente o no vigente... y el grupo de una lista desplegable" | SearchBar |
| 6 | image-0034.png | Alerta confirmación "¿Está seguro que desea eliminar...? Perderá toda la información asociada" con Aceptar/Cancelar | "debe haber una alerta de confirmación de la acción" | ConfirmDialog |
| 7 | image-0139.png | Modal "Agregar Título": input título, dropdown función, icono (+) para más funciones, botón Agregar | "se abre una ventana para ingresar el titulo y seleccionar las funciones... Si se requiere agregar más funciones se presiona el icono más" | AddTituloModal |
| 8 | image-0143.png | Modal "Agregar Función": "Título 1: fccfgfcg" (read-only), dropdown "Seleccione la Función", botón Agregar | "Se muestra el titulo... se debe seleccionar de una lista desplegable... Se agrega una función a la vez" | AddFuncionModal |

### 4.2 Mapeo Frontend → Backend → BD

| Visual Campo | Componente | API Endpoint | BD Tabla.Columna | Tipo | Validación |
|--------------|-----------|--------------|-----------------|------|------------|
| "Ingrese nombre del Grupo" | CreateGroupForm | POST /crear body.nombre | BR_GRUPOS.GRUP_NOMBRE | VARCHAR2(100) | Obligatorio, max 100 |
| "Ingrese nombre del Título" | CreateGroupForm | POST /crear body.titulo | BR_TITULOS.TITU_NOMBRE | VARCHAR2(100) | Obligatorio, max 100 |
| "Seleccione Función" | CreateGroupForm | POST /crear body.funcionId | BR_TITULOS_FUNCIONES.TIFU_FUNC_ID | NUMBER | FK a BR_FUNCIONES |
| Toggle "Vigente/No Vigente" | GroupsMainPage | PUT /{id}/vigencia | BR_GRUPOS.GRUP_VIGENTE | VARCHAR2(1) | 'S' o 'N' |
| Cantidad usuarios (100) | GroupsMainPage | GET /{id}/usuarios | COUNT(*) BR_USUARIO_GRUPO | NUMBER | Read-only |
| Icono basurero (grupo) | GroupsMainPage | DELETE /{id} | BR_GRUPOS + CASCADE | - | Elimina títulos y funciones |

## 5. Funcionalidades Principales

### 5.1 Gestión de Grupos

**Pantalla Inicial** (image-0135.png):
- Dropdown para seleccionar grupo (vacío inicialmente)
- Toggle vigente/no vigente (por defecto: vigente)
- Icono lupa para buscar
- Botón "Agregar" siempre habilitado

**Agregar Grupo** (image-0129.png):
- Código del grupo: número correlativo automático (no visible)
- Nombre del grupo: texto de 100 caracteres (obligatorio)
- Título: texto de 100 caracteres (obligatorio)
- Función: lista desplegable con funciones disponibles (obligatorio)
- Icono X para cancelar
- Icono ✓ para guardar (se habilita al completar campos)
- Alerta de grabado exitoso (image-0027.png)

**Visualizar Grupo** (image-0127.png):
- Nombre del grupo
- Cantidad de usuarios (clickeable)
- Toggle vigente/no vigente
- Títulos colapsables con funciones
- Iconos de acción: basurero (eliminar), (+) agregar

**Eliminar Grupo** (image-0034.png):
- Icono basurero
- Alerta de confirmación con advertencia
- Al aceptar: elimina grupo y todos los registros asociados (títulos y funciones)

### 5.2 Gestión de Títulos del Grupo

**Visualización** (image-0127.png):
- Formato: nombre del título + correlativo automático
- Pestañas colapsables: click despliega/esconde funciones

**Agregar Título** (image-0139.png):
- Modal "Agregar Título"
- Input: nombre del título (obligatorio)
- Dropdown: seleccionar función (obligatorio)
- Icono (+): agregar más funciones al título
- Botón "Agregar": guarda cuando completo
- Alerta de confirmación (image-0027.png)

**Eliminar Título** (image-0034.png):
- Icono basurero al lado del título
- Alerta de confirmación
- Elimina título y todas las funciones asociadas

### 5.3 Gestión de Funciones del Título

**Agregar Función** (image-0143.png):
- Modal "Agregar Función"
- Muestra: título a modificar (read-only)
- Dropdown: seleccionar función (una a la vez)
- Botón "Agregar": guarda cuando completo
- Alerta de confirmación (image-0027.png)

**Eliminar Función** (image-0034.png):
- Icono basurero al lado de la función
- Alerta de confirmación
- Elimina solo esa relación título-función

### 5.4 Usuarios del Grupo

**Ver Usuarios** (image-0132.png):
- Modal "Usuarios por Grupo"
- Tabla con columnas:
  - RUT
  - Nombre
  - Vigencia Inicial
  - Vigencia Final
- Total de usuarios en header
- Botón Excel para exportar

### 5.5 Historial del Mantenedor

**Registros Requeridos:**
- Fecha y hora (dd/mm/aaaa - hh:mm)
- Evento (agregar, modificar, eliminar)
- Descripción de la acción
- RUT funcionario
- Nombre funcionario
- Ubicación (unidad)
- Nro ticket
- Autorización Subdirector(a) (Si/No)
- Convenio vigente (nombre o "No")

**Funcionalidades:**
- Icono para abrir historial en nueva ventana
- Descargar en Excel y PDF

## 6. Arquitectura

### Frontend
- Proyecto: `frontend/acaj-intra-ui`
- Stack: React 18 + Redux Toolkit + Ant Design
- Idioma: Español
- Rutas principales:
  - `/grupos` - Pantalla principal
  - `/grupos/crear` - Modal crear grupo
  - `/grupos/:id/titulos` - Gestión títulos
  - `/grupos/:id/historial` - Historial cambios

### Backend
- Proyecto: `backend/acaj-ms`
- Base URL: `/acaj-ms/api/v1/{rut}-{dv}/grupos`
- Endpoints: 10 APIs REST (ver backend-apis.md)
- Idioma: Español (campos, mensajes, validaciones)

### Base de Datos
- Oracle 19c (queilen.sii.cl:1540/koala)
- Schema: AVAL
- Tablas nuevas: 5 tablas + 2 secuencias + 7 índices
- Verificado: Todas las tablas son NUEVAS (no existen)

## 7. Modelo de Datos

### Tablas a Crear

#### BR_GRUPOS (Principal)
- GRUP_ID (NUMBER, PK, SEQ_GRUPO_ID)
- GRUP_NOMBRE (VARCHAR2(100), NOT NULL)
- GRUP_VIGENTE (VARCHAR2(1), DEFAULT 'S', CHECK 'S'/'N')
- GRUP_FECHA_CREACION (DATE, DEFAULT SYSDATE)
- GRUP_USUARIO_CREACION (NUMBER, FK BR_RELACIONADOS)
- GRUP_FECHA_MODIFICACION (DATE)
- GRUP_USUARIO_MODIFICACION (NUMBER, FK BR_RELACIONADOS)

#### BR_TITULOS (Hijos de Grupo)
- TITU_ID (NUMBER, PK, SEQ_TITULO_ID)
- TITU_GRUP_ID (NUMBER, FK BR_GRUPOS ON DELETE CASCADE)
- TITU_NOMBRE (VARCHAR2(100), NOT NULL)
- TITU_ORDEN (NUMBER, NOT NULL) - correlativo automático
- TITU_FECHA_CREACION (DATE, DEFAULT SYSDATE)
- TITU_USUARIO_CREACION (NUMBER, FK BR_RELACIONADOS)

#### BR_TITULOS_FUNCIONES (Relación N:M)
- TIFU_TITU_ID (NUMBER, PK compuesta, FK BR_TITULOS ON DELETE CASCADE)
- TIFU_FUNC_ID (NUMBER, PK compuesta, FK BR_FUNCIONES)
- TIFU_FECHA_CREACION (DATE, DEFAULT SYSDATE)
- TIFU_USUARIO_CREACION (NUMBER, FK BR_RELACIONADOS)

#### BR_USUARIO_GRUPO (Relación Usuarios-Grupos)
- USGR_RELA_RUT (NUMBER, PK compuesta, FK BR_RELACIONADOS)
- USGR_GRUP_ID (NUMBER, PK compuesta, FK BR_GRUPOS)
- USGR_FECHA_INICIO (DATE, NOT NULL)
- USGR_FECHA_FIN (DATE)
- USGR_ACTIVO (VARCHAR2(1), DEFAULT 'S', CHECK 'S'/'N')

#### BR_USUARIO_GRUPO_ORDEN (Orden Personalizado)
- UGOR_RELA_RUT (NUMBER, PK compuesta, FK BR_RELACIONADOS)
- UGOR_GRUP_ID (NUMBER, PK compuesta, FK BR_GRUPOS)
- UGOR_ORDEN (NUMBER, NOT NULL)

### Índices para Optimización
- IDX_GRUP_VIGENTE ON BR_GRUPOS(GRUP_VIGENTE)
- IDX_GRUP_NOMBRE ON BR_GRUPOS(GRUP_NOMBRE)
- IDX_TITU_GRUP ON BR_TITULOS(TITU_GRUP_ID)
- IDX_TITU_ORDEN ON BR_TITULOS(TITU_GRUP_ID, TITU_ORDEN)
- IDX_TIFU_TITU ON BR_TITULOS_FUNCIONES(TIFU_TITU_ID)
- IDX_TIFU_FUNC ON BR_TITULOS_FUNCIONES(TIFU_FUNC_ID)
- IDX_USGR_GRUP ON BR_USUARIO_GRUPO(USGR_GRUP_ID)

## 8. Validación de Coherencia

### Operaciones Validadas

✅ **CREATE Grupo**
- Frontend: CreateGroupModal (image-0129) → inputs Nombre, Título, Función
- Backend: POST /grupos/crear → transacción atómica 3 INSERTs
- BD: INSERT en BR_GRUPOS + BR_TITULOS + BR_TITULOS_FUNCIONES
- Secuencias: SEQ_GRUPO_ID, SEQ_TITULO_ID
- Auditoría: Registro en historial

✅ **READ Grupo**
- Frontend: GroupsMainPage (image-0127) → búsqueda dropdown + filtro vigente
- Backend: GET /grupos/buscar?vigente=S&grupoId=123
- BD: SELECT con JOINs BR_GRUPOS + BR_TITULOS + BR_TITULOS_FUNCIONES + BR_FUNCIONES
- Índices: IDX_GRUP_VIGENTE, IDX_GRUP_NOMBRE

✅ **UPDATE Vigencia**
- Frontend: Toggle verde/naranjo (image-0127)
- Backend: PUT /grupos/{id}/vigencia body.vigente='S'|'N'
- BD: UPDATE BR_GRUPOS SET GRUP_VIGENTE = :vigente
- Validación: CHECK constraint 'S'/'N'

✅ **DELETE Grupo**
- Frontend: Icono basurero + confirmación (image-0034)
- Backend: DELETE /grupos/{id}
- BD: DELETE CASCADE en BR_GRUPOS → elimina BR_TITULOS y BR_TITULOS_FUNCIONES
- Foreign keys: ON DELETE CASCADE

✅ **Agregar Título**
- Frontend: Modal agregar título (image-0139) → input + dropdown funciones + (+)
- Backend: POST /grupos/{id}/titulos body.titulo, funciones[]
- BD: INSERT en BR_TITULOS + múltiples INSERT en BR_TITULOS_FUNCIONES
- Orden: TITU_ORDEN calculado automáticamente (MAX + 1)

✅ **Agregar Función a Título**
- Frontend: Modal agregar función (image-0143) → título read-only + dropdown función
- Backend: POST /grupos/{gid}/titulos/{tid}/funciones body.funcionId
- BD: INSERT en BR_TITULOS_FUNCIONES
- Validación: FK TIFU_FUNC_ID existe en BR_FUNCIONES

✅ **Ver Usuarios del Grupo**
- Frontend: Modal usuarios (image-0132) → tabla + botón Excel
- Backend: GET /grupos/{id}/usuarios
- BD: SELECT COUNT(*) + lista desde BR_USUARIO_GRUPO con JOIN BR_RELACIONADOS
- Exportación: Excel (frontend genera desde datos API)

### Validaciones de BD Realizadas

✅ Todas las tablas NO EXISTEN → DDL crea todas  
✅ Tablas de referencia EXISTEN (BR_FUNCIONES, BR_RELACIONADOS)  
✅ Foreign keys válidas a tablas existentes  
✅ Secuencias para IDs automáticos  
✅ DELETE CASCADE correcto para integridad referencial  
✅ Índices en columnas de búsqueda frecuente  
✅ CHECK constraints para valores permitidos

## 9. Estructura de Archivos del Módulo

```
docs/develop-plan/VIII-Mantenedor-Grupos/
├── README.md (este archivo - especificación completa)
├── frontend.md (8 componentes React)
├── backend-apis.md (10 endpoints REST)
├── HdU-001-Crear-Grupo.md
├── HdU-002-Buscar-Grupo.md
├── HdU-003-Modificar-Vigencia-Grupo.md
├── HdU-004-Eliminar-Grupo.md
├── HdU-005-Agregar-Titulo.md
├── HdU-006-Eliminar-Titulo.md
├── HdU-007-Agregar-Funcion.md
├── HdU-008-Eliminar-Funcion.md
├── HdU-009-Ver-Usuarios-Grupo.md
├── DDL/
│   ├── create-tables.sql (5 tablas, 2 secuencias, 7 índices)
│   └── indexes.sql (índices de optimización)
└── images/
    ├── image-0127.png (pantalla principal)
    ├── image-0129.png (formulario agregar grupo)
    ├── image-0027.png (alerta éxito)
    ├── image-0132.png (modal usuarios)
    ├── image-0135.png (búsqueda header)
    ├── image-0034.png (alerta confirmación)
    ├── image-0139.png (agregar título)
    └── image-0143.png (agregar función)
```

## 10. Referencias

**Especificación Original:**
- `tmp/Requerimineto-Control-Acceso-2/output/requeriments.md` líneas 980-1205

**Diseño Técnico:**
- `docs/PHASE-03-design.md`

**System Prompt General:**
- `docs/develop-plan/system-prompt.md`

**Base de Datos:**
- Conexión: `sql intbrprod/Avalexpl@//queilen.sii.cl:1540/koala`
- Schema: AVAL
- Estado: Tablas NO EXISTEN (verificado 01/02/2026)

## 11. Estado del Desarrollo

- [x] Carpeta y estructura creadas
- [x] Imágenes extraídas y copiadas (8 PNG, 328 KB total)
- [x] Análisis visual de imágenes completado
- [x] Validación de tablas en Oracle AVAL (NO EXISTEN)
- [x] README.md con especificación completa
- [ ] frontend.md (8 componentes React)
- [ ] backend-apis.md (10 endpoints REST)
- [ ] HdU-*.md (9 historias de usuario)
- [ ] DDL/create-tables.sql
- [ ] progress-log.md actualizado
