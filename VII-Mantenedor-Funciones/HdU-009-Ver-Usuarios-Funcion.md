# HdU-009: Ver Usuarios de Función

## Información General

- **ID:** HdU-009
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Alta
- **Estimación:** 5 puntos de historia
- **Actor Principal:** Administrador Nacional, Perfil Consulta

## Historia de Usuario

**Como** usuario autenticado,  
**Quiero** ver la lista completa de usuarios asignados a una función u opción con sus vigencias,  
**Para** conocer quiénes tienen acceso y poder exportar la información a Excel.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Secciones "UserListModal" (image-0105) y flujo "4.9 Ver Usuarios de Función".

## Criterios de Aceptación

### AC-001: Contador clickeable
**Dado que** FuncionSection o OpcionAccordion desplegados,  
**Entonces** contador usuarios (icono usuario + número) debe ser clickeable (cursor pointer).

### AC-002: Abrir modal usuarios
**Cuando** hago clic en contador,  
**Entonces** sistema:
- Abre modal "Usuarios por Función" (o "Usuarios por Opción")
- GET /api/v1/{rut}-{dv}/funciones/{id}/usuarios
- Muestra tabla con columnas: Rut, Nombre, Vigencia Inicial, Vigencia Final
- Muestra total usuarios en header: "Función: [nombre]" + "[N]"
- Botón "Exportar a Excel" con icono X verde abajo centro

### AC-003: Formato tabla
**Dado que** modal está abierto con usuarios,  
**Entonces** tabla debe:
- RUT formato XX.XXX.XXX-X
- Vigencia Inicial formato DD-MM-YYYY
- Vigencia Final formato DD-MM-YYYY o "-" si indefinida
- Ordenar por vigencia (vigentes primero)
- Sin paginación (max 1000 usuarios esperados)

### AC-004: Exportar Excel
**Cuando** presiono "Exportar a Excel",  
**Entonces** sistema:
- Genera archivo Excel client-side con xlsx.js
- Nombre archivo: "usuarios-funcion-[nombre]-[YYYYMMDD].xlsx"
- Incluye todas las columnas de tabla
- Descarga automáticamente

### AC-005: Sin usuarios
**Cuando** función/opción NO tiene usuarios,  
**Entonces** modal muestra: "No hay usuarios asignados a esta función".

### AC-006: Cerrar modal
**Cuando** presiono X blanco derecha,  
**Entonces** modal cierra sin cambios.

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.9 Ver Usuarios de Función".

1. Usuario ve función con contador "100"
2. Usuario hace clic en contador
3. Sistema abre modal "Usuarios por Función"
4. Sistema carga GET /funciones/123/usuarios
5. Sistema muestra tabla con 100 usuarios
6. Usuario revisa lista (RUT, Nombre, Vigencias)
7. Usuario presiona "Exportar a Excel"
8. Sistema genera archivo "usuarios-funcion-usuario-comun-web-20260202.xlsx"
9. Sistema descarga archivo
10. Usuario cierra modal con X

## Dependencias

- **HdU-001:** Crear función
- **HdU-002:** Buscar función
- **Módulo V:** Asignar funciones a usuarios

## Notas Técnicas

- Librería: xlsx.js para exportar client-side
- Query SQL:
```sql
SELECT u.rut, u.nombre, uf.vigencia_inicial, uf.vigencia_final
FROM USUARIO_FUNCION uf
JOIN USUARIO u ON uf.usuario_id = u.id
WHERE uf.funcion_id = :funcionId
ORDER BY uf.vigente DESC, uf.vigencia_final DESC NULLS FIRST
```

## Estimación

- Frontend: 3 puntos (modal, tabla, exportar Excel)
- Backend: 2 puntos (endpoint, join usuarios)
- Total: 5 puntos
