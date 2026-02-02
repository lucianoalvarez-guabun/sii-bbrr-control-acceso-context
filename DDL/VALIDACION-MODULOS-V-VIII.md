# Validación Módulos V y VIII - Modelo Oracle Real

**Fecha:** 2 febrero 2026  
**Basado en:** Aprendizajes módulo VII + código funcionando `backend/acaj-ms`

---

## Módulo V: Mantenedor de Usuarios Relacionados

### ✅ ESTADO: Ya usa nomenclatura Oracle real

**Tablas validadas en backend-apis.md:**
- BR_RELACIONADOS (RELA_RUT, RELA_DV, RELA_NOMBRE, etc.)
- BR_CARGOS_RELACIONADO (CGRE_*)
- BR_FUNCIONES_CARGO_RELACIONADO (FCGR_*)

**Queries correctas:**
```sql
SELECT r.RELA_RUT, r.RELA_DV, r.RELA_NOMBRE, r.RELA_PATERNO
FROM AVAL.BR_RELACIONADOS r
WHERE r.RELA_RUT = :rut;
```

### ⚠️ PENDIENTE VALIDAR:
1. Campos que podrían no existir en BR_RELACIONADOS:
   - `RELA_FONO` (telefono)
   - `RELA_TIPO_USUARIO` (INTERNO/EXTERNO)
   - `RELA_JURISDICCION` (SIMPLE/AMPLIADA)
   - `RELA_VIGENCIA_INICIO`, `RELA_VIGENCIA_FIN`
   - `RELA_UNIDAD_PRINCIPAL`

2. Tabla BR_CARGOS_USUARIO (especificado) vs BR_CARGOS_RELACIONADO (real)

**ACCIÓN REQUERIDA:** Conectar Oracle y ejecutar `DESC BR_RELACIONADOS`

---

## Módulo VIII: Mantenedor de Grupos

### ❌ ESTADO: Usa nomenclatura especificada, NO validada con Oracle

**Tablas en backend-apis.md (SIN VALIDAR):**
- BR_GRUPOS (GRUP_ID, GRUP_CODIGO, GRUP_NOMBRE, GRUP_VIGENTE)
- BR_TITULOS (TITU_ID, TITU_GRUP_ID, TITU_NOMBRE, TITU_ORDEN)
- BR_TITULO_FUNCION (TIFU_TITU_ID, TIFU_FUNC_ID)

**Queries sin validar:**
```sql
INSERT INTO AVAL.BR_GRUPOS (GRUP_ID, GRUP_CODIGO, GRUP_NOMBRE, GRUP_VIGENTE)
VALUES (SEQ_GRUPO_ID.NEXTVAL, SEQ_GRUPO_ID.NEXTVAL, :nombre, 'S');
```

### 🔍 BUSQUEDA EN ORACLE:
No se encontraron tablas `BR_GRUPOS`, `BR_TITULOS` en schema AVAL.

**Tablas posibles candidatas:**
- BR_PERFILES
- BR_FUNCIONARIOS_PERFIL

**HIPÓTESIS:** Concepto "Grupo" en especificación podría ser "Perfil" en Oracle real.

**ACCIÓN REQUERIDA:** 
1. `DESC BR_PERFILES` 
2. `DESC BR_FUNCIONARIOS_PERFIL`
3. Buscar relación Perfiles → Funciones en modelo real

---

## Patrones Aprendidos Módulo VII

### 1. Validación Oracle SIEMPRE antes de especificar
```bash
sql -S intbrprod/Avalexpl@queilen.sii.cl:1540/koala
SELECT table_name FROM all_tables WHERE owner = 'AVAL' AND table_name LIKE '%GRUP%';
DESC BR_GRUPOS;
```

### 2. Nomenclatura real ≠ especificada
| Especificado | Real Oracle |
|--------------|-------------|
| FUNC_* | FUNS_* |
| BR_FUNCION_OPCION | BR_OPCIONES_FUNCION |
| FOAA_* | AOFU_* |
| BR_USUARIO_FUNCION | BR_FUNCIONES_CARGO_RELACIONADO |

### 3. Alcances embebidos (NO tabla separada)
- NO existe BR_ALCANCES
- Alcance en 2º char de ATRI_CODIGO: F/U/G/N
- Operación en 1º char: B/J/U/E/etc.

### 4. LEFT JOIN con extensiones
```sql
LEFT JOIN BR_OPCIONES_EXTENSION ext 
    ON of.FUNS_CODIGO = ext.FUNS_CODIGO 
```

### 5. Vigencia con fechas (no flags)
```sql
WHERE cgre.cgre_fecha_termino > SYSDATE
```

---

## Próximos Pasos

### Módulo V:
1. Validar campos de BR_RELACIONADOS
2. Si faltan campos, crear `BR_RELACIONADOS_EXT`
3. Actualizar queries con LEFT JOIN

### Módulo VIII:
1. ✅ Verificar si existe BR_GRUPOS (NO EXISTE)
2. 🔍 DESC BR_PERFILES, BR_FUNCIONARIOS_PERFIL
3. Mapear concepto "Grupo" → modelo real
4. Actualizar backend-apis.md con nomenclatura real
5. Actualizar HdUs con campos correctos
6. Crear extensiones si necesario

---

## Comandos Útiles

```bash
# Buscar tablas por patrón
sql -S intbrprod/Avalexpl@queilen.sii.cl:1540/koala << 'EOF'
SELECT table_name FROM all_tables 
WHERE owner = 'AVAL' 
AND table_name LIKE '%PERFIL%'
ORDER BY table_name;
EXIT;
EOF

# Describir estructura
sql -S intbrprod/Avalexpl@queilen.sii.cl:1540/koala << 'EOF'
DESC AVAL.BR_PERFILES;
EXIT;
EOF

# Contar registros
sql -S intbrprod/Avalexpl@queilen.sii.cl:1540/koala << 'EOF'
SELECT COUNT(*) FROM AVAL.BR_PERFILES;
EXIT;
EOF
```
