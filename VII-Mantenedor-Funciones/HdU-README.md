# Compendio de Historias de Usuario - Módulo VII: Mantenedor de Funciones

## Resumen

Este módulo contiene **11 historias de usuario** que cubren la funcionalidad completa del Mantenedor de Funciones del Sistema Control de Acceso de Avaluaciones (SCAA).

## Historias de Usuario

| ID | Título | Prioridad | Estimación | Actor |
|----|--------|-----------|------------|-------|
| [HdU-001](./HdU-001-Crear-Funcion.md) | Crear función con opción inicial | Alta | 5 pts | Administrador Nacional |
| [HdU-002](./HdU-002-Buscar-Funcion.md) | Buscar función por vigencia | Alta | 3 pts | Admin Nacional, Consulta |
| [HdU-003](./HdU-003-Modificar-Vigencia-Funcion.md) | Modificar vigencia de función | Alta | 3 pts | Administrador Nacional |
| [HdU-004](./HdU-004-Eliminar-Funcion.md) | Eliminar función | Media | 3 pts | Administrador Nacional |
| [HdU-005](./HdU-005-Agregar-Opcion.md) | Agregar opción a función | Alta | 5 pts | Administrador Nacional |
| [HdU-006](./HdU-006-Eliminar-Opcion.md) | Eliminar opción de función | Media | 3 pts | Administrador Nacional |
| [HdU-007](./HdU-007-Agregar-Atribucion-Alcance.md) | Agregar atribución-alcance a opción | Alta | 3 pts | Administrador Nacional |
| [HdU-008](./HdU-008-Eliminar-Atribucion-Alcance.md) | Eliminar atribución-alcance | Media | 2 pts | Administrador Nacional |
| [HdU-009](./HdU-009-Ver-Usuarios-Funcion.md) | Ver usuarios de función | Alta | 5 pts | Admin Nacional, Consulta |
| [HdU-010](./HdU-010-Reordenar-Opciones.md) | Reordenar opciones con drag and drop | Baja | 3 pts | Administrador Nacional |
| [HdU-011](./HdU-011-Exportar-Usuarios-Excel.md) | Exportar usuarios a Excel | Media | 3 pts | Admin Nacional, Consulta |

**Total:** 38 puntos de historia

## Agrupación por Funcionalidad

### Gestión de Funciones (14 pts)
- HdU-001: Crear función con opción inicial (5 pts)
- HdU-002: Buscar función por vigencia (3 pts)
- HdU-003: Modificar vigencia de función (3 pts)
- HdU-004: Eliminar función (3 pts)

### Gestión de Opciones (11 pts)
- HdU-005: Agregar opción a función (5 pts)
- HdU-006: Eliminar opción de función (3 pts)
- HdU-010: Reordenar opciones con drag and drop (3 pts)

### Gestión de Atribuciones-Alcances (5 pts)
- HdU-007: Agregar atribución-alcance a opción (3 pts)
- HdU-008: Eliminar atribución-alcance (2 pts)

### Visualización y Reportes (8 pts)
- HdU-009: Ver usuarios de función (5 pts)
- HdU-011: Exportar usuarios a Excel (3 pts)

## Priorización

### Alta Prioridad (24 pts) - Sprint 1
1. HdU-001: Crear función (5 pts) - **Base fundamental**
2. HdU-002: Buscar función (3 pts) - **Navegación básica**
3. HdU-003: Modificar vigencia (3 pts) - **Control acceso**
4. HdU-005: Agregar opción (5 pts) - **Expandir funciones**
5. HdU-007: Agregar atribución-alcance (3 pts) - **Permisos granulares**
6. HdU-009: Ver usuarios (5 pts) - **Trazabilidad**

### Media Prioridad (11 pts) - Sprint 2
7. HdU-004: Eliminar función (3 pts)
8. HdU-006: Eliminar opción (3 pts)
9. HdU-008: Eliminar atribución-alcance (2 pts)
10. HdU-011: Exportar usuarios Excel (3 pts)

### Baja Prioridad (3 pts) - Sprint 3
11. HdU-010: Reordenar opciones drag and drop (3 pts) - **Mejora UX**

## Dependencias entre HdU

```
HdU-001 (Crear función)
  ↓
HdU-002 (Buscar función)
  ↓
├── HdU-003 (Modificar vigencia)
├── HdU-004 (Eliminar función)
├── HdU-005 (Agregar opción)
│     ↓
│   ├── HdU-006 (Eliminar opción)
│   ├── HdU-007 (Agregar atrib-alc)
│   │     ↓
│   │   └── HdU-008 (Eliminar atrib-alc)
│   └── HdU-010 (Reordenar opciones)
└── HdU-009 (Ver usuarios)
      ↓
    HdU-011 (Exportar Excel)
```

## Módulos Externos Requeridos

### Módulos Previos (Bloquean desarrollo)
- **Módulo IX - Mantenedor de Alcance:** Definir alcances (Nacional, Regional, Unidad, Personal)
- **Módulo X - Mantenedor de Atribuciones:** Definir atribuciones (Registro, Archivo, Ingreso, etc.)
- **Módulo XI - Mantenedor de Opciones:** Definir opciones de aplicativos disponibles

### Módulos Posteriores (Dependen de este)
- **Módulo V - Mantenedor de Usuarios Relacionados:** Asignar funciones a usuarios
- **Módulo VIII - Mantenedor de Grupos:** Asignar funciones a grupos

## Criterios de Aceptación Generales

Todas las HdU comparten estos criterios transversales:

### Seguridad
- RUT usuario autenticado en ruta: `/api/v1/{rut}-{dv}/funciones`
- Validación permisos: Administrador Nacional (CRUD), Consulta (solo lectura)
- HTTP 403 si sin permisos, HTTP 404 si recurso no existe

### Auditoría
- Todas las operaciones CUD registran en AUDITORIA_FUNCIONES:
  - Fecha/hora (DD/MM/YYYY - HH:MM)
  - Evento (Crear, Modificar, Eliminar)
  - Descripción detallada
  - RUT y nombre funcionario
  - Ubicación (unidad)
  - Nro ticket (si aplica)
  - Autorización subdirector (si aplica)

### Validaciones
- Nombres función: max 500 caracteres, únicos (case insensitive), solo alfanuméricos/espacios/guiones
- Duplicados: validar combos opción-atribución-alcance únicos por función
- Usuarios asignados: bloquear eliminación, advertir al desactivar
- Foreign keys: validar existencia y vigencia de opciones, atribuciones, alcances

### Performance
- Búsquedas: < 1 segundo
- Guardado: < 2 segundos
- Carga modal usuarios: < 2 segundos (hasta 1000 usuarios)
- Exportar Excel: < 3 segundos (hasta 1000 usuarios)

### UX
- Mensajes éxito: "Registro guardado correctamente", "Vigencia actualizada", etc.
- Mensajes error: específicos y accionables
- Loading states: spinners en botones y áreas de contenido
- Confirmaciones: modal estándar para eliminaciones
- Tooltips: descripción completa en atribuciones-alcances al hover

## Modelo de Datos

### Tablas Principales
- **FUNCION:** id, codigo, nombre, vigente, fecha_creacion, usuario_creacion
- **FUNCION_OPCION:** id, funcion_id (FK), opcion_id (FK), orden, vigente, fecha_creacion
- **FUNCION_OPCION_ATRIB_ALCANCE:** id, funcion_opcion_id (FK), atribucion_id (FK), alcance_id (FK), vigente, fecha_creacion
- **AUDITORIA_FUNCIONES:** id, accion, descripcion, usuario, fecha, detalle_json

### Relaciones
- FUNCION 1:N FUNCION_OPCION (CASCADE DELETE)
- FUNCION_OPCION 1:N FUNCION_OPCION_ATRIB_ALCANCE (CASCADE DELETE)
- FUNCION_OPCION N:1 OPCION
- FUNCION_OPCION_ATRIB_ALCANCE N:1 ATRIBUCION
- FUNCION_OPCION_ATRIB_ALCANCE N:1 ALCANCE

### Índices Requeridos
- idx_funcion_nombre_vigente (nombre, vigente) - búsquedas duplicados
- idx_funcion_opcion_funcion_id (funcion_id) - carga opciones
- idx_funcion_opcion_atrib_alc_funcion_opcion_id (funcion_opcion_id) - carga atrib-alc
- idx_usuario_funcion_funcion_id (funcion_id) - contar usuarios

## Stack Tecnológico

### Frontend (acaj-intra-ui)
- Vue 3 + Composition API
- Bootstrap 5.2 + Bootstrap Icons
- Vuex 4.1 (state management)
- Axios (HTTP client)
- xlsx.js (exportar Excel)
- Sortable.js o vue-draggable (drag and drop)

### Backend (acaj-ms)
- Spring Boot 3.x
- Java 17+
- Oracle 19c driver
- Spring Data JPA
- Spring Security
- Lombok

### Base de Datos
- Oracle 19c (queilen.sii.cl:1540/koala)
- Schema: AVAL

## Notas de Implementación

### Frontend
- Formulario crear función inline (NO modal) con 3 filas jerárquicas
- Acordeones colapsables con animación CSS (300ms)
- Drag and drop solo para Administrador Nacional
- Exportar Excel 100% client-side (mejor performance)
- Caché local dropdown funciones (5 minutos)

### Backend
- Endpoints RESTful con RUT en ruta
- Transacciones atómicas para operaciones cascada
- Query optimizado con LEFT JOIN para cargar función completa
- Validación duplicados con UPPER() case insensitive
- Auditoría síncrona (INSERT después de cada operación exitosa)

### Base de Datos
- Foreign keys con ON DELETE CASCADE (funcion → opcion → atrib-alc)
- Constraint UNIQUE: uk_funcion_nombre_vigente UNIQUE (UPPER(nombre), vigente) WHERE vigente = 1
- Secuencias para IDs: seq_funcion, seq_funcion_opcion, seq_funcion_opcion_atrib_alc
- Triggers NO requeridos (lógica en backend)

## Roadmap de Desarrollo

### Sprint 1 (3 semanas) - Core Funcionalidad
- Semana 1: HdU-001, HdU-002 (crear y buscar funciones)
- Semana 2: HdU-003, HdU-005 (vigencia y agregar opciones)
- Semana 3: HdU-007, HdU-009 (atrib-alc y ver usuarios)

### Sprint 2 (2 semanas) - Operaciones CRUD
- Semana 1: HdU-004, HdU-006 (eliminar función y opción)
- Semana 2: HdU-008, HdU-011 (eliminar atrib-alc, exportar Excel)

### Sprint 3 (1 semana) - Mejoras UX
- HdU-010: Drag and drop reordenar opciones

**Total estimado:** 6 semanas (38 pts / 6.3 pts/semana)

## Referencias

- **Requerimientos:** `/docs/PHASE-03-requerimientos.md` - Sección 7
- **Frontend:** [frontend.md](./frontend.md)
- **Backend APIs:** [backend-apis.md](./backend-apis.md) (próximo a crear)
- **DDL:** [DDL/create-tables.sql](./DDL/create-tables.sql) (próximo a crear)
- **README Módulo:** [README.md](./README.md)
