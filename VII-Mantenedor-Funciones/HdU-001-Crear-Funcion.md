# HdU-001: Crear Función con Opción Inicial

## Información General

- **ID:** HdU-001
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 5 puntos de historia
- **Actor Principal:** Administrador Nacional

## Historia de Usuario

**Como** Administrador Nacional del Sistema Control de Acceso,  
**Quiero** crear una nueva función con su primera opción, atribución y alcance,  
**Para** poder agrupar opciones de aplicativos que posteriormente serán asignadas a usuarios y grupos del sistema.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "Análisis de Mockups" y componentes "CreateFuncionForm" y "FuncionSection".

## Criterios de Aceptación

### AC-001: Acceso al formulario de creación
**Dado que** soy un Administrador Nacional autenticado en el sistema,  
**Cuando** accedo a la vista de Funciones y presiono el botón "Agregar" del SearchBar,  
**Entonces** el sistema debe desplegar un formulario inline (NO modal) con 3 filas jerárquicas:
- Fila 1 (verde oscuro): Input "Ingrese nombre de la Función" con icono engranaje
- Fila 2 (verde claro): Dropdown "Seleccione una Opción" con icono edificios
- Fila 3 (verde más claro, 2 columnas): Dropdown "Seleccione una Atribución" con icono mano izquierda + Dropdown "Seleccione un Alcance" con icono mundo derecha
- Botones: X gris (cancelar, habilitado) y check verde (guardar, deshabilitado inicialmente)

### AC-002: Carga de datos en dropdowns
**Dado que** el formulario de creación está desplegado,  
**Cuando** el sistema carga los dropdowns,  
**Entonces** debe:
- Cargar opciones disponibles desde GET /api/v1/{rut}-{dv}/opciones
- Cargar atribuciones disponibles desde GET /api/v1/{rut}-{dv}/atribuciones
- Cargar alcances disponibles desde GET /api/v1/{rut}-{dv}/alcances
- Mostrar spinner mientras carga cada dropdown
- Ordenar opciones, atribuciones y alcances alfabéticamente

### AC-003: Validación de campos obligatorios
**Dado que** estoy completando el formulario de creación,  
**Cuando** ingreso información en los campos,  
**Entonces** el sistema debe:
- Validar nombre función: obligatorio, máximo 500 caracteres, solo letras/números/espacios/guiones
- Validar opción: obligatorio, debe seleccionar una opción de la lista
- Validar atribución: obligatoria, debe seleccionar una atribución de la lista
- Validar alcance: obligatorio, debe seleccionar un alcance de la lista
- Habilitar botón check verde solo cuando todos los campos estén completos y válidos
- Mostrar mensajes de error específicos debajo de cada campo con validación fallida

### AC-004: Validación de duplicados
**Dado que** he completado el formulario de creación,  
**Cuando** intento guardar una función,  
**Entonces** el sistema debe validar:
- No existe otra función vigente con el mismo nombre (case insensitive)
- Mostrar mensaje: "Ya existe una función vigente con este nombre" si hay duplicado
- Bloquear guardado si hay duplicado
- Permitir guardar si el nombre es único

### AC-005: Guardado exitoso de función
**Dado que** he completado correctamente el formulario de creación,  
**Cuando** presiono el botón check verde,  
**Entonces** el sistema debe:
- Mostrar spinner en botón check y deshabilitar formulario durante guardado
- Crear función con POST /api/v1/{rut}-{dv}/funciones con body:
  ```json
  {
    "nombre": "Usuario común web",
    "opcionId": 123,
    "atribucionId": 45,
    "alcanceId": 1,
    "vigente": true
  }
  ```
- Crear función vigente por defecto con código automático correlativo
- Crear opción asociada a la función
- Crear atribución-alcance asociado a la opción
- Colapsar formulario inline
- Mostrar mensaje: "Registro guardado correctamente"
- Actualizar lista mostrando nueva FuncionSection expandida con la opción creada

### AC-006: Cancelar creación
**Dado que** estoy en el formulario de creación (con o sin datos ingresados),  
**Cuando** presiono el botón X gris,  
**Entonces** el sistema debe:
- Colapsar formulario inline inmediatamente
- No guardar ningún cambio
- No mostrar mensaje de confirmación
- Volver al estado inicial del SearchBar

### AC-007: Manejo de errores de guardado
**Dado que** he completado el formulario de creación,  
**Cuando** ocurre un error al guardar,  
**Entonces** el sistema debe:
- Si error 409 (duplicado): mostrar "Ya existe una función vigente con este nombre"
- Si error 400 (validación backend): mostrar mensaje específico del servidor
- Si error 500 (error servidor): mostrar "Error al guardar la función. Intente nuevamente."
- Mantener formulario desplegado con datos ingresados
- Permitir al usuario corregir y reintentar
- Re-habilitar botón check verde después de mostrar error

### AC-008: Visualización de función creada
**Dado que** acabo de crear una función exitosamente,  
**Cuando** el sistema actualiza la lista,  
**Entonces** debe mostrar la nueva función con:
- FuncionSection expandida con header verde oscuro
- Nombre de la función
- Contador de usuarios (inicialmente "0")
- Toggle vigencia en "Vigente" (verde)
- Icono papelera habilitado
- OpcionAccordion expandido mostrando la opción creada
- AtribucionAlcanceItem mostrando la atribución-alcance creada con toggle vigente

### AC-009: Validación de formato de nombre
**Dado que** estoy ingresando el nombre de la función,  
**Cuando** escribo caracteres en el campo,  
**Entonces** el sistema debe:
- Aceptar letras (mayúsculas y minúsculas), números, espacios y guiones
- Rechazar caracteres especiales (@, #, $, %, etc.)
- Mostrar mensaje: "El nombre solo puede contener letras, números, espacios y guiones"
- Permitir máximo 500 caracteres
- Mostrar contador de caracteres "X/500"
- Bloquear escritura después de 500 caracteres

### AC-010: Persistencia en base de datos
**Dado que** se crea una función exitosamente,  
**Cuando** el sistema guarda la información,  
**Entonces** debe:
- Insertar registro en tabla FUNCION con código correlativo, nombre, vigencia=true, fecha_creacion
- Insertar registro en tabla FUNCION_OPCION con funcion_id, opcion_id, orden=1, vigencia=true
- Insertar registro en tabla FUNCION_OPCION_ATRIB_ALCANCE con funcion_opcion_id, atribucion_id, alcance_id, vigencia=true
- Registrar auditoría con usuario, fecha/hora, acción "Crear función", descripción "Se creó función [nombre]"

### AC-011: Validación de permisos
**Dado que** soy un usuario autenticado,  
**Cuando** intento acceder a crear una función,  
**Entonces** el sistema debe:
- Verificar que tengo perfil Administrador Nacional
- Si NO tengo perfil: ocultar botón "Agregar" del SearchBar
- Si perfil Consulta: mostrar vista en modo solo lectura
- Si intento crear vía API sin permisos: retornar HTTP 403 Forbidden con mensaje "No tiene permisos para crear funciones"

### AC-012: Coherencia de datos
**Dado que** selecciono una opción, atribución y alcance,  
**Cuando** guardo la función,  
**Entonces** el sistema debe:
- Validar que opcionId existe en tabla OPCION y está vigente
- Validar que atribucionId existe en tabla ATRIBUCION y está vigente
- Validar que alcanceId existe en tabla ALCANCE y está vigente
- Si alguno no existe o no está vigente: retornar HTTP 400 con mensaje específico
- Crear relaciones válidas con foreign keys correctas

## Flujos Principales

### Flujo 1: Crear función exitosamente

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.2 Crear Nueva Función".

**Precondición:** Usuario autenticado con perfil Administrador Nacional

1. Usuario accede a la vista Funciones (tab "Funciones" activo)
2. Usuario observa SearchBar con botón "Agregar" verde
3. Usuario presiona botón "Agregar"
4. Sistema despliega CreateFuncionForm inline con 3 filas
5. Sistema carga dropdowns (opciones, atribuciones, alcances)
6. Usuario ingresa nombre: "Usuario común web"
7. Usuario selecciona opción: "OT Mantenedor usuarios relacionados"
8. Usuario selecciona atribución: "RE - Registro"
9. Usuario selecciona alcance: "N - Nacional"
10. Sistema valida campos completos y habilita botón check verde
11. Usuario presiona botón check verde
12. Sistema valida nombre único (no existe función vigente con ese nombre)
13. Sistema guarda función vigente con POST /api/v1/{rut}-{dv}/funciones
14. Sistema colapsa CreateFuncionForm
15. Sistema muestra mensaje: "Registro guardado correctamente"
16. Usuario presiona "Aceptar" en mensaje
17. Sistema actualiza lista mostrando nueva FuncionSection con:
    - Header: "Función: Usuario común web", contador "0", toggle Vigente verde
    - OpcionAccordion: "Opción: OT Mantenedor usuarios relacionados", contador "0"
    - AtribucionAlcanceItem: "Atribución-Alcance: RE-N", toggle Vigente verde

### Flujo 2: Cancelar creación de función

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.2 Crear Nueva Función" - Variante "Cancelar Creación".

**Precondición:** CreateFuncionForm desplegado con datos parciales ingresados

1. Usuario ha ingresado nombre: "Nueva función"
2. Usuario ha seleccionado opción: "F2890: Mantenedor Unidades"
3. Usuario decide NO continuar con creación
4. Usuario presiona botón X gris
5. Sistema colapsa CreateFuncionForm inmediatamente
6. Sistema NO guarda ningún cambio
7. Sistema NO muestra mensaje de confirmación
8. Sistema vuelve a estado inicial del SearchBar
9. Si usuario presiona "Agregar" nuevamente, formulario aparece vacío

### Flujo 3: Validación de nombre duplicado

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.2 Crear Nueva Función" - Variante "Validación Fallida".

**Precondición:** Existe función vigente llamada "Usuario común web"

1. Usuario despliega CreateFuncionForm
2. Usuario ingresa nombre: "Usuario Común Web" (diferente capitalización)
3. Usuario selecciona opción, atribución y alcance
4. Sistema habilita botón check verde
5. Usuario presiona botón check verde
6. Sistema valida nombre con backend
7. Backend detecta duplicado (case insensitive)
8. Sistema muestra mensaje: "Ya existe una función vigente con este nombre"
9. Sistema mantiene formulario desplegado con datos ingresados
10. Usuario corrige nombre a: "Usuario común web mejorado"
11. Usuario presiona botón check verde nuevamente
12. Sistema valida nombre único y guarda función exitosamente

### Flujo 4: Error de carga de dropdowns

**Precondición:** API de opciones no está disponible

1. Usuario presiona botón "Agregar" del SearchBar
2. Sistema despliega CreateFuncionForm
3. Sistema intenta cargar dropdowns con GET /opciones, /atribuciones, /alcances
4. GET /opciones retorna error 500
5. Sistema muestra mensaje en dropdown opciones: "Error al cargar opciones. Intente nuevamente."
6. Dropdowns atribuciones y alcances cargan correctamente
7. Usuario puede cerrar formulario con X
8. Usuario presiona "Agregar" nuevamente para reintentar
9. Sistema recarga dropdowns correctamente

## Dependencias

### Módulos/HdU Previos Requeridos
- **Módulo IX - Mantenedor de Alcance:** Debe existir al menos un alcance (Nacional, Regional, Unidad, Personal)
- **Módulo X - Mantenedor de Atribuciones:** Debe existir al menos una atribución (Registro, Archivo, Ingreso, etc.)
- **Módulo XI - Mantenedor de Opciones:** Debe existir al menos una opción de aplicativo disponible

### Módulos/HdU que Dependen de Esta
- **HdU-002:** Buscar función (requiere funciones creadas para buscar)
- **HdU-003:** Modificar vigencia de función (requiere función existente)
- **HdU-004:** Eliminar función (requiere función existente)
- **HdU-005:** Agregar opción a función (requiere función base creada)

## Notas Técnicas

### Frontend
- Formulario inline (NO modal) se despliega/colapsa con animación suave
- Validaciones en tiempo real con debounce de 300ms
- Botón check solo se habilita cuando todos los campos son válidos
- Spinner en botón check durante guardado con cursor wait
- Mantener focus en input nombre al desplegar formulario

### Backend
- Endpoint: POST /api/v1/{rut}-{dv}/funciones
- Validar nombre único con query: `SELECT COUNT(*) FROM FUNCION WHERE UPPER(nombre) = UPPER(:nombre) AND vigente = 1`
- Validar foreign keys: opcionId, atribucionId, alcanceId existen y están vigentes
- Generar código función correlativo: `SELECT MAX(codigo) + 1 FROM FUNCION`
- Transacción atómica: insert FUNCION → insert FUNCION_OPCION → insert FUNCION_OPCION_ATRIB_ALCANCE
- Si falla algún insert, rollback completo
- Auditoría: registrar usuario, fecha/hora, acción, descripción en tabla AUDITORIA_FUNCIONES

### Base de Datos
- Tabla FUNCION: columnas (id, codigo, nombre, vigente, fecha_creacion, usuario_creacion)
- Tabla FUNCION_OPCION: columnas (id, funcion_id, opcion_id, orden, vigente, fecha_creacion)
- Tabla FUNCION_OPCION_ATRIB_ALCANCE: columnas (id, funcion_opcion_id, atribucion_id, alcance_id, vigente, fecha_creacion)
- Índices: idx_funcion_nombre_vigente (nombre, vigente), idx_funcion_opcion_funcion_id (funcion_id)
- Foreign keys: funcion_opcion.funcion_id → funcion.id, funcion_opcion.opcion_id → opcion.id
- Constraint unique: uk_funcion_nombre_vigente UNIQUE (UPPER(nombre), vigente) WHERE vigente = 1

## Criterios de Prueba

### Pruebas Funcionales
1. **Crear función con datos válidos:** Verificar que función se crea vigente con opción y atribución-alcance
2. **Validar nombre duplicado:** Intentar crear función con nombre existente (case insensitive)
3. **Validar campos obligatorios:** Intentar guardar sin completar algún campo
4. **Validar formato nombre:** Ingresar caracteres especiales y verificar rechazo
5. **Validar longitud nombre:** Ingresar 501 caracteres y verificar bloqueo
6. **Cancelar creación:** Verificar que formulario colapsa sin guardar
7. **Validar permisos:** Intentar crear función con perfil Consulta
8. **Validar foreign keys:** Intentar crear función con opcionId inexistente

### Pruebas de Integración
1. **Carga de dropdowns:** Verificar que opciones, atribuciones y alcances cargan correctamente
2. **Persistencia completa:** Verificar que se crean registros en 3 tablas (FUNCION, FUNCION_OPCION, FUNCION_OPCION_ATRIB_ALCANCE)
3. **Auditoría:** Verificar que se registra evento en tabla AUDITORIA_FUNCIONES
4. **Actualización de lista:** Verificar que nueva función aparece en SearchBar al buscar después de crear

### Pruebas de Performance
1. **Tiempo de guardado:** Crear función debe tomar < 2 segundos
2. **Carga de dropdowns:** Cada dropdown debe cargar en < 1 segundo
3. **Validación duplicado:** Validación debe ser instantánea (< 500ms)

## Estimación Detallada

- **Frontend:** 3 puntos (formulario inline 3 filas, validaciones, integración API)
- **Backend:** 2 puntos (endpoint POST, validaciones, transacción 3 tablas, auditoría)
- **Testing:** 1 punto (pruebas funcionales, integración, performance)
- **Total:** 5 puntos de historia
