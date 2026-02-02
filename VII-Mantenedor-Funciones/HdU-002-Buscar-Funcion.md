# HdU-002: Buscar Función por Vigencia

## Información General

- **ID:** HdU-002
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional, Perfil Consulta

## Historia de Usuario

**Como** usuario autenticado del Sistema Control de Acceso,  
**Quiero** buscar funciones por vigencia y visualizar su estructura completa,  
**Para** consultar opciones, atribuciones y alcances asignados a cada función del sistema.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "Análisis de Mockups" y componentes "SearchBar" y "FuncionSection".

## Criterios de Aceptación

### AC-001: Carga inicial de la vista
**Dado que** soy un usuario autenticado,  
**Cuando** accedo a la vista de Funciones,  
**Entonces** el sistema debe:
- Mostrar SearchBar con toggle en "Vigente" por defecto (verde)
- Cargar dropdown de funciones vigentes con GET /api/v1/{rut}-{dv}/funciones?vigente=true
- Ordenar funciones alfabéticamente en dropdown
- Dropdown debe estar vacío (sin selección inicial)
- Botón lupa verde habilitado solo cuando se selecciona una función
- Mostrar área de contenido vacía (sin FuncionSection)

### AC-002: Filtrar funciones por vigencia
**Dado que** estoy en el SearchBar,  
**Cuando** cambio el toggle de "Vigente" a "No Vigente",  
**Entonces** el sistema debe:
- Cambiar color toggle de verde a naranja
- Recargar dropdown con funciones no vigentes: GET /api/v1/{rut}-{dv}/funciones?vigente=false
- Limpiar selección actual del dropdown si existía
- Mostrar spinner mientras carga nuevas funciones
- Si no hay funciones no vigentes: dropdown vacío con mensaje "No hay funciones no vigentes"

### AC-003: Seleccionar función del dropdown
**Dado que** el dropdown tiene funciones cargadas,  
**Cuando** selecciono una función de la lista,  
**Entonces** el sistema debe:
- Marcar función seleccionada en dropdown
- Habilitar botón lupa verde
- NO ejecutar búsqueda automáticamente (requiere clic en lupa)

### AC-004: Buscar función seleccionada
**Dado que** he seleccionado una función del dropdown,  
**Cuando** presiono el botón lupa verde,  
**Entonces** el sistema debe:
- Mostrar spinner en área de contenido
- Ejecutar GET /api/v1/{rut}-{dv}/funciones/{id}
- Desplegar FuncionSection con estructura completa:
  - Header verde oscuro: nombre función, contador usuarios, toggle vigencia, papelera
  - Lista de OpcionAccordion (colapsados por defecto)
  - Cada OpcionAccordion con contador de usuarios y lista de AtribucionAlcanceItem

### AC-005: Visualizar opciones colapsables
**Dado que** una función está desplegada,  
**Cuando** observo los OpcionAccordion,  
**Entonces** el sistema debe:
- Mostrar todos los OpcionAccordion colapsados inicialmente
- Mostrar nombre opción: "[código aplicativo]: [nombre]" (ej: "OT Mantenedor usuarios relacionados")
- Mostrar contador usuarios de la opción
- Mostrar botón (+) verde para agregar atribuciones-alcances
- Mostrar icono papelera gris para eliminar opción

### AC-006: Expandir/colapsar opción
**Dado que** una función tiene opciones desplegadas,  
**Cuando** hago clic en el nombre de un OpcionAccordion,  
**Entonces** el sistema debe:
- Expandir acordeón mostrando lista de AtribucionAlcanceItem
- Animar transición suave de expansión
- Si hay otro acordeón expandido: mantenerlo expandido (no colapsar automáticamente)
- Si hago clic nuevamente: colapsar acordeón ocultando AtribucionAlcanceItem

### AC-007: Visualizar atribuciones-alcances
**Dado que** un OpcionAccordion está expandido,  
**Cuando** observo las atribuciones-alcances,  
**Entonces** el sistema debe:
- Mostrar filas verdes claras con texto "Atribución-Alcance: [código atrib]-[código alc]"
- Ejemplo: "RE-N", "AR-R", "IN-U"
- Mostrar toggle vigencia de cada atribución-alcance (verde o naranja)
- Mostrar icono papelera gris en cada fila
- Última fila con botón (+) verde adicional

### AC-008: Tooltip descripción atribución-alcance
**Dado que** observo una atribución-alcance,  
**Cuando** hago hover sobre el texto "RE-N",  
**Entonces** el sistema debe:
- Mostrar tooltip con descripción completa: "Registro - Nacional"
- Tooltip aparece después de 500ms de hover
- Tooltip desaparece al quitar mouse

### AC-009: Contador de usuarios
**Dado que** una función está desplegada,  
**Cuando** observo los contadores de usuarios,  
**Entonces** el sistema debe:
- Mostrar número total usuarios de función en header (ej: icono usuario + "100")
- Mostrar número usuarios de cada opción en OpcionAccordion (ej: "10")
- Contadores deben ser clickeables (cursor pointer al hover)
- Contadores deben estar actualizados con datos reales de la función

### AC-010: Manejo de función no encontrada
**Dado que** intento buscar una función,  
**Cuando** la función fue eliminada o no existe,  
**Entonces** el sistema debe:
- Retornar HTTP 404 del backend
- Mostrar mensaje: "Función no encontrada"
- Mantener SearchBar visible
- NO mostrar FuncionSection vacía

### AC-011: Búsqueda múltiple
**Dado que** ya busqué y visualicé una función,  
**Cuando** selecciono otra función del dropdown y presiono lupa,  
**Entonces** el sistema debe:
- Ocultar FuncionSection anterior
- Cargar nueva función seleccionada
- Actualizar área de contenido con nueva FuncionSection
- Mantener toggle vigencia en estado actual (no resetear a "Vigente")

### AC-012: Permisos de visualización
**Dado que** soy un usuario autenticado,  
**Cuando** visualizo una función,  
**Entonces** el sistema debe:
- Si perfil Administrador Nacional: mostrar todos los botones de acción (Agregar, papeleras, toggles)
- Si perfil Consulta: ocultar todos los botones de acción, mostrar solo vista lectura
- Contadores de usuarios deben ser clickeables para ambos perfiles

## Flujos Principales

### Flujo 1: Buscar función vigente

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.1 Buscar Función Existente".

**Precondición:** Existen funciones vigentes en el sistema

1. Usuario accede a vista Funciones
2. Sistema muestra SearchBar con toggle "Vigente" verde por defecto
3. Sistema carga dropdown con funciones vigentes
4. Usuario selecciona función "Mantención general" del dropdown
5. Sistema habilita botón lupa verde
6. Usuario presiona botón lupa
7. Sistema ejecuta GET /api/v1/{rut}-{dv}/funciones/123
8. Sistema despliega FuncionSection con:
   - Header: "Función: Mantención general", contador "100", toggle Vigente verde
   - OpcionAccordion 1: "OT Mantenedor usuarios relacionados", contador "10" (colapsado)
   - OpcionAccordion 2: "F2890: Mantenedor Unidades", contador "10" (colapsado)
9. Usuario hace clic en OpcionAccordion 1 para expandir
10. Sistema expande acordeón mostrando 3 AtribucionAlcanceItem:
    - "Atribución-Alcance: RE-N" con toggle Vigente verde
    - "Atribución-Alcance: AR-R" con toggle Vigente verde
    - "Atribución-Alcance: IN-U" con toggle Vigente verde
11. Usuario hace hover sobre "RE-N"
12. Sistema muestra tooltip: "Registro - Nacional"

### Flujo 2: Buscar función no vigente

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.1 Buscar Función Existente" - Variante "Buscar No Vigentes".

**Precondición:** Existen funciones no vigentes en el sistema

1. Usuario accede a vista Funciones con toggle "Vigente"
2. Usuario cambia toggle a "No Vigente"
3. Sistema cambia color toggle a naranja
4. Sistema recarga dropdown con GET /funciones?vigente=false
5. Dropdown muestra funciones no vigentes: "Función antigua", "Función desactivada"
6. Usuario selecciona "Función antigua"
7. Usuario presiona botón lupa
8. Sistema despliega función con toggle vigencia en naranja "No Vigente"
9. Opciones y atribuciones-alcances también muestran estados no vigentes (naranja)

### Flujo 3: Expandir/colapsar múltiples opciones

**Precondición:** Función con 3 opciones desplegada

1. Usuario observa función con 3 OpcionAccordion colapsados
2. Usuario hace clic en OpcionAccordion 1
3. Sistema expande OpcionAccordion 1 mostrando atribuciones-alcances
4. Usuario hace clic en OpcionAccordion 2
5. Sistema expande OpcionAccordion 2 (OpcionAccordion 1 permanece expandido)
6. Usuario hace clic nuevamente en OpcionAccordion 1
7. Sistema colapsa OpcionAccordion 1 (OpcionAccordion 2 permanece expandido)
8. Usuario ahora ve solo OpcionAccordion 2 expandido

### Flujo 4: Sin funciones disponibles

**Precondición:** No existen funciones vigentes en el sistema

1. Usuario accede a vista Funciones
2. Sistema intenta cargar funciones vigentes
3. API retorna array vacío
4. Sistema muestra dropdown vacío con mensaje "No hay funciones disponibles"
5. Botón lupa permanece deshabilitado (gris)
6. Usuario NO puede buscar funciones

## Dependencias

### Módulos/HdU Previos Requeridos
- **HdU-001:** Crear función (requiere funciones existentes para buscar)
- **Módulo IX, X, XI:** Alcances, Atribuciones, Opciones (para desplegar datos completos)

### Módulos/HdU que Dependen de Esta
- **HdU-003:** Modificar vigencia (usa búsqueda previa)
- **HdU-004:** Eliminar función (usa búsqueda previa)
- **HdU-005:** Agregar opción (usa función desplegada)
- **HdU-009:** Ver usuarios (accede desde función desplegada)

## Notas Técnicas

### Frontend
- Acordeones colapsables con animación CSS transition (300ms)
- Tooltip con posición dinámica (evitar corte por borde pantalla)
- Spinner skeleton mientras carga función
- Caché local de dropdown funciones (5 minutos) para mejorar performance

### Backend
- Endpoint: GET /api/v1/{rut}-{dv}/funciones?vigente={true|false}
- Endpoint: GET /api/v1/{rut}-{dv}/funciones/{id}
- Query debe incluir LEFT JOIN para cargar opciones, atribuciones, alcances en una sola consulta
- Ordenar opciones por campo "orden" (drag and drop)
- Incluir contador usuarios por función y por opción

### Base de Datos
- Query optimizado con índices: idx_funcion_vigente (vigente), idx_funcion_opcion_funcion_id (funcion_id)
- Subquery para contar usuarios: `SELECT COUNT(*) FROM USUARIO_FUNCION WHERE funcion_id = ?`

## Criterios de Prueba

1. **Buscar función vigente:** Verificar que despliega estructura completa
2. **Buscar función no vigente:** Verificar toggle naranja
3. **Expandir/colapsar opciones:** Verificar animación y estado
4. **Tooltip atribución-alcance:** Verificar descripción completa
5. **Dropdown vacío:** Verificar mensaje y botón lupa deshabilitado
6. **Permisos consulta:** Verificar que no muestra botones acción

## Estimación Detallada

- **Frontend:** 2 puntos (SearchBar, acordeones, tooltips)
- **Backend:** 1 punto (endpoints GET, joins)
- **Total:** 3 puntos de historia
