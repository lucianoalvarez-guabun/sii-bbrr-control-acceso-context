# HdU-011: Exportar Usuarios a Excel

## Información General

- **ID:** HdU-011
- **Módulo:** VII - Mantenedor de Funciones
- **Prioridad:** Media
- **Estimación:** 3 puntos de historia
- **Actor Principal:** Administrador Nacional, Perfil Consulta

## Historia de Usuario

**Como** usuario autenticado,  
**Quiero** exportar la lista de usuarios de una función u opción a Excel,  
**Para** realizar análisis offline o compartir información con otros departamentos.

## Mockups de Referencia

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "UserListModal" (image-0105) - Botón "Exportar a Excel".

## Criterios de Aceptación

### AC-001: Botón exportar visible
**Dado que** UserListModal abierto con usuarios,  
**Entonces** debo ver botón verde "Exportar a Excel" con icono X verde abajo centro.

### AC-002: Generar archivo Excel
**Cuando** presiono botón "Exportar a Excel",  
**Entonces** sistema:
- Genera archivo Excel client-side con xlsx.js
- NO requiere llamada a backend adicional (usa datos ya cargados en modal)
- Incluye columnas: Rut, Nombre, Vigencia Inicial, Vigencia Final
- Incluye todas las filas (sin límite)
- Formato columnas:
  - Rut: texto con formato XX.XXX.XXX-X
  - Vigencias: fecha formato DD-MM-YYYY
  - Header bold con fondo verde claro

### AC-003: Nombre archivo
**Dado que** exporto usuarios de función "Usuario común web",  
**Entonces** archivo debe llamarse:
- Formato: "usuarios-funcion-[nombre-normalizado]-[YYYYMMDD].xlsx"
- Ejemplo: "usuarios-funcion-usuario-comun-web-20260202.xlsx"
- Normalizar: minúsculas, espacios → guiones, sin caracteres especiales

### AC-004: Descarga automática
**Cuando** archivo está generado,  
**Entonces** navegador inicia descarga automática sin cerrar modal.

### AC-005: Sin usuarios
**Cuando** NO hay usuarios y presiono "Exportar a Excel",  
**Entonces** sistema:
- Genera archivo con solo headers (sin filas datos)
- Descarga archivo vacío

### AC-006: Exportar usuarios de opción
**Dado que** modal muestra "Usuarios por Opción",  
**Entonces** nombre archivo debe ser:
- "usuarios-opcion-[codigo-nombre]-[fecha].xlsx"
- Ejemplo: "usuarios-opcion-ot-mantenedor-usuarios-20260202.xlsx"

## Flujos Principales

Ver [VII-Mantenedor-Funciones/frontend.md](./frontend.md) - Sección "4.9 Ver Usuarios de Función" - pasos 7-9.

1. Usuario abre modal usuarios función con 100 registros
2. Usuario revisa lista en pantalla
3. Usuario presiona botón "Exportar a Excel" verde
4. Sistema genera archivo xlsx client-side con xlsx.js:
   - Sheet "Usuarios"
   - Headers: Rut | Nombre | Vigencia Inicial | Vigencia Final
   - 100 filas datos con formato aplicado
5. Sistema descarga archivo "usuarios-funcion-usuario-comun-web-20260202.xlsx"
6. Usuario abre archivo en Excel para análisis
7. Modal permanece abierto para continuar revisando

## Dependencias

- **HdU-009:** Ver usuarios (modal debe estar abierto)
- **HdU-002:** Buscar función

## Notas Técnicas

### Frontend
- Librería: xlsx.js (SheetJS)
- Instalación: `npm install xlsx`
- Ejemplo código:
```javascript
import * as XLSX from 'xlsx';

function exportarExcel(usuarios, nombreFuncion) {
  const data = usuarios.map(u => ({
    'Rut': formatRut(u.rut),
    'Nombre': u.nombre,
    'Vigencia Inicial': formatDate(u.vigenciaInicial),
    'Vigencia Final': u.vigenciaFinal ? formatDate(u.vigenciaFinal) : '-'
  }));
  
  const ws = XLSX.utils.json_to_sheet(data);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Usuarios');
  
  const filename = `usuarios-funcion-${normalizar(nombreFuncion)}-${fechaHoy()}.xlsx`;
  XLSX.writeFile(wb, filename);
}
```

### Backend
- NO requiere endpoint adicional
- Datos ya están cargados en frontend via GET /funciones/{id}/usuarios
- Exportación 100% client-side para mejor performance

### Formato Excel
- Columna Rut: ancho 15
- Columna Nombre: ancho 40
- Columnas Vigencias: ancho 15
- Header: bold, background #d4edda (verde claro)
- Filas: alternadas blanco/gris claro (#f8f9fa)

## Criterios de Prueba

1. **Exportar función con 100 usuarios:** Verificar archivo descarga con 100 filas
2. **Exportar función sin usuarios:** Verificar archivo solo headers
3. **Nombre archivo normalizado:** Verificar formato correcto con caracteres especiales
4. **Formato fechas:** Verificar DD-MM-YYYY en Excel
5. **Formato RUT:** Verificar XX.XXX.XXX-X con puntos y guión
6. **Abrir en Excel:** Verificar que archivo es válido y abre correctamente

## Estimación Detallada

- **Frontend:** 3 puntos (integración xlsx.js, formateo, generación archivo)
- **Testing:** Incluido en frontend
- **Total:** 3 puntos de historia

## Notas Adicionales

- Exportación client-side evita carga servidor
- Soporta hasta 10,000 usuarios sin problemas performance
- Si función tiene >10,000 usuarios: considerar paginación o exportación backend
- Librería xlsx.js es lightweight (500KB) y bien mantenida
- Compatible con Excel 2007+ (.xlsx) y LibreOffice Calc
