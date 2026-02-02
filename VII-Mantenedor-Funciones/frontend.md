# Frontend - Módulo VII: Mantenedor de Funciones

**Stack Tecnológico:**  
Vue 3 + Composition API | Bootstrap 5.2 | Vuex 4.1 | Axios | acaj-intra-ui

---

## 1. Análisis de Mockups (Imágenes Cliente)

| # | Imagen | Descripción Visual | Componente Identificado | Propósito Funcional |
|---|--------|-------------------|------------------------|---------------------|
| 1 | ![image-0100](./images/image-0100.png) | Header verde "Control de Acceso" con logo puerta verde izquierda, info usuario derecha ("Rut autenticado: 15000000-1 | 30-06-2025 10:00"), tabs horizontales: "Usuario relacionado", "Unidad de negocio", **"Funciones" (activa en verde)**, "Mantenedores" (con dropdown). Debajo: fila blanca con toggle "No Vigente"/"Vigente" (Vigente activo en verde), label "Función", dropdown vacío, botón lupa verde, engranaje verde, botón "Agregar" verde, icono reloj verde derecha. Debajo: sección expandida verde oscuro "Función: Mantención general" con icono engranaje blanco izquierda, icono usuario blanco + "100" derecha (clickeable), toggle "No Vigente"/"Vigente" (Vigente ON verde), icono papelera gris extremo derecha. Debajo: acordeón verde claro colapsado/expandible "Opción: OT Mantenedor usuarios relacionados" con icono edificios verde izquierda, icono usuario + "10" derecha, botón (+) verde, papelera gris. Dentro del acordeón expandido: 3 filas verde claro "Atribución-Alcance: RE-N", "Atribución-Alcance: AR-R", "Atribución-Alcance: IN-U" cada una con toggle "No Vigente"/"Vigente" (todos ON), papelera gris derecha, última fila con botón (+) verde adicional. Debajo: segundo acordeón "Opción: F2890: Mantenedor Unidades de" con icono edificios, contador "10", (+) verde, papelera. Expandido muestra 2 filas "Atribución-Alcance: RE-N" (repetidas) con mismo patrón de toggles, papelera, última con (+). | HeaderNav + SearchBar + FuncionSection expandida + OpcionAccordion (colapsables) + AtribucionAlcanceItem (filas) | Pantalla principal mostrando función completa con estructura jerárquica: Función → Opciones (acordeones) → Atribuciones-Alcances (filas). Cada nivel muestra contador de usuarios clickeable. Permite gestionar vigencias y agregar nuevos elementos en cada nivel. |
| 2 | ![image-0102](./images/image-0102.png) | Header completo igual a imagen 1. SearchBar con toggle "No Vigente"/"Vigente" (Vigente ON), dropdown "Función" vacío, lupa, engranaje, botón "Agregar", reloj. Debajo: **formulario inline expandido** con fondo blanco. Primera fila verde oscuro con icono engranaje blanco izquierda, input verde "Ingrese nombre de la Función" (placeholder visible). Segunda fila verde claro con icono edificios verde izquierda, dropdown verde claro "Seleccione una Opción" (cerrado). Tercera fila verde más claro dividida en DOS columnas: izquierda con icono mano verde + dropdown "Seleccione una Atribución" (cerrado), derecha con icono mundo verde + dropdown "Seleccione un Alcance" (cerrado). Abajo: dos botones circulares icono X gris (cancelar) y check verde (guardar). | CreateFuncionForm inline | Formulario expandible inline (NO modal) para crear nueva función con primera opción, atribución y alcance en un solo paso. Se despliega al hacer clic en botón "Agregar". Similar a CreateGroupForm del módulo VIII. |
| 3 | ![image-0027](./images/image-0027.png) | Modal pequeño header verde "Alerta", body blanco "Registro guardado correctamente", botón verde "Aceptar". | SuccessAlert | **NOTA:** Componente estándar, NO incluir en flujos. Solo indicar mensaje específico en texto. |
| 4 | ![image-0105](./images/image-0105.png) | Modal header verde "Usuarios por Función" con botón X cierre blanco derecha. Dentro: fila verde claro con icono engranaje verde izquierda "Función: Usuario común web" y número "10" derecha. Tabla blanca debajo con columnas (Rut, Nombre, Vigencia Inicial, Vigencia Final), 3 registros con mismo RUT "15000000-1" y nombre "Adela Maria Lozano Arriagada" (datos repetidos son ilustrativos, en real serían usuarios distintos). Fechas: 05-08-2025 | 05-08-2026 primera fila, resto con "-" en Vigencia Final. Botón verde "Exportar a Excel" con icono Excel (X verde) abajo centro. | UserListModal | Modal para visualizar lista completa de usuarios asignados a una función específica con sus períodos de vigencia. Se abre al hacer clic en el contador de usuarios (ej: "100") de la FuncionSection. Permite exportar datos a Excel client-side. |
| 5 | ![image-0108](./images/image-0108.png) | Modal header verde "Alerta", texto "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada.", botones "Aceptar" (verde) y "Cancelar" (blanco). | ConfirmDialog | **NOTA:** Componente estándar, NO incluir en flujos. Solo indicar mensaje específico de confirmación en texto. |

---

## 2. Componentes Principales

### 2.1 Vista Principal: FuncionesView

**Ruta:** `/funciones`

**Descripción:**
Vista principal del mantenedor que muestra el buscador de funciones y permite administrar funciones, opciones y sus atribuciones-alcances. Utiliza layout jerárquico colapsable con tres niveles: Función → Opciones (acordeones) → Atribuciones-Alcances (filas).

**Estructura:**
- HeaderNav con tabs de navegación (Usuario relacionado, Unidad de negocio, **Funciones**, Mantenedores)
- SearchBar para filtrar y crear funciones
- Lista dinámica de FuncionSection (funciones encontradas)
- Cada FuncionSection contiene lista de OpcionAccordion
- Cada OpcionAccordion contiene lista de AtribucionAlcanceItem

**Imagen Referencia:**

![Vista principal](./images/image-0100.png)

### 2.2 SearchBar Component

**Imagen Referencia:**

![SearchBar](./images/image-0100.png)

**Funcionalidad:**
- Toggle "No Vigente"/"Vigente" (verde cuando Vigente activo, naranja cuando No Vigente)
- Label "Función"
- Dropdown selección de función (carga lista de funciones desde API)
- Botón lupa verde (buscar función seleccionada)
- Botón engranaje verde (funcionalidad administrativa)
- Botón "Agregar" verde (despliega CreateFuncionForm inline)
- Icono reloj verde derecha (abre historial del mantenedor)

**Comportamiento:**
- Dropdown funciones se llena con GET /api/v1/{rut}-{dv}/funciones
- Al seleccionar función y presionar lupa: busca función específica y despliega FuncionSection
- Toggle vigencia filtra dropdown de funciones (solo vigentes o todas)
- Botón "Agregar" despliega formulario inline CreateFuncionForm debajo del SearchBar

### 2.3 CreateFuncionForm Component

**Imagen Referencia:**

![Formulario crear función](./images/image-0102.png)

**Funcionalidad:**
Formulario inline expandible (NO modal) con estructura jerárquica en 3 filas:

**Fila 1 (verde oscuro):**
- Icono engranaje blanco izquierda
- Input texto "Ingrese nombre de la Función" (obligatorio, max 500 caracteres)

**Fila 2 (verde claro):**
- Icono edificios verde izquierda
- Dropdown "Seleccione una Opción" (obligatorio, carga opciones disponibles desde API)

**Fila 3 (verde más claro, dividida en 2 columnas):**
- Columna izquierda: Icono mano verde + Dropdown "Seleccione una Atribución" (obligatorio)
- Columna derecha: Icono mundo verde + Dropdown "Seleccione un Alcance" (obligatorio)

**Botones:**
- Círculo X gris (cancelar, siempre habilitado, colapsa formulario)
- Círculo check verde (guardar, se habilita cuando todos los campos obligatorios están completos)

**Validaciones:**
- Nombre función: obligatorio, max 500 caracteres, único (no duplicados vigentes)
- Opción: obligatorio, seleccionar de lista
- Atribución: obligatoria, seleccionar de lista
- Alcance: obligatorio, seleccionar de lista
- Combo opción-atribución-alcance debe ser único para esta función

**Comportamiento:**
- Se despliega al presionar botón "Agregar" del SearchBar
- Al guardar: POST /api/v1/{rut}-{dv}/funciones con función, opción, atribución, alcance
- Función se crea vigente por defecto
- Al guardar exitosamente: colapsa formulario, muestra mensaje "Registro guardado correctamente", actualiza lista
- Al cancelar: colapsa formulario sin cambios

### 2.4 FuncionSection Component

**Imagen Referencia:**

![Función expandida](./images/image-0100.png)

**Funcionalidad:**
Sección expandida (verde oscuro) que representa una función con sus opciones y atribuciones-alcances:

**Header (fila verde oscuro):**
- Icono engranaje blanco izquierda
- Texto "Función: [nombre]"
- Icono usuario blanco + número clickeable derecha (ej: "100", abre modal UserListModal)
- Toggle "No Vigente"/"Vigente" (verde cuando vigente, naranja cuando no vigente)
- Icono papelera gris extremo derecha (eliminar función con confirmación)

**Contenido:**
- Lista de OpcionAccordion (acordeones colapsables)
- Las opciones pueden reordenarse con Drag and Drop

**Acciones:**
- Clic en contador usuarios: abre UserListModal con lista de usuarios que tienen esta función
- Toggle vigencia: PUT /api/v1/{rut}-{dv}/funciones/{id}/vigencia
- Icono papelera: muestra confirmación "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada." → DELETE /api/v1/{rut}-{dv}/funciones/{id}

### 2.5 OpcionAccordion Component

**Imagen Referencia:**

![Opciones expandidas](./images/image-0100.png)

**Funcionalidad:**
Acordeón colapsable (verde claro) que agrupa atribuciones-alcances de una opción:

**Header acordeón (siempre visible):**
- Icono edificios verde izquierda
- Texto "Opción: [código aplicativo]: [nombre opción]" (ej: "OT Mantenedor usuarios relacionados")
- Icono usuario + número clickeable derecha (abre modal con usuarios que tienen esta opción)
- Botón (+) verde (agregar nueva atribución-alcance a esta opción)
- Icono papelera gris (eliminar opción completa con confirmación)

**Contenido colapsable:**
- Lista de AtribucionAlcanceItem (filas verdes claras)
- Se colapsa/expande al hacer clic en el nombre de la opción

**Acciones:**
- Clic en contador usuarios: abre UserListModal con usuarios de esta opción específica
- Botón (+): abre modal para agregar atribución-alcance a esta opción
- Icono papelera: muestra confirmación → DELETE /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}
- Drag and Drop: reordenar opciones dentro de la función

### 2.6 AtribucionAlcanceItem Component

**Imagen Referencia:**

![Atribuciones-alcances](./images/image-0100.png)

**Funcionalidad:**
Fila individual (verde claro) que representa una combinación atribución-alcance:

**Contenido:**
- Texto "Atribución-Alcance: [código atribución]-[código alcance]" (ej: "RE-N", "AR-R", "IN-U")
- Tooltip al hacer hover muestra descripción completa de atribución y alcance
- Toggle "No Vigente"/"Vigente" (verde cuando vigente, naranja cuando no vigente)
- Icono papelera gris derecha (eliminar atribución-alcance)
- Última fila tiene botón (+) verde adicional para agregar nueva atribución-alcance

**Acciones:**
- Toggle vigencia: PUT /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id}/vigencia
- Icono papelera: muestra confirmación → DELETE /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id}
- Botón (+): abre modal para agregar nueva atribución-alcance a esta opción

### 2.7 UserListModal Component

**Imagen Referencia:**

![Modal usuarios por función](./images/image-0105.png)

**Funcionalidad:**
Modal que muestra la lista completa de usuarios asignados a una función específica:

**Header:**
- Título verde "Usuarios por Función"
- Botón X blanco derecha (cerrar modal)

**Contenido:**
- Fila verde claro con icono engranaje + "Función: [nombre]" + número total de usuarios
- Tabla blanca con columnas:
  - Rut (formato XX.XXX.XXX-X)
  - Nombre (nombre completo del usuario)
  - Vigencia Inicial (formato DD-MM-YYYY)
  - Vigencia Final (formato DD-MM-YYYY, o "-" si es vigencia indefinida)
- Botón verde "Exportar a Excel" con icono X verde abajo centro

**Comportamiento:**
- Se abre al hacer clic en el contador de usuarios de FuncionSection o OpcionAccordion
- Carga datos con GET /api/v1/{rut}-{dv}/funciones/{id}/usuarios
- Exportar Excel: genera archivo client-side con librería xlsx.js
- Ordenamiento por vigencia (vigentes primero)
- Sin paginación inicial (max 1000 usuarios esperados)

---

## 3. Mapeo Componentes → APIs

| Componente | Acción Usuario | API Endpoint | Método | Respuesta Esperada |
|------------|----------------|--------------|--------|-------------------|
| SearchBar | Cargar lista funciones | /api/v1/{rut}-{dv}/funciones?vigente={true\|false} | GET | 200: Array de funciones |
| SearchBar | Buscar función por ID | /api/v1/{rut}-{dv}/funciones/{id} | GET | 200: Función con opciones y atribuciones-alcances / 404: No encontrada |
| CreateFuncionForm | Cargar opciones disponibles | /api/v1/{rut}-{dv}/opciones | GET | 200: Array de opciones |
| CreateFuncionForm | Cargar atribuciones disponibles | /api/v1/{rut}-{dv}/atribuciones | GET | 200: Array de atribuciones |
| CreateFuncionForm | Cargar alcances disponibles | /api/v1/{rut}-{dv}/alcances | GET | 200: Array de alcances |
| CreateFuncionForm | Crear función nueva | /api/v1/{rut}-{dv}/funciones | POST | 201: Función creada / 400: Validación / 409: Duplicado |
| FuncionSection | Modificar vigencia función | /api/v1/{rut}-{dv}/funciones/{id}/vigencia | PUT | 200: Vigencia actualizada / 404: No encontrada |
| FuncionSection | Eliminar función | /api/v1/{rut}-{dv}/funciones/{id} | DELETE | 204: Eliminada / 404: No encontrada / 409: Tiene usuarios |
| FuncionSection | Ver usuarios de función | /api/v1/{rut}-{dv}/funciones/{id}/usuarios | GET | 200: Array usuarios con vigencias |
| OpcionAccordion | Ver usuarios de opción | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/usuarios | GET | 200: Array usuarios |
| OpcionAccordion | Agregar opción a función | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones | POST | 201: Opción agregada / 409: Ya existe |
| OpcionAccordion | Eliminar opción de función | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId} | DELETE | 204: Eliminada / 409: Tiene usuarios |
| OpcionAccordion | Reordenar opciones | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/orden | PUT | 200: Orden actualizado |
| AtribucionAlcanceItem | Agregar atribución-alcance | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances | POST | 201: Agregada / 409: Ya existe |
| AtribucionAlcanceItem | Modificar vigencia atrib-alc | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id}/vigencia | PUT | 200: Vigencia actualizada |
| AtribucionAlcanceItem | Eliminar atribución-alcance | /api/v1/{rut}-{dv}/funciones/{funcionId}/opciones/{opcionId}/atribuciones-alcances/{id} | DELETE | 204: Eliminada |

---

## 4. Flujos de Usuario

### 4.1 Buscar Función Existente

**Precondición:** Usuario autenticado con perfil Administrador Nacional o Consulta

**Flujo:**
1. Usuario accede a la vista Funciones (tab "Funciones" en header)
2. Sistema muestra SearchBar con toggle en "Vigente" por defecto
3. Sistema carga dropdown de funciones vigentes (GET /funciones?vigente=true)
4. Usuario selecciona función del dropdown
5. Usuario presiona botón lupa verde
6. Sistema busca función (GET /funciones/{id})
7. Sistema despliega FuncionSection con:
   - Header función con nombre, contador usuarios, toggle vigencia, papelera
   - Lista de OpcionAccordion (colapsados por defecto)
8. Usuario puede expandir acordeones para ver atribuciones-alcances

**Variante - Buscar No Vigentes:**
- Usuario cambia toggle a "No Vigente"
- Sistema recarga dropdown con funciones no vigentes (GET /funciones?vigente=false)
- Usuario selecciona y busca función no vigente

### 4.2 Crear Nueva Función

**Precondición:** Usuario autenticado con perfil Administrador Nacional

**Flujo:**
1. Usuario presiona botón "Agregar" verde del SearchBar
2. Sistema despliega CreateFuncionForm inline con 3 filas:
   - Fila 1: Input nombre función (vacío)
   - Fila 2: Dropdown opciones (carga GET /opciones)
   - Fila 3: Dropdowns atribución (GET /atribuciones) y alcance (GET /alcances)
3. Usuario ingresa nombre función (ej: "Usuario común web")
4. Usuario selecciona opción del dropdown (ej: "OT Mantenedor usuarios relacionados")
5. Usuario selecciona atribución del dropdown (ej: "RE - Registro")
6. Usuario selecciona alcance del dropdown (ej: "N - Nacional")
7. Sistema valida campos completos y habilita botón check verde
8. Usuario presiona botón check verde
9. Sistema valida:
   - Nombre función único (no existe función vigente con mismo nombre)
   - Combo opción-atribución-alcance válido
10. Sistema crea función vigente (POST /funciones con body: {nombre, opcionId, atribucionId, alcanceId})
11. Sistema muestra mensaje "Registro guardado correctamente"
12. Sistema colapsa CreateFuncionForm
13. Sistema actualiza lista mostrando nueva función creada

**Variante - Cancelar Creación:**
- Usuario presiona botón X gris en cualquier momento
- Sistema colapsa CreateFuncionForm sin guardar cambios

**Variante - Validación Fallida:**
- Sistema muestra mensaje error específico:
  - "Ya existe una función vigente con este nombre"
  - "La combinación opción-atribución-alcance ya existe para esta función"

### 4.3 Modificar Vigencia de Función

**Precondición:** Función desplegada en FuncionSection

**Flujo:**
1. Usuario observa función vigente (toggle verde en "Vigente")
2. Usuario hace clic en toggle para cambiar a "No Vigente"
3. Sistema valida que función puede ser desactivada
4. Sistema actualiza vigencia (PUT /funciones/{id}/vigencia con body: {vigente: false})
5. Sistema cambia toggle a naranja "No Vigente"
6. Sistema propaga cambio a todas las opciones y atribuciones-alcances (quedan no vigentes en cascada)

**Variante - Activar Función No Vigente:**
- Usuario cambia toggle de "No Vigente" a "Vigente"
- Sistema actualiza vigencia a true
- Función queda vigente (opciones y atrib-alc mantienen su estado individual)

### 4.4 Eliminar Función

**Precondición:** Función desplegada en FuncionSection

**Flujo:**
1. Usuario presiona icono papelera gris del header de FuncionSection
2. Sistema muestra confirmación: "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."
3. Usuario presiona "Aceptar"
4. Sistema valida que función no tiene usuarios asignados
5. Sistema elimina función y todas sus opciones y atribuciones-alcances en cascada (DELETE /funciones/{id})
6. Sistema oculta FuncionSection de la vista
7. Sistema muestra mensaje "Función eliminada correctamente"

**Variante - Cancelar Eliminación:**
- Usuario presiona "Cancelar" en confirmación
- Sistema cierra diálogo sin cambios

**Variante - Función con Usuarios:**
- Sistema detecta que función tiene usuarios asignados
- Sistema muestra mensaje error: "No se puede eliminar la función porque tiene usuarios asignados. Primero debe reasignar o eliminar los usuarios."

### 4.5 Agregar Opción a Función

**Precondición:** Función desplegada en FuncionSection

**Flujo:**
1. Usuario presiona botón (+) verde al final de la lista de opciones
2. Sistema abre modal "Agregar opción a la función"
3. Modal muestra:
   - Dropdown "Seleccione una Opción" (carga opciones NO usadas en esta función)
   - Dropdown "Seleccione una Atribución"
   - Dropdown "Seleccione un Alcance"
   - Botón (+) verde para agregar más atribuciones-alcances
4. Usuario selecciona opción (ej: "F2890: Mantenedor Unidades")
5. Usuario selecciona atribución (ej: "RE - Registro")
6. Usuario selecciona alcance (ej: "R - Regional")
7. Usuario presiona botón (+) verde para agregar segunda atribución-alcance
8. Sistema agrega nueva fila con dropdowns vacíos
9. Usuario selecciona segunda atribución-alcance (ej: "AR - Archivo", "N - Nacional")
10. Usuario presiona botón "Agregar"
11. Sistema valida:
    - Opción no existe en la función
    - Atribuciones-alcances únicos (no duplicados)
12. Sistema crea opción con atribuciones-alcances (POST /funciones/{id}/opciones)
13. Sistema cierra modal
14. Sistema muestra mensaje "Registro guardado correctamente"
15. Sistema actualiza FuncionSection agregando nuevo OpcionAccordion

**Variante - Cancelar:**
- Usuario presiona X en modal
- Sistema cierra modal sin cambios

### 4.6 Eliminar Opción de Función

**Precondición:** Función con al menos una opción desplegada

**Flujo:**
1. Usuario presiona icono papelera gris del OpcionAccordion
2. Sistema muestra confirmación: "¿Está seguro que desea eliminar este registro? Perderá toda la información asociada."
3. Usuario presiona "Aceptar"
4. Sistema valida que opción no tiene usuarios asignados
5. Sistema elimina opción y todas sus atribuciones-alcances (DELETE /funciones/{id}/opciones/{opcionId})
6. Sistema oculta OpcionAccordion de la vista
7. Sistema muestra mensaje "Opción eliminada correctamente"

**Variante - Opción con Usuarios:**
- Sistema detecta que opción tiene usuarios asignados
- Sistema muestra mensaje error: "No se puede eliminar la opción porque tiene usuarios asignados."

### 4.7 Modificar Vigencia de Atribución-Alcance

**Precondición:** OpcionAccordion expandido mostrando atribuciones-alcances

**Flujo:**
1. Usuario observa atribución-alcance vigente (toggle verde)
2. Usuario hace clic en toggle para cambiar a "No Vigente"
3. Sistema actualiza vigencia (PUT /funciones/{id}/opciones/{opcionId}/atribuciones-alcances/{id}/vigencia)
4. Sistema cambia toggle a naranja "No Vigente"

### 4.8 Agregar Atribución-Alcance a Opción

**Precondición:** OpcionAccordion expandido

**Flujo:**
1. Usuario presiona botón (+) verde de la última fila de atribuciones-alcances
2. Sistema abre modal "Agregar atribución-alcance"
3. Modal muestra:
   - Dropdown "Seleccione una Atribución"
   - Dropdown "Seleccione un Alcance"
   - Botón "Agregar"
4. Usuario selecciona atribución y alcance
5. Usuario presiona "Agregar"
6. Sistema valida que combo atribución-alcance no existe en esta opción
7. Sistema crea atribución-alcance vigente (POST /funciones/{id}/opciones/{opcionId}/atribuciones-alcances)
8. Sistema cierra modal
9. Sistema muestra mensaje "Registro guardado correctamente"
10. Sistema agrega nueva fila AtribucionAlcanceItem al acordeón

### 4.9 Ver Usuarios de Función

**Precondición:** Función desplegada en FuncionSection

**Flujo:**
1. Usuario hace clic en contador de usuarios del header de FuncionSection (ej: icono usuario + "100")
2. Sistema abre modal "Usuarios por Función"
3. Sistema carga usuarios (GET /funciones/{id}/usuarios)
4. Sistema muestra tabla con columnas: Rut, Nombre, Vigencia Inicial, Vigencia Final
5. Sistema muestra total de usuarios en header (ej: "Función: Usuario común web" + "100")
6. Usuario puede revisar lista de usuarios
7. (Opcional) Usuario presiona "Exportar a Excel"
8. Sistema genera archivo Excel client-side con datos de la tabla
9. Sistema descarga archivo "usuarios-funcion-[nombre]-[fecha].xlsx"
10. Usuario cierra modal presionando X

**Nota:** Mismo flujo aplica para ver usuarios de OpcionAccordion (GET /funciones/{id}/opciones/{opcionId}/usuarios)

### 4.10 Reordenar Opciones con Drag and Drop

**Precondición:** Función con múltiples opciones desplegada

**Flujo:**
1. Usuario hace clic y mantiene presionado sobre el header de un OpcionAccordion
2. Sistema muestra cursor de arrastre
3. Usuario arrastra opción hacia arriba o abajo
4. Sistema muestra indicador visual de posición de inserción
5. Usuario suelta opción en nueva posición
6. Sistema actualiza orden (PUT /funciones/{id}/opciones/orden con body: [{opcionId: 1, orden: 2}, {opcionId: 2, orden: 1}])
7. Sistema reordena visualmente las opciones

---

## 5. Validaciones Frontend

### 5.1 CreateFuncionForm

**Campo: Nombre Función**
- Obligatorio: "El nombre de la función es obligatorio"
- Máximo 500 caracteres: "El nombre no puede exceder 500 caracteres"
- Solo letras, números, espacios, guiones: "El nombre solo puede contener letras, números, espacios y guiones"

**Campo: Opción**
- Obligatorio: "Debe seleccionar una opción"

**Campo: Atribución**
- Obligatorio: "Debe seleccionar una atribución"

**Campo: Alcance**
- Obligatorio: "Debe seleccionar un alcance"

### 5.2 Modificar Vigencia

**Función:**
- Si tiene usuarios asignados: advertencia "Esta función tiene [N] usuarios asignados. Al desactivarla, los usuarios perderán acceso. ¿Desea continuar?"

**Atribución-Alcance:**
- Si tiene usuarios asignados: advertencia similar

### 5.3 Eliminar Función/Opción

**Función:**
- Si tiene usuarios: bloquear eliminación con mensaje "No se puede eliminar la función porque tiene usuarios asignados"

**Opción:**
- Si tiene usuarios: bloquear eliminación con mensaje similar

### 5.4 Agregar Opción/Atribución-Alcance

**Duplicados:**
- Validar que combo opción-atribución-alcance no exista en la función
- Mensaje: "La combinación ya existe para esta función"

---

## 6. Estados de Carga y Errores

### 6.1 SearchBar
- **Loading:** Mostrar spinner en dropdown mientras carga funciones
- **Error:** Mostrar mensaje "Error al cargar funciones. Intente nuevamente."
- **Sin resultados:** Dropdown vacío con mensaje "No hay funciones disponibles"

### 6.2 CreateFuncionForm
- **Loading:** Deshabilitar botón check y mostrar spinner durante guardado
- **Error 409:** Mostrar mensaje "Ya existe una función vigente con este nombre"
- **Error 400:** Mostrar mensaje de validación específico del backend
- **Error 500:** Mostrar mensaje "Error al guardar la función. Intente nuevamente."

### 6.3 FuncionSection
- **Loading:** Mostrar skeleton de función mientras carga detalles
- **Error 404:** Mostrar mensaje "Función no encontrada"
- **Error eliminar 409:** Mostrar mensaje "No se puede eliminar la función porque tiene usuarios asignados"

### 6.4 UserListModal
- **Loading:** Mostrar spinner en tabla mientras carga usuarios
- **Sin usuarios:** Mostrar mensaje "No hay usuarios asignados a esta función"
- **Error:** Mostrar mensaje "Error al cargar usuarios. Intente nuevamente."

---

## 7. Checklist de Implementación

**Componentes:**
- [ ] HeaderNav con tabs de navegación
- [ ] SearchBar con toggle vigencia, dropdown funciones, botones acción
- [ ] CreateFuncionForm inline con 3 filas jerárquicas
- [ ] FuncionSection con header colapsable
- [ ] OpcionAccordion con drag and drop
- [ ] AtribucionAlcanceItem con toggle vigencia
- [ ] UserListModal con tabla y exportar Excel
- [ ] ConfirmDialog reutilizable
- [ ] SuccessAlert reutilizable

**Funcionalidades:**
- [ ] Buscar función por dropdown y lupa
- [ ] Filtrar funciones vigentes/no vigentes
- [ ] Crear función con opción, atribución y alcance inicial
- [ ] Modificar vigencia de función (cascada a opciones y atrib-alc)
- [ ] Eliminar función (validar usuarios asignados)
- [ ] Expandir/colapsar OpcionAccordion
- [ ] Agregar opción a función con múltiples atribuciones-alcances
- [ ] Eliminar opción (validar usuarios)
- [ ] Agregar atribución-alcance a opción
- [ ] Eliminar atribución-alcance
- [ ] Modificar vigencia de atribución-alcance
- [ ] Reordenar opciones con drag and drop
- [ ] Ver usuarios de función en modal
- [ ] Ver usuarios de opción en modal
- [ ] Exportar usuarios a Excel client-side
- [ ] Abrir historial del mantenedor

**Validaciones:**
- [ ] Nombre función obligatorio, max 500 caracteres, único
- [ ] Campos obligatorios en formularios
- [ ] Duplicados en opciones y atribuciones-alcances
- [ ] Validar usuarios asignados antes de eliminar
- [ ] Advertencia al desactivar vigencia con usuarios

**Integraciones API:**
- [ ] GET /funciones (con filtro vigencia)
- [ ] GET /funciones/{id}
- [ ] POST /funciones
- [ ] PUT /funciones/{id}/vigencia
- [ ] DELETE /funciones/{id}
- [ ] GET /funciones/{id}/usuarios
- [ ] POST /funciones/{id}/opciones
- [ ] DELETE /funciones/{id}/opciones/{opcionId}
- [ ] PUT /funciones/{id}/opciones/orden
- [ ] GET /funciones/{id}/opciones/{opcionId}/usuarios
- [ ] POST /funciones/{id}/opciones/{opcionId}/atribuciones-alcances
- [ ] PUT /funciones/{id}/opciones/{opcionId}/atribuciones-alcances/{id}/vigencia
- [ ] DELETE /funciones/{id}/opciones/{opcionId}/atribuciones-alcances/{id}
- [ ] GET /opciones (para dropdowns)
- [ ] GET /atribuciones (para dropdowns)
- [ ] GET /alcances (para dropdowns)

