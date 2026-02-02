# HdU-009: Buscar Usuario Relacionado

## Información General

**ID:** HdU-009  
**Módulo:** V - Mantenedor de Usuarios Relacionados  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador del SII  
**Quiero** buscar un usuario relacionado por su RUT  
**Para** visualizar su información completa, cargos, funciones y unidades asignadas  

## Mockups de Referencia

- ![image-0027](./images/image-0027.png) - SearchBar inicial con input RUT vacío
- ![image-0025](./images/image-0025.png) - Card usuario con datos completos y cargos expandidos

## Criterios de Aceptación

**AC-001:** La pantalla inicial debe mostrar un SearchBar con:
- Input "Ingrese RUT:" con formato automático XX.XXX.XXX-X
- Botón lupa para ejecutar búsqueda
- Botón "+ Agregar usuario nuevo" (verde)
- Estado vacío sin resultados

**AC-002:** El sistema debe validar el RUT ingresado:
- Formato correcto: 8-9 dígitos + dígito verificador
- Dígito verificador válido según algoritmo módulo 11
- Mostrar error inmediato si formato incorrecto

**AC-003:** Al presionar el botón lupa, el sistema debe:
- Ejecutar búsqueda en BR_RELACIONADOS por RELA_RUT
- Mostrar indicador de carga durante la consulta

**AC-004:** Si el usuario existe, el sistema debe mostrar UserDetailCard con:
- RUT en formato XX.XXX.XXX-X
- Tipo de usuario (INTERNO/EXTERNO)
- Nombre completo (RELA_NOMBRE + RELA_PATERNO + RELA_MATERNO)
- Email (RELA_EMAIL)
- Teléfono (RELA_FONO)
- Toggle jurisdicción (SIMPLE/AMPLIADA)
- Vigencia inicio y fin
- Botones editar y eliminar
- Sección de unidades con cargos y funciones

**AC-005:** Si el usuario NO existe, el sistema debe:
- Mostrar mensaje "Usuario no encontrado" en área de resultados
- Mantener SearchBar visible con el RUT ingresado
- Habilitar botón "+ Agregar usuario nuevo"

**AC-006:** El sistema debe diferenciar usuarios INTERNO vs EXTERNO:
- INTERNO (SII): Icono distintivo, datos desde SIGER (read-only)
- EXTERNO (OCM/Notario/otros): Icono distintivo, datos editables

## Flujos Principales

### Flujo 1: Búsqueda Exitosa

1. Usuario abre pantalla /usuarios-relacionados
2. Sistema muestra SearchBar vacío:

![SearchBar inicial](./images/image-0027.png)

3. Usuario ingresa RUT "15000000" en input
4. Sistema formatea automáticamente a "15.000.000-1"
5. Usuario presiona botón lupa
6. Sistema valida módulo 11 del RUT
7. Sistema ejecuta GET /buscar?rut=15000000
8. Sistema recibe response 200 con datos del usuario
9. Sistema muestra UserDetailCard con datos completos:

![Usuario encontrado](./images/image-0025.png)

   - Información personal
   - Lista de cargos con funciones
   - Unidades asignadas
10. Usuario visualiza información completa

### Flujo 2: Usuario No Encontrado

1. Usuario sigue pasos 1-7 del Flujo 1
2. Sistema ejecuta GET /buscar?rut=99999999
3. Sistema recibe response 404 Not Found
4. Sistema muestra mensaje "Usuario no encontrado para RUT 99.999.999-X"
5. Sistema mantiene SearchBar visible
6. Sistema habilita botón "+ Agregar usuario nuevo"

### Flujo 3: RUT Inválido

1. Usuario ingresa RUT "12345678-0" (dígito verificador incorrecto)
2. Sistema valida módulo 11 → detecta error
3. Sistema muestra mensaje "Dígito verificador incorrecto" en rojo
4. Sistema NO ejecuta búsqueda al backend
5. Sistema mantiene foco en input RUT

## Notas Técnicas

**API Consumida:** GET /acaj-ms/api/v1/usuarios-relacionados/buscar?rut={rut}

**Validaciones Frontend:**
- RUT formato XX.XXX.XXX-X (8-9 dígitos)
- Módulo 11 del dígito verificador
- Input obligatorio para buscar

**Validaciones Backend:**
- RUT debe existir en BR_RELACIONADOS
- Usuario autenticado debe tener permisos según alcance (Nacional/Regional/Unidad)

**Tablas BD Consultadas:**
- BR_RELACIONADOS (SELECT)
- BR_CARGOS_USUARIO (SELECT con JOIN)
- BR_FUNCIONES_USUARIO (SELECT con JOIN)
- BR_CARGOS (JOIN para descripción)
- BR_FUNCIONES (JOIN para descripción)

**Response incluye:**
- Datos personales completos
- Lista de cargos con sus funciones (anidado)
- Unidad principal y unidades de apoyo
- Vigencias actuales

## Dependencias

**Funcionales:**
- Tabla BR_RELACIONADOS debe contener usuarios
- Tabla BR_CARGOS debe tener cargos vigentes
- Tabla BR_FUNCIONES debe tener funciones vigentes
- Sistema de autenticación activo (JWT con RUT)

## Glosario

- **Usuario Relacionado**: Persona (interno SII o externo) con acceso al sistema de avaluaciones
- **RUT**: Rol Único Tributario chileno, 8-9 dígitos + dígito verificador
- **Módulo 11**: Algoritmo para validar dígito verificador de RUT chileno
- **INTERNO**: Usuario funcionario del SII, datos desde SIGER
- **EXTERNO**: Usuario de instituciones externas (OCM, notarios, CBR, CDE, municipalidades)
- **Jurisdicción SIMPLE**: Usuario opera solo en región de su unidad
- **Jurisdicción AMPLIADA**: Usuario opera en todo el país
