# HdU-001: Listar y Buscar Unidades de Negocio

## Información General

- **ID**: HdU-001
- **Módulo**: VI - Mantenedor de Unidades de Negocio
- **Prioridad**: Alta
- **Estimación**: 5 puntos

## Historia de Usuario

**Como** administrador del sistema,  
**Quiero** visualizar y buscar unidades de negocio con filtros múltiples,  
**Para** gestionar eficientemente la estructura organizacional del SII.

## Criterios de Aceptación

### AC-001: Visualización Inicial
- Al acceder a la vista principal, el sistema muestra todas las unidades de negocio vigentes
- La tabla muestra: Tipo Unidad, Código, Nombre, Dirección, Teléfono, Email, Unidad Padre, Vigencia
- La paginación muestra 20 registros por página
- El total de registros se muestra: "Mostrando 1-20 de 585 resultados"

### AC-002: Filtro por Tipo de Unidad
- El dropdown "Tipo de Unidad" carga opciones desde tabla BR_TIPOS_UNIDAD
- Al seleccionar un tipo, la tabla se filtra mostrando solo unidades de ese tipo
- El filtro se muestra como badge removible: "Tipo: Dirección Regional X"

### AC-003: Filtro por Vigencia
- El toggle muestra tres opciones: "Vigente", "No Vigente", "Todos"
- Por defecto está seleccionado "Vigente" (UNNE_VIGENTE = 1)
- Al cambiar a "No Vigente", muestra solo unidades con UNNE_VIGENTE = 0
- Al seleccionar "Todos", muestra todas las unidades sin filtro de vigencia

### AC-004: Búsqueda por Nombre
- El input texto permite búsqueda parcial (LIKE '%texto%')
- La búsqueda es case-insensitive
- Al ejecutar búsqueda, la tabla se filtra mostrando coincidencias en el nombre
- El filtro se muestra como badge removible: "Nombre: Fiscal X"

### AC-005: Búsqueda Combinada
- Los filtros se pueden combinar (tipo + vigencia + nombre)
- Todos los filtros activos se muestran como badges removibles
- Al hacer clic en X de un badge, se remueve solo ese filtro y se recarga la tabla

### AC-006: Limpiar Filtros
- El botón "Limpiar" resetea todos los filtros a valores default (Vigente, sin tipo, sin nombre)
- La tabla se recarga mostrando todas las unidades vigentes

### AC-007: Paginación
- La tabla muestra 20 registros por página
- Los controles de paginación permiten navegar entre páginas
- Al cambiar de página, los filtros se mantienen activos
- Se muestra el rango actual: "Mostrando 21-40 de 585 resultados"

### AC-008: Ordenamiento
- Al hacer clic en encabezado "Nombre", la tabla se ordena alfabéticamente
- Primer clic: ascendente (A-Z)
- Segundo clic: descendente (Z-A)
- Tercer clic: vuelve a orden default

### AC-009: Sin Resultados
- Si no hay coincidencias, se muestra mensaje: "No se encontraron unidades con los criterios especificados"
- Se ofrece botón "Limpiar Filtros" para resetear búsqueda

## Flujos Principales

### Flujo Principal: Búsqueda con Filtros

1. Usuario accede a vista `/unidades-negocio`
2. Sistema muestra tabla con 20 unidades vigentes (primera página de 585 totales)
3. Usuario selecciona "Departamento" en dropdown "Tipo de Unidad"
4. Usuario selecciona "Vigente" en toggle vigencia (ya seleccionado por defecto)
5. Usuario ingresa "Fiscal" en input búsqueda por nombre
6. Usuario hace clic en botón "Buscar" (icono lupa)
7. Sistema ejecuta GET /unidades-negocio?tipoUnidad=2&vigente=1&nombre=Fiscal
8. Sistema muestra tabla filtrada con 5 resultados
9. Sistema muestra badges: "Tipo: Departamento X", "Vigente X", "Nombre: Fiscal X"
10. Sistema muestra total: "Mostrando 1-5 de 5 resultados"

### Flujo Alternativo 1: Limpiar Filtros

1. Usuario tiene filtros activos (desde flujo principal)
2. Usuario hace clic en botón "Limpiar"
3. Sistema resetea dropdown tipo unidad a "Todos"
4. Sistema resetea toggle vigencia a "Vigente"
5. Sistema limpia input nombre
6. Sistema remueve todos los badges de filtros
7. Sistema recarga tabla con todas las unidades vigentes (585 totales, página 1)

### Flujo Alternativo 2: Remover Filtro Individual

1. Usuario tiene 3 filtros activos (tipo, vigencia, nombre)
2. Usuario hace clic en X del badge "Tipo: Departamento X"
3. Sistema remueve solo ese filtro
4. Sistema mantiene filtros de vigencia y nombre
5. Sistema recarga tabla con filtros restantes
6. Sistema actualiza contador de resultados

### Flujo Alternativo 3: Sin Resultados

1. Usuario ingresa "XYZ123" en búsqueda por nombre
2. Usuario hace clic en "Buscar"
3. Sistema ejecuta query y no encuentra coincidencias
4. Sistema muestra mensaje: "No se encontraron unidades con los criterios especificados"
5. Sistema muestra botón "Limpiar Filtros"
6. Usuario hace clic en "Limpiar Filtros"
7. Sistema resetea y muestra todas las unidades vigentes

## Notas Técnicas

### API Consumida
- **Endpoint**: GET /acaj-ms/api/v1/{rut}-{dv}/unidades-negocio
- **Método**: GET
- **Query Params**: tipoUnidad, vigente, nombre, page, size

### Validaciones Backend
- Validar formato RUT en path
- Validar permisos según alcance usuario (Nacional, Regional, Unidad)
- Validar parámetros de paginación (page >= 1, size <= 100)

### Tablas BD Afectadas
- **Lectura**: BR_UNIDADES_NEGOCIO, BR_TIPOS_UNIDAD
- **Operación**: SELECT con JOIN y LEFT JOIN

## Dependencias

- Tabla BR_UNIDADES_NEGOCIO debe estar poblada (585 registros validados)
- Tabla BR_TIPOS_UNIDAD debe estar poblada (23 tipos validados)
- Usuario debe tener sesión activa con token JWT válido

## Glosario

- **Unidad de Negocio**: Entidad organizacional del SII (Dirección Regional, Departamento, Sección, Unidad)
- **Tipo de Unidad**: Clasificación de unidades según nivel jerárquico (BR_TIPOS_UNIDAD)
- **Vigente**: Unidad activa (UNNE_VIGENTE = 1) o inactiva (UNNE_VIGENTE = 0)
- **Badge**: Etiqueta visual removible que representa un filtro activo
- **Alcance**: Nivel de permisos del usuario (Nacional, Regional, Unidad)
