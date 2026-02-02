# HdU-009: Ver Usuarios Asignados al Grupo

## Información General

**ID:** HdU-009  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** visualizar la lista completa de usuarios asignados a un grupo específico con sus períodos de vigencia  
**Para** conocer qué usuarios tienen acceso a las funcionalidades del grupo y poder verificar sus vigencias activas o históricas  

## Mockups de Referencia

Ver [VIII-Mantenedor-Grupos/frontend.md](./frontend.md) - Sección "Análisis de Mockups" y componente "UserListModal"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un contador de usuarios clickeable en el header del GroupSection junto al nombre del grupo (ej: icono usuario + "100")

**AC-002:** Al hacer clic en el contador de usuarios, el sistema debe abrir un modal titulado "Usuarios por Grupo"

**AC-003:** El modal debe mostrar en la parte superior:
- Fila verde claro con icono del grupo a la izquierda
- Nombre del grupo (ej: "Grupo: Sistema OT")
- Número total de usuarios asignados a la derecha

**AC-004:** El modal debe mostrar una tabla con las siguientes columnas:
- **Rut**: RUT del usuario con formato XX.XXX.XXX-X
- **Nombre**: Nombre completo del usuario
- **Vigencia Inicial**: Fecha de inicio de vigencia en formato DD-MM-YYYY
- **Vigencia Final**: Fecha de término de vigencia en formato DD-MM-YYYY o "-" si está vigente sin fecha fin

**AC-005:** La tabla debe mostrar TODOS los usuarios asignados al grupo (no solo los vigentes), incluyendo:
- Usuarios con vigencia activa (fecha actual entre vigencia inicial y final)
- Usuarios con vigencia futura (vigencia inicial > fecha actual)
- Usuarios con vigencia expirada (vigencia final < fecha actual)
- Usuarios sin fecha de término (vigencia final = NULL)

**AC-006:** El sistema debe ordenar los usuarios por:
- Primero: usuarios vigentes (sin fecha fin o fecha fin >= hoy)
- Segundo: usuarios con vigencia expirada
- Dentro de cada grupo: orden alfabético por nombre

**AC-007:** El modal debe incluir un botón "Exportar a Excel" con icono de Excel en la parte inferior derecha

**AC-008:** Al hacer clic en "Exportar a Excel", el sistema debe generar un archivo .xlsx con:
- Nombre de archivo: `Usuarios_Grupo_[nombreGrupo]_[DDMMYYYY].xlsx`
- Sheet única con las 4 columnas de la tabla
- Todos los registros visibles en el modal
- Formato de celdas apropiado (texto para RUT, fecha para vigencias)

**AC-009:** El archivo Excel debe generarse en el navegador (client-side) sin enviar datos al backend

**AC-010:** El modal debe tener un botón X en la esquina superior derecha para cerrarlo

**AC-011:** Si el grupo no tiene usuarios asignados (contador = 0), el modal debe mostrar mensaje: "No hay usuarios asignados a este grupo"

**AC-012:** Si ocurre un error al cargar los usuarios (500), el sistema debe mostrar: "Error al cargar usuarios del grupo. Intente nuevamente."

## Flujos Principales

### Flujo 1: Visualización Exitosa de Usuarios

1. Usuario busca grupo "Sistema OT" (grupoId=123) desde SearchBar
2. Sistema muestra GroupSection con contador "100" usuarios (icono usuario + número clickeable)
3. Usuario hace clic en el contador "100"
4. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/123/usuarios`
5. Backend retorna 200 OK con payload:
   ```json
   {
     "grupoId": 123,
     "nombreGrupo": "Sistema OT",
     "totalUsuarios": 100,
     "usuarios": [
       {
         "rut": "15000000",
         "dv": "1",
         "nombreCompleto": "Adela Maria Lozano Arriagada",
         "vigenciaInicial": "2025-08-05",
         "vigenciaFinal": "2026-08-05"
       },
       {
         "rut": "16000000",
         "dv": "2",
         "nombreCompleto": "Juan Pérez González",
         "vigenciaInicial": "2024-01-01",
         "vigenciaFinal": null
       },
       {
         "rut": "17000000",
         "dv": "3",
         "nombreCompleto": "María González López",
         "vigenciaInicial": "2023-06-15",
         "vigenciaFinal": "2024-06-15"
       }
     ]
   }
   ```
6. Sistema abre modal "Usuarios por Grupo"
7. Sistema renderiza fila superior: "Grupo: Sistema OT | 100"
8. Sistema renderiza tabla con 3 usuarios (ordenados: vigentes primero, luego expirados, alfabético)
9. Usuario visualiza datos de usuarios en la tabla

### Flujo 2: Exportación a Excel

1. Usuario sigue pasos 1-9 del Flujo 1
2. Usuario hace clic en botón "Exportar a Excel"
3. Sistema genera archivo Excel client-side con biblioteca xlsx.js:
   - Sheet: "Usuarios"
   - Headers: Rut | Nombre | Vigencia Inicial | Vigencia Final
   - 100 filas con datos de usuarios
4. Sistema formatea columnas:
   - Rut: formato texto (15.000.000-1)
   - Nombre: texto
   - Vigencias: formato fecha (05-08-2025) o "-" si NULL
5. Sistema descarga archivo: `Usuarios_Grupo_Sistema_OT_02022026.xlsx`
6. Usuario abre archivo Excel y verifica datos

### Flujo 3: Grupo Sin Usuarios

1. Usuario busca grupo "Grupo Test" (grupoId=456) sin usuarios asignados
2. Sistema muestra GroupSection con contador "0" usuarios
3. Usuario hace clic en el contador "0"
4. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/456/usuarios`
5. Backend retorna 200 OK con payload:
   ```json
   {
     "grupoId": 456,
     "nombreGrupo": "Grupo Test",
     "totalUsuarios": 0,
     "usuarios": []
   }
   ```
6. Sistema abre modal "Usuarios por Grupo"
7. Sistema muestra fila superior: "Grupo: Grupo Test | 0"
8. Sistema muestra mensaje centrado: "No hay usuarios asignados a este grupo"
9. Botón "Exportar a Excel" está deshabilitado (gris)

### Flujo 4: Error al Cargar Usuarios

1. Usuario hace clic en contador de usuarios
2. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/123/usuarios`
3. Backend retorna 500 Internal Server Error
4. Sistema muestra mensaje de error: "Error al cargar usuarios del grupo. Intente nuevamente."
5. Modal no se abre o se cierra automáticamente
6. Usuario puede reintentar desde el contador nuevamente

## Validaciones de Negocio

**VN-001:** Solo consulta datos, no modifica BR_USUARIO_GRUPO

**VN-002:** Mostrar usuarios con CUALQUIER estado de vigencia (activos, futuros, expirados)

**VN-003:** Formato RUT con puntos y guión (15.000.000-1) para visualización

**VN-004:** Fechas en formato DD-MM-YYYY (no ISO 8601)

**VN-005:** Exportación Excel client-side (no enviar datos sensibles al backend para generar archivo)

## Tablas de Datos Involucradas

**Lectura (SELECT):**
- BR_USUARIO_GRUPO: relación usuario-grupo con vigencias
- BR_USUARIOS: datos del usuario (RUT, nombre)

**Query Estimado:**
```sql
SELECT 
  u.USU_RUT || '-' || u.USU_DV AS rut_completo,
  u.USU_PRIMER_NOMBRE || ' ' || u.USU_PRIMER_APELLIDO AS nombre_completo,
  ug.USUGRU_VIGENCIA_INICIAL,
  ug.USUGRU_VIGENCIA_FINAL,
  CASE 
    WHEN ug.USUGRU_VIGENCIA_FINAL IS NULL THEN 1
    WHEN ug.USUGRU_VIGENCIA_FINAL >= SYSDATE THEN 1
    ELSE 2
  END AS orden_vigencia
FROM BR_USUARIO_GRUPO ug
INNER JOIN BR_USUARIOS u ON ug.USU_ID = u.USU_ID
WHERE ug.GRUP_ID = :grupoId
ORDER BY orden_vigencia, nombre_completo;
```

## Dependencias

**Depende de:**
- HdU-002 (Buscar Grupo): debe existir grupo cargado para ver usuarios
- Módulo V (Mantenedor Usuarios Relacionados): usuarios deben estar previamente creados y asignados

**Habilita:**
- Verificación de accesos por grupo
- Auditoría de asignaciones de usuarios
- Generación de reportes de usuarios por grupo

## Notas Técnicas

**Frontend:**
- Componente: UserListModal (modal reutilizable)
- Biblioteca Excel: xlsx.js o ExcelJS (client-side)
- Estado: cargar usuarios en state local del modal (no Vuex)

**Backend:**
- Endpoint: GET `/grupos/{grupoId}/usuarios`
- No requiere paginación (asumiendo max 1000 usuarios por grupo)
- Si performance es problema futuro, considerar paginación con `?page=1&size=100`

**Consideraciones:**
- Modal debe ser responsivo (scroll vertical si muchos usuarios)
- Exportación Excel puede ser lenta con +500 usuarios (mostrar loading)
- No incluir filtros de búsqueda en versión inicial (feature futura)
