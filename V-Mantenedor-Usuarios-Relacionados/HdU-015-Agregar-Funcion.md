# HdU-015: Agregar Función a Cargo Existente

## Información General

**ID:** HdU-015  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Media  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** agregar funciones adicionales a un cargo ya asignado  
**Para** ampliar los permisos del usuario sin crear nuevo cargo  

## Mockups de Referencia

- ![image-0025](./images/image-0025.png) - Cargo con botón icono (+) para agregar función

## Criterios de Aceptación

**AC-001:** Cada cargo en la lista debe mostrar:
- Botón icono (+) para agregar función
- Visible solo si cargo está vigente

**AC-002:** Al hacer clic en icono (+), el sistema debe:
- Abrir modal "Agregar Función del cargo"
- Mostrar "Cargo: [nombre del cargo]" como read-only
- Mostrar dropdown "Seleccione la Función" (funciones vigentes disponibles)
- Mostrar botón icono (+) para agregar más funciones
- Botones "Agregar" y "Cancelar"

**AC-003:** El dropdown funciones debe:
- Cargar solo funciones vigentes (FUNS_VIGENTE=1)
- Excluir funciones ya asignadas al cargo
- Permitir seleccionar múltiples funciones nuevas

**AC-004:** El sistema debe validar:
- Al menos 1 función nueva seleccionada
- No repetir funciones ya existentes en el cargo
- Funciones deben ser vigentes

**AC-005:** Al presionar "Agregar", el sistema debe:
- Insertar en BR_FUNCIONES_USUARIO para cada función seleccionada
- Vincular funciones al cargoId existente
- Registrar auditoría
- Cerrar modal
- Refrescar lista de funciones del cargo en UserDetailCard
- Mostrar alerta éxito "X funciones agregadas correctamente"

**AC-006:** Si se intenta agregar función ya existente, el sistema debe:
- Mostrar error "La función [nombre] ya está asignada a este cargo"
- NO cerrar modal
- Permitir seleccionar otras funciones

## Flujos Principales

### Flujo 1: Agregar 2 Funciones

1. Usuario ve cargo "Jefe de Departamento" con 3 funciones actuales:

![Cargo con funciones](./images/image-0025.png)

2. Usuario hace clic en icono (+) del cargo
3. Sistema abre modal "Agregar Función del cargo"
4. Sistema muestra "Cargo: Jefe de Departamento" (read-only)
5. Sistema carga funciones disponibles (excluye las 3 ya asignadas)
6. Usuario selecciona "Generar informes" en primer dropdown
7. Usuario hace clic en icono (+)
8. Sistema agrega segundo dropdown
9. Usuario selecciona "Exportar a Excel"
10. Usuario hace clic en "Agregar"
11. Sistema valida 2 funciones nuevas
12. Sistema inserta 2 registros en BR_FUNCIONES_USUARIO
13. Sistema cierra modal
14. Sistema refresca cargo en UserDetailCard
15. Usuario ve cargo ahora con 5 funciones (3 originales + 2 nuevas)
16. Sistema muestra alerta "2 funciones agregadas correctamente"

### Flujo 2: Función Duplicada

1. Usuario abre modal agregar función
2. Usuario selecciona función "Aprobar solicitudes" (ya existe en cargo)
3. Usuario intenta guardar
4. Sistema detecta duplicado
5. Sistema muestra error "La función Aprobar solicitudes ya está asignada a este cargo"
6. Sistema mantiene modal abierto
7. Usuario selecciona otra función
8. Usuario guarda exitosamente

### Flujo 3: Cargo No Vigente

1. Usuario ve cargo "Supervisor Regional" (vigencia fin pasada)
2. Botón icono (+) está deshabilitado (gris)
3. Usuario pasa mouse → tooltip "No se pueden agregar funciones a cargo no vigente"

## Notas Técnicas

**APIs Consumidas:**
- GET /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos/{cargoId}/funciones/disponibles
- POST /acaj-ms/api/v1/usuarios-relacionados/{rut}-{dv}/cargos/{cargoId}/funciones

**Validaciones Backend:**
- Cargo debe existir y estar vigente
- Funciones deben ser vigentes (FUNS_VIGENTE=1)
- No duplicar funciones en mismo cargo
- Al menos 1 función nueva

**Tablas BD Afectadas:**
- BR_FUNCIONES_USUARIO (INSERT múltiple)
- BR_AUDITORIA_CAMBIOS (INSERT)

**Secuencia:**
- SEQ_FUNCION_USUARIO_ID para cada FUUS_ID

## Dependencias

**Funcionales:**
- Cargo debe existir y estar vigente
- BR_FUNCIONES debe tener funciones vigentes disponibles
- Usuario debe tener permisos según alcance

## Glosario

- **Función Disponible**: Función vigente no asignada aún al cargo
- **Función Existente**: Función ya asignada al cargo
- **Cargo Vigente**: Cargo con vigencia fin NULL o futura
