# Frontend - Mantenedor de Unidades de Negocio

## 1. Stack Tecnológico Base

- **Framework**: Vue 3 + Composition API (acaj-intra-ui existente)
- **UI**: Bootstrap 5.2 + Bootstrap Icons
- **State**: Vuex 4.1
- **HTTP**: Axios con interceptores
- **Validación**: Vuelidate o validaciones personalizadas

## 2. Rutas Principales

```
/unidades-negocio              # Vista principal CRUD
/unidades-negocio/crear        # Formulario crear
/unidades-negocio/:tipo/:codigo/editar  # Formulario editar
/unidades-negocio/arbol        # Vista jerárquica árbol
```

## 3. Vistas y Componentes

### 3.1 Vista Principal - Lista de Unidades

**Ruta**: `/unidades-negocio`

**Componentes necesarios:**

#### SearchBar
- Input texto para búsqueda por nombre (búsqueda parcial, LIKE)
- Dropdown "Tipo de Unidad" (carga desde GET /tipos-unidad)
- Toggle "Vigente / No Vigente / Todos" (botones radio)
- Botón "Buscar" (icono lupa)
- Botón "Limpiar" (resetear filtros)
- Botón "Agregar" (navegación a /crear, verde, siempre habilitado)
- Botón "Vista Árbol" (navegación a /arbol, icono árbol/jerarquía)

#### TablaUnidades
- Columnas:
  - Tipo Unidad (descripción)
  - Código
  - Nombre
  - Dirección
  - Teléfono
  - Email
  - Unidad Padre (nombre, vacío si es raíz)
  - Vigente (badge verde "Vigente" o naranja "No Vigente")
  - Acciones (iconos: ver, editar, eliminar)
- Paginación: 20 registros por página (componente Bootstrap Pagination)
- Ordenamiento por nombre (ascendente/descendente)
- Filtros activos mostrados como badges removibles arriba de tabla

#### Acciones por Fila
- **Ver**: Icono ojo, abre modal con detalle completo + lista de unidades hijas
- **Editar**: Icono lápiz, navega a `/unidades-negocio/:tipo/:codigo/editar`
- **Eliminar**: Icono papelera, muestra modal de confirmación

### 3.2 Formulario Crear Unidad

**Ruta**: `/unidades-negocio/crear`

**Campos del Formulario:**

| Campo | Tipo | Validaciones | Placeholder |
|---|---|---|---|
| Tipo de Unidad | Dropdown | Requerido | Seleccione tipo |
| Nombre | Input text | Requerido, max 50 chars | Ingrese nombre unidad |
| Dirección | Input text | Requerido, max 50 chars | Ingrese dirección |
| Teléfono | Input text | Requerido, max 15 chars, formato +XX-X-XXXXXXX | 56-2-3952000 |
| Fax | Input text | Requerido, max 15 chars, formato +XX-X-XXXXXXX | 56-2-6964185 |
| Email | Input email | Opcional, max 80 chars, RFC 5322 | contacto@sii.cl |
| Comuna SII | Dropdown searchable | Requerido | Buscar comuna |
| Unidad Padre | Dropdown searchable | Opcional | Seleccione unidad padre (opcional) |
| Vigente | Toggle switch | Default ON (1) | - |

**Validaciones Frontend:**
- Tipo Unidad: Obligatorio, debe existir en lista tipos
- Nombre: Obligatorio, 1-50 caracteres, sin caracteres especiales peligrosos
- Dirección: Obligatorio, 1-50 caracteres
- Teléfono: Obligatorio, formato +XX-X-XXXXXXX
- Fax: Obligatorio, formato +XX-X-XXXXXXX
- Email: Opcional, validar RFC 5322 si se ingresa
- Comuna SII: Obligatorio, debe existir en lista comunas
- Unidad Padre: Opcional, si se selecciona debe ser del tipo compatible

**Botones:**
- **Guardar** (check verde): Habilitado solo si formulario válido, ejecuta POST /unidades-negocio
- **Cancelar** (X roja): Siempre habilitado, navega de vuelta a lista principal

**Estados:**
- **Loading**: Deshabilitar formulario mientras carga tipos de unidad, comunas
- **Submitting**: Deshabilitar botones mientras guarda (mostrar spinner)
- **Success**: Mostrar alerta "Unidad de negocio creada correctamente", navegar a lista
- **Error**: Mostrar alerta con mensaje de error del backend (400, 409)

### 3.3 Formulario Editar Unidad

**Ruta**: `/unidades-negocio/:tipo/:codigo/editar`

**Funcionalidad:**
- Cargar datos existentes con GET /unidades-negocio/:tipo/:codigo
- Mostrar formulario idéntico a crear, pero prellenado
- **Tipo Unidad** y **Código**: Read-only (parte de PK, no modificables)
- Resto de campos editables
- Botón **Actualizar** ejecuta PUT /unidades-negocio/:tipo/:codigo
- Validar que nueva unidad padre no cree jerarquía circular (validación backend)

**Validaciones Adicionales:**
- Si unidad tiene hijas, mostrar warning al cambiar unidad padre: "Esta unidad tiene N unidades hijas. ¿Desea continuar?"

### 3.4 Modal Detalle Unidad

**Trigger**: Clic en icono ojo de tabla

**Contenido:**
- Datos completos de la unidad (read-only)
- Sección "Unidades Hijas":
  - Si tiene hijas: Tabla con tipo, código, nombre, vigencia
  - Si no tiene hijas: Mensaje "No tiene unidades hijas"
- Botones:
  - **Editar** (navega a formulario editar)
  - **Cerrar** (cierra modal)

### 3.5 Modal Confirmación Eliminar

**Trigger**: Clic en icono papelera de tabla

**Contenido:**
- Título: "Confirmar Eliminación"
- Mensaje: "¿Está seguro de eliminar la unidad '{nombre}'?"
- **Warning si tiene hijas activas**: "Esta unidad tiene N unidades hijas activas. No se puede eliminar."
- Botones:
  - **Eliminar** (ejecuta DELETE /unidades-negocio/:tipo/:codigo, solo si no tiene hijas)
  - **Cancelar** (cierra modal)

**Estados:**
- **Success**: Mostrar alerta "Unidad de negocio marcada como no vigente", recargar tabla
- **Error 409**: Mostrar mensaje "No se puede eliminar una unidad con unidades hijas activas"

### 3.6 Vista Árbol Jerárquico

**Ruta**: `/unidades-negocio/arbol`

**Componentes:**
- **Filtro Vigente**: Toggle "Vigente / No Vigente / Todos" (default: Vigente)
- **Árbol Expandible** (componente tipo TreeView):
  - Carga datos desde GET /unidades-negocio/arbol
  - Cada nodo muestra: Tipo | Código | Nombre | Badge vigencia
  - Expandir/colapsar niveles (iconos + y -)
  - Al hacer clic en nodo: navegar a formulario editar
  - Colores diferentes por nivel jerárquico (nivel 0: azul, nivel 1: verde, nivel 2: amarillo)
- **Botón Volver**: Navega a lista principal

## 4. Mapeo Componentes → APIs

| Componente | Acción Usuario | API Endpoint | Método | Respuesta Esperada |
|---|---|---|---|---|
| SearchBar | Seleccionar tipo unidad | GET /tipos-unidad | GET | 200: Lista tipos de unidad |
| SearchBar | Buscar por filtros | GET /unidades-negocio?tipoUnidad={}&vigente={}&nombre={} | GET | 200: Lista unidades paginada |
| TablaUnidades | Ver detalle (ojo) | GET /unidades-negocio/:tipo/:codigo | GET | 200: Unidad + hijas / 404: No encontrada |
| FormularioCrear | Guardar nueva unidad | POST /unidades-negocio | POST | 201: Unidad creada / 400: Validación / 409: Duplicada |
| FormularioEditar | Cargar datos | GET /unidades-negocio/:tipo/:codigo | GET | 200: Unidad completa |
| FormularioEditar | Actualizar unidad | PUT /unidades-negocio/:tipo/:codigo | PUT | 200: Actualizada / 404: No encontrada / 409: Jerarquía inválida |
| TablaUnidades | Eliminar unidad | DELETE /unidades-negocio/:tipo/:codigo | DELETE | 200: Eliminada / 404: No encontrada / 409: Tiene hijas |
| VistaArbol | Cargar árbol | GET /unidades-negocio/arbol?vigente={} | GET | 200: Árbol jerárquico |

## 5. Flujos de Usuario

### 5.1 Flujo: Crear Nueva Unidad de Negocio

1. Usuario abre vista principal `/unidades-negocio`
2. Sistema muestra tabla de unidades existentes + SearchBar
3. Usuario hace clic en botón "Agregar" (verde)
4. Sistema navega a `/unidades-negocio/crear`
5. Sistema carga tipos de unidad (GET /tipos-unidad)
6. Sistema carga comunas SII (GET /comunas) - endpoint externo
7. Sistema muestra formulario vacío con dropdowns cargados
8. Usuario completa campos requeridos:
   - Selecciona tipo de unidad
   - Ingresa nombre
   - Ingresa dirección
   - Ingresa teléfono y fax
   - Ingresa email (opcional)
   - Selecciona comuna SII
   - Selecciona unidad padre (opcional)
   - Deja vigente en ON
9. Sistema valida campos en tiempo real (blur):
   - Nombre: max 50 chars
   - Email: formato válido
   - Teléfono/Fax: formato válido
10. Usuario hace clic en botón "Guardar" (check verde)
11. Sistema ejecuta POST /unidades-negocio con datos del formulario
12. **Si respuesta 201 Created**:
    - Sistema muestra alerta éxito: "Unidad de negocio creada correctamente"
    - Sistema navega de vuelta a `/unidades-negocio`
    - Sistema recarga tabla con nueva unidad visible
13. **Si respuesta 400 Bad Request**:
    - Sistema muestra errores de validación bajo cada campo
    - Usuario corrige errores y vuelve a intentar
14. **Si respuesta 409 Conflict**:
    - Sistema muestra alerta: "Ya existe una unidad con el mismo nombre"
    - Usuario modifica nombre y vuelve a intentar

**Cancelar operación:**
- Usuario hace clic en botón "Cancelar" (X roja) en cualquier momento
- Sistema descarta cambios y navega de vuelta a `/unidades-negocio`

### 5.2 Flujo: Buscar Unidad de Negocio

1. Usuario abre vista principal `/unidades-negocio`
2. Sistema muestra tabla con todas las unidades vigentes (paginadas, 20 por página)
3. Usuario ingresa criterios de búsqueda:
   - Tipo de unidad: Selecciona "Departamento" del dropdown
   - Vigente: Deja en "Vigente" (default)
   - Nombre: Ingresa "Fiscal"
4. Usuario hace clic en botón "Buscar" (lupa)
5. Sistema ejecuta GET /unidades-negocio?tipoUnidad=2&vigente=1&nombre=Fiscal
6. **Si respuesta 200 OK con resultados**:
   - Sistema muestra tabla filtrada
   - Sistema muestra badges de filtros activos arriba de tabla: "Tipo: Departamento X", "Vigente X", "Nombre: Fiscal X"
   - Sistema muestra total de resultados: "Mostrando 5 de 5 resultados"
7. **Si respuesta 200 OK sin resultados**:
   - Sistema muestra mensaje: "No se encontraron unidades con los criterios especificados"
   - Sistema ofrece botón "Limpiar Filtros"

**Limpiar filtros:**
- Usuario hace clic en botón "Limpiar" o en X de badge de filtro
- Sistema resetea formulario de búsqueda
- Sistema recarga tabla con todas las unidades vigentes

### 5.3 Flujo: Editar Unidad de Negocio

1. Usuario busca unidad en tabla
2. Usuario hace clic en icono lápiz (editar) de la fila
3. Sistema navega a `/unidades-negocio/:tipo/:codigo/editar`
4. Sistema ejecuta GET /unidades-negocio/:tipo/:codigo
5. **Si respuesta 200 OK**:
   - Sistema muestra formulario prellenado con datos actuales
   - Tipo Unidad y Código están read-only (grises, deshabilitados)
6. Usuario modifica campos:
   - Cambia nombre de "Departamento de Fiscalización" a "Departamento de Fiscalización y Control"
   - Actualiza teléfono
   - Cambia unidad padre
7. Sistema valida cambios (mismas validaciones que crear)
8. Usuario hace clic en botón "Actualizar" (check verde)
9. Sistema ejecuta PUT /unidades-negocio/:tipo/:codigo
10. **Si respuesta 200 OK**:
    - Sistema muestra alerta: "Unidad de negocio actualizada correctamente"
    - Sistema navega de vuelta a `/unidades-negocio`
    - Sistema muestra unidad actualizada en tabla
11. **Si respuesta 409 Conflict (jerarquía circular)**:
    - Sistema muestra alerta: "No se puede asignar como padre a una unidad hija"
    - Usuario selecciona otro padre válido

### 5.4 Flujo: Eliminar Unidad de Negocio

1. Usuario busca unidad en tabla
2. Usuario hace clic en icono papelera (eliminar) de la fila
3. Sistema ejecuta validación previa:
   - GET /unidades-negocio/:tipo/:codigo para verificar si tiene hijas
4. **Si unidad tiene hijas activas**:
   - Sistema muestra modal: "No se puede eliminar una unidad con 3 unidades hijas activas"
   - Botón "Eliminar" está deshabilitado
   - Solo botón "Cancelar" disponible
5. **Si unidad NO tiene hijas**:
   - Sistema muestra modal: "¿Está seguro de eliminar la unidad 'Departamento X'?"
   - Botón "Eliminar" está habilitado (rojo)
6. Usuario hace clic en "Eliminar"
7. Sistema ejecuta DELETE /unidades-negocio/:tipo/:codigo
8. **Si respuesta 200 OK**:
   - Sistema muestra alerta: "Unidad de negocio marcada como no vigente correctamente"
   - Sistema recarga tabla (unidad ya no aparece si filtro está en "Vigente")
9. **Si respuesta 409 Conflict**:
   - Sistema muestra alerta: "Error al eliminar. Intente nuevamente."

### 5.5 Flujo: Ver Árbol Jerárquico

1. Usuario hace clic en botón "Vista Árbol" en vista principal
2. Sistema navega a `/unidades-negocio/arbol`
3. Sistema ejecuta GET /unidades-negocio/arbol?vigente=1
4. **Si respuesta 200 OK**:
   - Sistema renderiza árbol con estructura jerárquica
   - Nodos raíz (sin padre) expandidos por defecto
   - Resto de niveles colapsados
5. Usuario hace clic en icono + de un nodo
6. Sistema expande nodo mostrando unidades hijas
7. Usuario hace clic en nombre de unidad
8. Sistema navega a formulario editar de esa unidad
9. Usuario hace clic en botón "Volver"
10. Sistema navega de vuelta a `/unidades-negocio`

## 6. Validaciones Frontend

### 6.1 Validaciones en Tiempo Real (blur)

| Campo | Validación | Mensaje Error |
|---|---|---|
| Tipo Unidad | Requerido | "Debe seleccionar un tipo de unidad" |
| Nombre | Requerido, 1-50 chars | "El nombre es requerido (máx 50 caracteres)" |
| Dirección | Requerido, 1-50 chars | "La dirección es requerida (máx 50 caracteres)" |
| Teléfono | Requerido, formato +XX-X-XXXXXXX | "Formato inválido. Use +56-2-3952000" |
| Fax | Requerido, formato +XX-X-XXXXXXX | "Formato inválido. Use +56-2-6964185" |
| Email | Opcional, RFC 5322 | "Formato de email inválido" |
| Comuna SII | Requerido | "Debe seleccionar una comuna" |

### 6.2 Validaciones al Enviar

Antes de ejecutar POST/PUT, validar:
1. Todos los campos requeridos completados
2. Formato de email válido (si se ingresó)
3. Formato de teléfono/fax válido
4. Tipo de unidad seleccionado
5. Comuna SII seleccionada

**Si alguna validación falla:**
- Marcar campo en rojo (Bootstrap `is-invalid`)
- Mostrar mensaje de error bajo el campo
- Deshabilitar botón "Guardar/Actualizar"
- Focus en primer campo inválido

## 7. Estados de UI

### 7.1 Estados de Carga

| Componente | Estado | Indicador Visual |
|---|---|---|
| TablaUnidades | Cargando datos | Skeleton loader o spinner sobre tabla |
| FormularioCrear | Cargando tipos/comunas | Spinner en dropdown |
| FormularioCrear | Guardando | Spinner en botón "Guardar", texto "Guardando..." |
| FormularioEditar | Cargando datos | Skeleton loader en formulario |
| VistaArbol | Cargando árbol | Spinner centrado |

### 7.2 Estados de Error

| Escenario | Indicador Visual | Acción Usuario |
|---|---|---|
| Error de red (sin conexión) | Alerta roja: "Error de conexión. Intente nuevamente." | Botón "Reintentar" |
| 404 Unidad no encontrada | Alerta amarilla: "Unidad de negocio no encontrada" | Botón "Volver a lista" |
| 400 Validación backend | Mensajes de error bajo cada campo | Corregir y reenviar |
| 409 Conflicto | Alerta naranja con mensaje específico (duplicado, jerarquía, hijas) | Ajustar datos y reenviar |
| 500 Error servidor | Alerta roja: "Error inesperado. Contacte soporte." | Botón "Volver" |

### 7.3 Estados de Éxito

| Acción | Indicador Visual | Duración |
|---|---|---|
| Unidad creada | Alerta verde: "Unidad de negocio creada correctamente" | 3 segundos, auto-cerrar |
| Unidad actualizada | Alerta verde: "Unidad de negocio actualizada correctamente" | 3 segundos, auto-cerrar |
| Unidad eliminada | Alerta verde: "Unidad de negocio marcada como no vigente correctamente" | 3 segundos, auto-cerrar |

## 8. Estado Global Vuex

**Módulo**: `store/modules/unidadesNegocio.js`

**State necesario:**
- `unidades`: Array de unidades cargadas
- `tiposUnidad`: Array de tipos de unidad (cache)
- `comunas`: Array de comunas SII (cache)
- `filtros`: Objeto con filtros activos (tipo, vigente, nombre)
- `pagination`: Objeto con info paginación (page, size, totalElements, totalPages)
- `loading`: Boolean (cargando datos)
- `error`: String o null (mensaje de error)

**Actions necesarias:**
- `fetchUnidades({ commit, state })`: Cargar lista con filtros y paginación
- `fetchTiposUnidad({ commit })`: Cargar tipos de unidad (una vez, cache)
- `fetchComunas({ commit })`: Cargar comunas (una vez, cache)
- `fetchUnidadById({ commit }, { tipo, codigo })`: Cargar unidad específica
- `createUnidad({ dispatch }, unidad)`: POST crear unidad
- `updateUnidad({ dispatch }, { tipo, codigo, unidad })`: PUT actualizar
- `deleteUnidad({ dispatch }, { tipo, codigo })`: DELETE soft-delete
- `fetchArbol({ commit }, { vigente })`: Cargar árbol jerárquico
- `setFiltros({ commit, dispatch }, filtros)`: Actualizar filtros y recargar lista
- `setPagination({ commit, dispatch }, { page, size })`: Cambiar página

**Mutations necesarias:**
- `SET_UNIDADES(state, unidades)`
- `SET_TIPOS_UNIDAD(state, tipos)`
- `SET_COMUNAS(state, comunas)`
- `SET_FILTROS(state, filtros)`
- `SET_PAGINATION(state, pagination)`
- `SET_LOADING(state, loading)`
- `SET_ERROR(state, error)`

## 9. Consideraciones de UX

### 9.1 Responsividad

- Vista lista: Desktop muestra tabla completa, mobile muestra cards apiladas
- Formularios: Campos de 100% ancho en mobile, 2 columnas en desktop
- Árbol jerárquico: Scrollable horizontal en mobile

### 9.2 Accesibilidad

- Labels asociados a inputs (for/id)
- ARIA labels en botones de acción (editar, eliminar, ver)
- Contraste de colores cumple WCAG 2.1 AA
- Navegación por teclado habilitada (Tab, Enter, Escape)

### 9.3 Feedback Visual

- Hover en filas de tabla (cambio de color)
- Hover en botones (cambio de opacidad)
- Disabled states visualmente distintos (opacidad 0.5)
- Loading states con spinners consistentes
- Transiciones suaves entre vistas (fade)

### 9.4 Prevención de Errores

- Confirmación antes de eliminar
- Warning al cambiar unidad padre si tiene hijas
- Validación en tiempo real (no esperar a submit)
- Mensajes de error descriptivos (no genéricos)

## 10. Estructura de Archivos Frontend

```
src/
├── views/
│   ├── UnidadesNegocioView.vue        # Vista principal lista
│   ├── UnidadNegocioCrearView.vue     # Vista crear
│   ├── UnidadNegocioEditarView.vue    # Vista editar
│   └── UnidadesNegocioArbolView.vue   # Vista árbol
├── components/
│   ├── unidades-negocio/
│   │   ├── SearchBar.vue              # Barra búsqueda + filtros
│   │   ├── TablaUnidades.vue          # Tabla paginada
│   │   ├── FormularioUnidad.vue       # Formulario crear/editar (reutilizable)
│   │   ├── ModalDetalleUnidad.vue     # Modal ver detalle + hijas
│   │   ├── ModalConfirmarEliminar.vue # Modal confirmación eliminar
│   │   └── ArbolJerarquico.vue        # Componente TreeView
│   └── common/
│       ├── Pagination.vue             # Paginación reutilizable
│       └── AlertMessage.vue           # Alertas éxito/error reutilizables
├── store/
│   └── modules/
│       └── unidadesNegocio.js         # Módulo Vuex
└── services/
    └── api/
        └── unidadesNegocio.js         # Axios calls a backend APIs
```

## 11. Referencias

### 11.1 Backend APIs

Ver [backend-apis.md](./backend-apis.md) para especificaciones completas de endpoints.

### 11.2 Modelo de Datos

Ver [README.md](./README.md) sección "Modelo de Datos Validado" para estructura Oracle.

### 11.3 Patrones de Otros Módulos

- **Módulo V (Usuarios Relacionados)**: Patrón SearchBar + Tabla + Formulario CRUD
- **Módulo VII (Funciones)**: Patrón drag-and-drop (NO aplicable a módulo VI)
- **Módulo VIII (Grupos)**: Patrón listas anidadas (similar a árbol jerárquico)
