# Frontend - Módulo VIII: Mantenedor de Grupos

**Stack Tecnológico:**  
Vue 3 + Composition API | Bootstrap 5.2 | Vuex 4.1 | Axios | acaj-intra-ui

---

## 1. Análisis de Mockups (Imágenes Cliente)

| # | Imagen | Descripción Visual | Componente Identificado | Propósito Funcional |
|---|--------|-------------------|------------------------|---------------------|
| 1 | ![image-0135](./images/image-0135.png) | Header verde "Control de Acceso" con logo puerta verde izquierda, info usuario derecha ("Rut autenticado: 15000000-1 | 30-06-2025 10:00"), tabs horizontales: "Usuario relacionado", "Unidad de negocio", "Funciones", "Mantenedores" (con dropdown). Debajo: fila blanca con toggle "No Vigente"/"Vigente" (Vigente activo en verde), label "Grupo", input dropdown vacío, botón lupa verde, engranaje verde, botón "Agregar" verde, icono reloj verde derecha. | HeaderNav + SearchBar vacío | Estado inicial de búsqueda sin grupo seleccionado. Toggle en "Vigente" por defecto. |
| 2 | ![image-0127](./images/image-0127.png) | Header completo (igual image-0135) + SearchBar con dropdown mostrando grupo seleccionado. Debajo: fila verde oscuro expandida "Grupo: Sistema OT" con icono estrella blanco izquierda, icono usuario blanco + "100" centro-derecha (clickeable), toggle "No Vigente"/"Vigente" (ON verde) derecha, icono papelera gris extremo derecha. Debajo: acordeón verde claro colapsado "Título 1: OT Reportes" con icono carpeta, flecha abajo (expandible). Expandido muestra 3 filas verde oscuro: "Función 1: csdfcasc", "Función 2", "Función 3" cada una con icono engranaje verde izquierda, icono papelera gris derecha, botón (+) verde extremo derecha. Debajo otro acordeón verde claro colapsado "Título 2: OT Opciones para jefaturas" con 2 funciones (Función 1, Función 2), mismo patrón de iconos. | GroupSection + TituloAccordion + FuncionItem | Visualización completa de grupo seleccionado con estructura jerárquica: grupo → títulos (acordeones) → funciones (lista). |
| 3 | ![image-0129](./images/image-0129.png) | Header completo + SearchBar con dropdown "Grupo" vacío. Debajo: bloque expandido con fondo blanco. Primera fila verde oscuro con icono estrella blanco izquierda, input verde "Ingrese nombre del Grupo" (placeholder visible), toggle "No Vigente"/"Vigente" (Vigente ON verde) derecha. Segunda fila verde claro con icono carpeta verde izquierda, input verde claro "Ingrese nombre del Título" (placeholder visible). Tercera fila verde más claro con icono engranaje verde izquierda, dropdown verde claro "Seleccione Función" (cerrado). Abajo: dos botones circulares icono X gris (cancelar) y check verde (guardar). | CreateGroupForm inline | Formulario expandible inline (NO modal) para crear grupo nuevo con primer título y función en un solo paso. Se despliega debajo del SearchBar al hacer clic en botón "Agregar". |
| 4 | ![image-0027](./images/image-0027.png) | Modal pequeño header verde "Alerta", body blanco "Registro guardado correctamente", botón verde "Aceptar" | SuccessAlert | **NOTA:** Componente estándar, NO incluir en flujos. Solo indicar mensaje específico. |
| 5 | ![image-0132](./images/image-0132.png) | Modal header verde "Usuarios por Grupo" con botón X cierre. Dentro: fila verde claro con icono verde izquierda "Grupo: Sistema OT" y número "100" derecha. Tabla blanca debajo con columnas (Rut, Nombre, Vigencia Inicial, Vigencia Final), 3 registros ejemplo "15000000-1 | Adela Maria Lozano Arriagada | 05-08-2025 | 05-08-2026". Botón verde "Exportar a Excel" con icono Excel abajo derecha. | UserListModal | Visualizar lista completa de usuarios asignados al grupo con sus períodos de vigencia. Permite exportar datos a Excel. |
| 6 | ![image-0034](./images/image-0034.png) | Modal header verde "Alerta", texto "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada.", botones "Aceptar" (verde) y "Cancelar" (blanco) | ConfirmDialog | **NOTA:** Componente estándar, NO incluir en flujos. Solo indicar mensaje específico. |
| 7 | ![image-0139](./images/image-0139.png) | Modal header verde "Agregar Título" con botón X blanco cierre derecha. Body: input verde claro con icono carpeta verde "Ingrese Título" (placeholder). Debajo label "Funciones del título:". Fila con dropdown verde claro "Seleccione la Función" (cerrado) con icono engranaje verde izquierda, botón circular (+) verde derecha. Debajo área vacía para funciones seleccionadas. Abajo botón rectangular verde "Agregar" centrado. | AddTituloModal | Modal para agregar nuevo título a grupo existente. Permite seleccionar múltiples funciones antes de guardar (botón + agrega función a lista temporal). |
| 8 | ![image-0143](./images/image-0143.png) | Modal header verde "Agregar Función" con botón X blanco cierre derecha. Body: fila verde claro read-only con icono carpeta verde "Título 1: fccfgfg" (no editable, muestra título seleccionado). Debajo dropdown verde claro "Seleccione la Función" (cerrado) con icono engranaje verde izquierda, botón circular (+) verde derecha. Debajo área vacía. Abajo botón rectangular verde "Agregar" centrado. | AddFuncionModal | Modal para agregar funciones adicionales a un título específico ya existente. Título se muestra read-only (contexto). Permite agregar múltiples funciones (botón + agrega a lista temporal). |

---

## 2. Componentes Principales y Funcionalidades

### 2.1 Vista Principal: GruposView.vue

**Ruta:** `/grupos`

**Elementos Visuales:**
- SearchBar con dropdown grupos + toggle vigente + lupa
- CreateGroupForm inline expandible (debajo del SearchBar, visible al crear)
- GroupSection expandida con títulos colapsables
- Cada título contiene lista de funciones con botones acción

---

### 2.2 SearchBar Component

**Imagen Referencia Estado Inicial:**

![SearchBar vacío](./images/image-0135.png)

**Imagen Referencia Después de Buscar (con GroupSection):**

![Grupo expandido](./images/image-0127.png)

**Funcionalidad:**
- Dropdown "Seleccione grupo" (carga dinámica desde GET /grupos/buscar)
- Toggle "Vigente" (azul activo / gris inactivo)
  - Activo: filtra solo grupos con GRUP_VIGENTE='S'
  - Inactivo: muestra todos los grupos
- Botón lupa: carga grupo seleccionado con sus títulos y funciones
- Botón "+ Agregar grupo nuevo": expande CreateGroupForm inline

**Validaciones:**
- Dropdown: requerido para buscar
- Toggle: opcional, default=activo (vigentes)

**APIs Consumidas:**
```
GET /acaj-ms/api/v1/{rut-auth}/grupos/buscar?vigente=true
Response 200: [{id, nombreGrupo, vigente}, ...]

GET /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}
Response 200: {id, nombreGrupo, vigente, titulos: [{id, titulo, orden, funciones: []}]}
```

**Flujo Buscar Grupo:**
1. Usuario selecciona grupo del dropdown
2. Click lupa (o Enter)
3. Ejecuta GET /grupos/{grupoId}
4. Si 200: cargar grupo, renderizar GroupSection
5. Si error: mostrar mensaje error

**Flujo Toggle Vigente:**
1. Usuario cambia toggle
2. Recargar GET /grupos/buscar con param vigente=true/false
3. Actualizar opciones dropdown
4. Limpiar selección actual

---

### 2.3 CreateGroupForm Component (Inline, NO Modal)

**Imagen Referencia:**

![CreateGroupForm inline](./images/image-0129.png)

**Funcionalidad:**
- Formulario inline que se expande/colapsa debajo del SearchBar
- Input "Nombre grupo/título" (límite 100 chars grupo, 50 chars título)
- Dropdown "Seleccione la Función" (carga funciones vigentes)
- Botón X (cerrar/cancelar sin guardar)
- Botón ✓ (guardar grupo + título + función)

**Validaciones:**
- Nombre grupo/título: obligatorio, límite 100/50 chars
- Función: obligatoria, al menos 1

**API Consumida:**
```
GET /acaj-ms/api/v1/{rut-auth}/grupos/funciones/disponibles
Response 200: [{codigo: 10, descripcion: "Administrador"}, ...]

POST /acaj-ms/api/v1/{rut-auth}/grupos
Body: {
  nombreGrupo: "Grupo Nuevo",
  primerTitulo: "Título Inicial",
  funcionId: 10
}
Response 201: {id: 100, nombreGrupo, vigente: "S", titulos: [...]}
```

**Flujo Crear Grupo:**
1. Usuario click "+ Agregar grupo nuevo"
2. Formulario se expande inline (visible=true)
3. Usuario completa nombre grupo/título y selecciona función
4. Click ✓
5. Validar campos obligatorios
6. Ejecutar POST /grupos (crea grupo + título + función en transacción)
7. Si 201: colapsar form, cargar nuevo grupo en dropdown, mostrar alerta "Grupo creado correctamente"
8. Si 409: mostrar error "Grupo ya existe"
9. Si error: mostrar mensaje error

**Flujo Cancelar:**
1. Click X
2. Colapsar formulario sin ejecutar validaciones
3. Limpiar campos

---

### 2.4 GroupSection Component

**Imagen Referencia:**

![GroupSection](./images/image-0127.png)

**Funcionalidad:**
- Card principal con header:
  - Icono grupo + "Grupo: [nombre]"
  - Badge "Vigente" (verde) o "No vigente" (gris)
  - Botón usuarios (icono personas): abre UserListModal
  - Toggle vigencia (switch): actualiza GRUP_VIGENTE
  - Botón (+) agregar título: abre AddTituloModal
  - Botón eliminar grupo (basurero)

- Body: Lista de TituloAccordion expandibles

**Reglas Visuales:**
- Badge verde si GRUP_VIGENTE='S'
- Badge gris si GRUP_VIGENTE='N'
- Botón eliminar grupo: deshabilitado si grupo vigente
- Botón eliminar título: deshabilitado si es el único título del grupo

**APIs Consumidas:**
```
PUT /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/vigencia
Body: {vigente: "S" | "N"}
Response 200: {mensaje: "Vigencia actualizada"}

DELETE /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}
Response 200: {mensaje: "Grupo eliminado"}
Response 409: {error: "Grupo vigente no puede eliminarse"}
```

**Flujo Toggle Vigencia:**
1. Usuario cambia switch
2. Ejecuta PUT /grupos/{grupoId}/vigencia
3. Si 200: actualizar badge en vista
4. Si error: revertir switch, mostrar error

**Flujo Eliminar Grupo:**
1. Usuario click basurero (solo si no vigente)
2. Abrir ConfirmDialog con mensaje "¿Está seguro de eliminar este grupo?"
3. Si Aceptar: DELETE /grupos/{grupoId}
4. Si 200: colapsar GroupSection, mostrar alerta "Grupo eliminado correctamente"
5. Si 409: mostrar error "Grupo vigente no puede eliminarse"

---

### 2.5 TituloAccordion Component

**Imagen Referencia:**

![TituloAccordion](./images/image-0127.png)

**Funcionalidad:**
- Acordeón colapsable por cada título
- Header azul claro:
  - Icono título + "Título: [nombre]"
  - Badge "Orden: [N]"
  - Botón (+) agregar función: abre AddFuncionModal
  - Botón eliminar título (basurero)
  - Icono flecha expandir/colapsar
- Body (expandido): Lista de FuncionItem en filas verdes

**Reglas:**
- Botón eliminar título: deshabilitado si es el único título del grupo
- Botón eliminar función: deshabilitado si es la única función del título

**APIs Consumidas:**
```
DELETE /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/titulos/{tituloId}
Response 200: {mensaje: "Título eliminado", funcionesEliminadas: N}
Response 409: {error: "No se puede eliminar el único título del grupo"}
```

**Flujo Eliminar Título:**
1. Usuario click basurero
2. Validar si es el único título (deshabilitado si COUNT=1)
3. Abrir ConfirmDialog con mensaje "¿Está seguro de eliminar este título?"
4. Si Aceptar: DELETE /titulos/{tituloId}
5. Si 200: remover título de vista (CASCADE elimina funciones), mostrar alerta "Título eliminado correctamente"
6. Si 409: mostrar error "No se puede eliminar el único título del grupo"

---

### 2.6 FuncionItem Component

**Imagen Referencia:**

![FuncionItem](./images/image-0127.png)

**Funcionalidad:**
- Fila verde con:
  - Checkbox (siempre checked, no interactivo según imagen)
  - "Función: [nombre función]"
  - Botón eliminar (X roja)

**API Consumida:**
```
DELETE /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}
Response 200: {mensaje: "Función eliminada"}
Response 409: {error: "No se puede eliminar la última función del título"}
```

**Flujo Eliminar Función:**
1. Usuario click X
2. Validar si es la última función del título (deshabilitado si COUNT=1)
3. Abrir ConfirmDialog con mensaje "¿Está seguro de eliminar esta función?"
4. Si Aceptar: DELETE /funciones/{funcionId}
5. Si 200: remover función de vista, mostrar alerta "Función eliminada correctamente"
6. Si 409: mostrar error "No se puede eliminar la última función"

---

### 2.7 UserListModal Component

**Imagen Referencia:**

![UserListModal](./images/image-0132.png)

**Funcionalidad:**
- Modal grande "Usuarios relacionados del Grupo [nombre]"
- Tabla con columnas:
  - RUT
  - Nombre
  - Fecha inicio vigencia
  - Fecha fin vigencia
- Botón "Exportar a Excel" (genera archivo .xlsx)
- Botón "Cerrar"

**API Consumida:**
```
GET /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/usuarios
Response 200: [{rut, dv, nombreCompleto, vigenciaInicio, vigenciaFin}, ...]
```

**Flujo:**
1. Usuario click botón usuarios desde GroupSection
2. Abre modal
3. Carga GET /grupos/{grupoId}/usuarios
4. Renderiza tabla con datos
5. Botón "Exportar a Excel": genera archivo client-side con biblioteca (xlsx.js)
6. Botón "Cerrar": cierra modal

---

### 2.8 AddTituloModal Component

**Imagen Referencia:**

![AddTituloModal](./images/image-0139.png)

**Funcionalidad:**
- Modal "Agregar Título al Grupo [nombre]"
- Input "Ingrese el Título" (límite 50 chars)
- Sección "Funciones del título":
  - Lista dinámica de dropdowns "Seleccione la Función"
  - Botón (+) para agregar más dropdowns
  - Al menos 1 función obligatoria
- Botón "Agregar" (verde)

**Validaciones:**
- Título: obligatorio, límite 50 chars
- Funciones: al menos 1 seleccionada

**APIs Consumidas:**
```
GET /acaj-ms/api/v1/{rut-auth}/grupos/funciones/disponibles
Response 200: [{codigo: 10, descripcion: "Administrador"}, ...]

POST /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/titulos
Body: {
  titulo: "Nuevo Título",
  funciones: [10, 15, 20]
}
Response 201: {id: 200, titulo, orden: 2, funciones: [...]}
```

**Flujo:**
1. Usuario click (+) agregar título desde GroupSection
2. Abre modal
3. Carga GET /funciones/disponibles
4. Usuario completa título y selecciona funciones
5. Click "Agregar"
6. Validar campos obligatorios
7. Ejecutar POST /grupos/{grupoId}/titulos
8. Si 201: cerrar modal, refrescar grupo, mostrar alerta "Título agregado correctamente"
9. Si 409: mostrar error "Título ya existe en este grupo"

---

### 2.9 AddFuncionModal Component

**Imagen Referencia:**

![AddFuncionModal](./images/image-0143.png)

**Funcionalidad:**
- Modal "Agregar Función al Título [nombre]"
- Alerta info mostrando "Título: [nombre]" (read-only)
- Lista dinámica de dropdowns "Seleccione la Función"
- Botón (+) para agregar más dropdowns
- Botón "Agregar"

**API Consumida:**
```
GET /acaj-ms/api/v1/{rut-auth}/grupos/funciones/disponibles
Response 200: [{codigo: 10, descripcion: "Administrador"}, ...]

POST /acaj-ms/api/v1/{rut-auth}/grupos/{grupoId}/titulos/{tituloId}/funciones
Body: {funciones: [10, 15]}
Response 201: {funcionesAgregadas: 2}
```

**Flujo:**
1. Usuario click (+) agregar función desde TituloAccordion
2. Abre modal
3. Carga GET /funciones/disponibles
4. Usuario selecciona funciones
5. Click "Agregar"
6. Ejecutar POST /titulos/{tituloId}/funciones
7. Si 201: cerrar modal, refrescar grupo, mostrar alerta "Funciones agregadas correctamente"
8. Si 409: mostrar error "Función ya asignada a este título"

---

## 3. Mapeo Completo: Componentes → APIs → BD

| Componente | Acción Usuario | API Endpoint | Método | Response | BD Tablas |
|------------|---------------|--------------|--------|----------|-----------|
| SearchBar | Listar grupos vigentes | `/grupos/buscar?vigente=true` | GET | 200: Array grupos | BR_GRUPOS (GRUP_VIGENTE='S') |
| SearchBar | Cargar grupo completo | `/grupos/{grupoId}` | GET | 200: Grupo con títulos y funciones | BR_GRUPOS + JOINs |
| CreateGroupForm | Listar funciones disponibles | `/grupos/funciones/disponibles` | GET | 200: Array funciones | BR_FUNCIONES (FUNS_VIGENTE=1) |
| CreateGroupForm | Crear grupo + título + función | `/grupos` | POST | 201: Grupo creado / 409: Ya existe | BR_GRUPOS, BR_TITULOS, BR_TITULOS_FUNCIONES |
| GroupSection | Actualizar vigencia grupo | `/grupos/{grupoId}/vigencia` | PUT | 200: Actualizado | GRUP_VIGENTE |
| GroupSection | Eliminar grupo | `/grupos/{grupoId}` | DELETE | 200: Eliminado / 409: Vigente | BR_GRUPOS (CASCADE títulos y funciones) |
| TituloAccordion | Eliminar título | `/grupos/{grupoId}/titulos/{tituloId}` | DELETE | 200: Eliminado / 409: Único título | BR_TITULOS (CASCADE funciones) |
| FuncionItem | Eliminar función | `/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}` | DELETE | 200: Eliminado / 409: Última función | BR_TITULOS_FUNCIONES |
| UserListModal | Listar usuarios del grupo | `/grupos/{grupoId}/usuarios` | GET | 200: Array usuarios | Vista/query compleja |
| AddTituloModal | Crear título con funciones | `/grupos/{grupoId}/titulos` | POST | 201: Título creado | BR_TITULOS, BR_TITULOS_FUNCIONES |
| AddFuncionModal | Agregar funciones a título | `/grupos/{grupoId}/titulos/{tituloId}/funciones` | POST | 201: Funciones agregadas | BR_TITULOS_FUNCIONES |

---

## 4. Flujos de Usuario Principales

### 4.1 Flujo: Buscar y Visualizar Grupo

1. Usuario abre vista /grupos
2. Carga GET /grupos/buscar (default vigente=true)
3. Selecciona grupo del dropdown
4. Click lupa
5. Ejecuta GET /grupos/{grupoId}
6. Si 200: Renderiza GroupSection con títulos colapsables y funciones

### 4.2 Flujo: Crear Grupo Nuevo

1. Click "+ Agregar grupo nuevo"
2. CreateGroupForm se expande inline debajo del SearchBar
3. Usuario ingresa nombre grupo/título y selecciona función
4. Click ✓
5. Ejecuta POST /grupos (transacción: grupo + primer título + función)
6. Si 201: Colapsa form, recarga dropdown, mostrar alerta "Grupo creado correctamente"
7. Nuevo grupo aparece seleccionado automáticamente

### 4.3 Flujo: Agregar Título con Funciones

1. Desde GroupSection, click (+) agregar título
2. Abre AddTituloModal
3. Usuario ingresa nombre título y selecciona 1+ funciones
4. Click "Agregar"
5. Ejecuta POST /grupos/{grupoId}/titulos
6. Si 201: Cierra modal, refresca GET /grupos/{grupoId}, mostrar alerta "Título agregado correctamente"
7. Nuevo título aparece expandido en la lista

### 4.4 Flujo: Eliminar Título (CASCADE funciones)

1. Usuario click eliminar título (solo si COUNT > 1)
2. Abre ConfirmDialog
3. Si Aceptar: DELETE /titulos/{tituloId}
4. Si 200: Refresca grupo (funciones eliminadas automáticamente)
5. Mostrar alerta "Título eliminado correctamente"

### 4.5 Flujo: Cambiar Vigencia Grupo

1. Usuario cambia toggle vigencia
2. Ejecuta PUT /grupos/{grupoId}/vigencia
3. Si 200: Actualiza badge (verde/gris), actualiza estado local
4. Muestra mensaje éxito breve

### 4.6 Flujo: Exportar Usuarios a Excel

1. Usuario click botón usuarios desde GroupSection
2. Abre UserListModal
3. Carga GET /grupos/{grupoId}/usuarios
4. Renderiza tabla con datos
5. Click "Exportar a Excel"
6. Genera archivo .xlsx client-side con biblioteca (xlsx.js)
7. Descarga automática

---

## 5. Validaciones Frontend Requeridas

| Campo | Validación | Regla | Mensaje Error |
|-------|-----------|-------|---------------|
| Nombre Grupo | Longitud | Máx 100 caracteres | "Nombre de grupo no puede exceder 100 caracteres" |
| Nombre Grupo | Obligatorio | No vacío | "Nombre de grupo obligatorio" |
| Nombre Título | Longitud | Máx 50 caracteres | "Nombre de título no puede exceder 50 caracteres" |
| Nombre Título | Obligatorio | No vacío | "Nombre de título obligatorio" |
| Función | Obligatorio | Al menos 1 seleccionada | "Debe seleccionar al menos una función" |
| Eliminar Título | Validación | COUNT > 1 | "No se puede eliminar el único título del grupo" |
| Eliminar Función | Validación | COUNT > 1 | "No se puede eliminar la última función del título" |
| Eliminar Grupo | Validación | GRUP_VIGENTE = 'N' | "No se puede eliminar un grupo vigente" |

---

## 6. Consideraciones Técnicas

### 6.1 Navegación
- Ruta principal: `/grupos`
- Modales: no cambian URL (usar v-model para visibilidad)

### 6.2 Loading States
- SearchBar: spinner durante GET /grupos/buscar y GET /grupos/{grupoId}
- CreateGroupForm: deshabilitar botones durante POST
- Toggle vigencia: loading inline durante PUT

### 6.3 Error Handling
- 409: Mensajes específicos según contexto (ej: "Grupo ya existe", "Grupo vigente no puede eliminarse")
- 404: "Grupo no encontrado"
- 500: "Error del servidor"

### 6.4 Feedback Visual
- Badges de estado: "Vigente" (verde), "No vigente" (gris)
- Botones deshabilitados según reglas de negocio
- Acordeones colapsables para títulos

### 6.5 Exportación Excel
- Usar biblioteca client-side: xlsx.js o SheetJS
- Columnas: RUT | Nombre | Fecha Inicio | Fecha Fin
- Nombre archivo: `Usuarios_Grupo_[nombreGrupo]_[fecha].xlsx`

---

## 7. Checklist Frontend Developer

- [ ] Implementar SearchBar con dropdown dinámico y toggle vigente
- [ ] Implementar CreateGroupForm inline (expandible, NO modal)
- [ ] Crear GroupSection con títulos colapsables (accordion)
- [ ] Implementar TituloAccordion y FuncionItem
- [ ] Crear modales: AddTituloModal, AddFuncionModal, UserListModal
- [ ] Validar estados botones (deshabilitar eliminar si único título/función, grupo vigente)
- [ ] Implementar exportación a Excel (xlsx.js)
- [ ] Testing: flujos crear grupo, agregar título, eliminar función
