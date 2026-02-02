# HdU-002: Buscar Grupo

## Información General

**ID:** HdU-002  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** buscar un grupo específico por su ID y estado de vigencia  
**Para** visualizar su estructura completa (títulos y funciones) y gestionar su información  

## Mockups de Referencia

- **image-0135.png**: SearchBar con dropdown de grupos, toggle "Vigente/No Vigente" y lupa
- **image-0127.png**: Resultado de búsqueda mostrando grupo "Sistema OT" expandido con títulos y funciones

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar en la cabecera un SearchBar con los siguientes elementos:
- Dropdown "Grupo" (obligatorio, lista todos los grupos vigentes por defecto)
- Toggle "Vigente/No Vigente" (switch on/off, por defecto "Vigente"=ON)
- Botón lupa (ejecuta búsqueda)
- Botón "Agregar Grupo" (icono +)

**AC-002:** El dropdown "Grupo" debe cargar dinámicamente la lista de grupos desde BR_GRUPOS filtrando por el estado del toggle vigente

**AC-003:** Si el toggle está en "Vigente" (ON), el dropdown debe mostrar solo grupos con GRUP_VIGENTE='S'

**AC-004:** Si el toggle está en "No Vigente" (OFF), el dropdown debe mostrar solo grupos con GRUP_VIGENTE='N'

**AC-005:** Al cambiar el estado del toggle, el sistema debe:
- Vaciar la selección actual del dropdown
- Recargar automáticamente la lista de grupos según el nuevo filtro
- Mantener el botón lupa deshabilitado hasta nueva selección

**AC-006:** El botón lupa debe estar deshabilitado (gris) mientras no se haya seleccionado un grupo del dropdown

**AC-007:** Al hacer clic en el botón lupa con un grupo seleccionado, el sistema debe ejecutar GET /buscar y mostrar:
- Nombre del grupo (título principal)
- Cantidad de usuarios (clickeable, abre modal de usuarios)
- Toggle vigente/no vigente (switch habilitado para modificar)
- Botón eliminar (icono papelera, solo si grupo sin usuarios activos)
- Lista de títulos ordenados por TITU_ORDEN (acordeones colapsables)
- Dentro de cada título: lista de funciones asociadas con botón eliminar por función

**AC-008:** Si la búsqueda retorna un grupo exitosamente (200 OK), el sistema debe renderizar el componente GroupSection con los datos recibidos

**AC-009:** Si el grupo no existe (404 Not Found), el sistema debe mostrar mensaje:
- "Grupo no encontrado. Verifique el ID seleccionado."
- Limpiar el área de resultados

**AC-010:** Si ocurre un error de servidor (500), el sistema debe mostrar:
- "Error al cargar el grupo. Intente nuevamente."
- Registrar error en logs del frontend (console.error con stack trace)

## Flujos Principales

### Flujo 1: Búsqueda Exitosa de Grupo Vigente

1. Usuario accede a pantalla principal del módulo
2. Sistema carga SearchBar con toggle "Vigente" activado (ON)
3. Sistema carga dropdown "Grupo" con grupos vigentes (GRUP_VIGENTE='S')
4. Usuario abre dropdown y ve lista: "Sistema OT (123)", "Gestión de Deudas (124)"
5. Usuario selecciona "Sistema OT (123)"
6. Sistema habilita botón lupa (cambia de gris a verde)
7. Usuario hace clic en botón lupa
8. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=123`
9. Backend retorna 200 OK con payload:
   ```json
   {
     "grupoId": 123,
     "nombre": "Sistema OT",
     "cantidadUsuarios": 100,
     "vigente": "S",
     "titulos": [
       {
         "tituloId": 45,
         "nombre": "OT Reportes",
         "orden": 1,
         "funciones": [
           { "funcionId": 15, "nombre": "csdfcasc", "descripcion": "Consulta reportes OT" },
           { "funcionId": 16, "nombre": "Función 2", "descripcion": null }
         ]
       },
       {
         "tituloId": 46,
         "nombre": "OT Opciones para jefaturas",
         "orden": 2,
         "funciones": [
           { "funcionId": 17, "nombre": "Función 1", "descripcion": null }
         ]
       }
     ]
   }
   ```
10. Sistema renderiza GroupSection mostrando:
    - Título: "Sistema OT"
    - Subtítulo: "100 usuarios" (clickeable, con icono persona)
    - Toggle vigente activado (verde, switch ON)
    - Botón papelera (si cantidadUsuarios=0, deshabilitado si >0)
11. Sistema renderiza 2 acordeones TitulosAccordion:
    - "OT Reportes" (orden 1) con 2 funciones
    - "OT Opciones para jefaturas" (orden 2) con 1 función
12. Usuario expande acordeón "OT Reportes" (click en título)
13. Sistema muestra lista de funciones:
    - "csdfcasc - Consulta reportes OT" con icono X (eliminar)
    - "Función 2" con icono X (eliminar)
14. Usuario visualiza estructura completa del grupo (image-0127)

### Flujo 2: Cambio de Filtro Vigente a No Vigente

1. Usuario sigue pasos 1-3 del Flujo 1
2. Usuario hace clic en toggle "Vigente" (cambia de ON a OFF)
3. Sistema detecta cambio de estado
4. Sistema vacía selección actual del dropdown "Grupo"
5. Sistema ejecuta nueva consulta con filtro GRUP_VIGENTE='N'
6. Sistema recarga dropdown con grupos no vigentes: "Grupo Antiguo (200)", "Sistema Legacy (201)"
7. Sistema deshabilita botón lupa (gris)
8. Usuario selecciona "Grupo Antiguo (200)"
9. Sistema habilita botón lupa
10. Usuario hace clic en lupa
11. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=N&grupoId=200`
12. Sistema renderiza grupo no vigente con toggle desactivado (gris, switch OFF)

### Flujo 3: Grupo No Encontrado (404)

1. Usuario sigue pasos 1-7 del Flujo 1
2. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=999`
3. Backend retorna 404 Not Found:
   ```json
   { "error": "No encontrado", "mensaje": "Grupo ID 999 no existe" }
   ```
4. Sistema muestra mensaje de error en área de resultados:
   - Icono advertencia (triángulo amarillo)
   - Texto: "Grupo no encontrado. Verifique el ID seleccionado."
5. Sistema limpia cualquier resultado previo
6. Sistema mantiene SearchBar con selección actual visible

## Notas Técnicas

**API Consumida:**  
- GET /acaj-ms/api/v1/{rut}-{dv}/grupos/buscar?vigente={S|N}&grupoId={id}

**Validaciones:**
- Parámetro vigente: debe ser 'S' o 'N'
- GrupoId: debe existir y coincidir con el filtro de vigencia
- Usuario: autenticación requerida (RUT en JWT)

**Tablas BD (operación SELECT con JOIN):**
- BR_GRUPOS: datos del grupo
- BR_TITULOS: títulos del grupo ordenados por TITU_ORDEN
- BR_TITULOS_FUNCIONES: relación título-función
- BR_FUNCIONES: datos de las funciones
- BR_USUARIO_GRUPO: conteo de usuarios activos

**Filtros aplicados:**
- Dropdown de grupos se recarga según toggle vigente (S/N)
- Vista muestra estructura completa: grupo → títulos → funciones

## Dependencias

- BR_GRUPOS (tabla principal)
- BR_TITULOS (títulos del grupo)
- BR_TITULOS_FUNCIONES (relación con funciones)
- BR_FUNCIONES (datos de funciones)
- BR_USUARIO_GRUPO (conteo de usuarios)

## Glosario

- **Toggle Vigente**: Switch on/off que filtra grupos por estado de vigencia
- **Acordeón**: Componente UI colapsable (expand/collapse) que muestra títulos y sus funciones
- **Dropdown dinámico**: Select que recarga opciones según filtros aplicados
- **Grupo vigente**: Grupo activo (GRUP_VIGENTE='S') que puede asignarse a usuarios nuevos
- **Grupo no vigente**: Grupo inactivo (GRUP_VIGENTE='N') visible solo para consulta e historial
