# HdU-006: Eliminar Título de Grupo

## Información General

**ID:** HdU-006  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Media  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** eliminar un título completo (con todas sus funciones) de un grupo  
**Para** reorganizar la estructura de permisos cuando un título ya no es necesario  

## Mockups de Referencia

- **image-0127.png**: TitulosAccordion con botón eliminar (icono X o papelera)
- **image-0034.png**: ConfirmDialog "¿Está seguro que desea eliminar...?"
- **image-0027.png**: Alerta de éxito tras eliminación

## Criterios de Aceptación

**AC-001:** Cada título en la lista debe mostrar un botón eliminar (icono X o papelera) en el header del acordeón

**AC-002:** Al hacer clic en botón eliminar, el sistema debe mostrar modal de confirmación (ConfirmDialog) con:
- Icono advertencia (triángulo amarillo)
- Mensaje: "¿Está seguro que desea eliminar el título [NOMBRE_TITULO]? Se eliminarán todas las funciones asociadas. Esta acción no se puede deshacer."
- Botón "Cancelar" (gris)
- Botón "Eliminar" (rojo)

**AC-003:** Si usuario hace clic en "Cancelar", el sistema debe cerrar modal sin ejecutar eliminación

**AC-004:** Si usuario hace clic en "Eliminar", el sistema debe ejecutar DELETE `/{grupoId}/titulos/{tituloId}` y eliminar:
- Registro en BR_TITULOS (tituloId)
- Todos los registros en BR_TITULOS_FUNCIONES (por FK CASCADE)

**AC-005:** Si la eliminación es exitosa (200 OK), el sistema debe:
- Cerrar modal de confirmación
- Mostrar alerta verde "Título eliminado exitosamente" por 3 segundos
- Remover el acordeón del título de la lista visual
- Reordenar títulos restantes manteniendo su TITU_ORDEN original

**AC-006:** El sistema NO debe reordenar automáticamente los TITU_ORDEN en BD (mantiene orden original con gaps)

**AC-007:** Si el título no existe o ya fue eliminado (404 Not Found), el sistema debe mostrar:
- "Título no encontrado. Es posible que ya haya sido eliminado."
- Actualizar vista del grupo

**AC-008:** Si ocurre un error de servidor (500), el sistema debe mostrar:
- "Error al eliminar título. Intente nuevamente."
- Mantener título visible en lista

**AC-009:** El sistema debe registrar auditoría con operación='DELETE' incluyendo cantidad de funciones eliminadas

**AC-010:** Si el grupo solo tiene 1 título, el sistema debe permitir su eliminación (NO hay restricción de "último título")

## Flujos Principales

### Flujo 1: Eliminación Exitosa de Título

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Sistema muestra grupo con 2 títulos:
   - "OT Reportes" (tituloId=45, orden=1) con 2 funciones
   - "OT Opciones para jefaturas" (tituloId=46, orden=2) con 3 funciones
3. Usuario hace clic en botón eliminar (X) del título "OT Opciones para jefaturas"
4. Sistema abre modal ConfirmDialog (image-0034):
   - Icono advertencia
   - Texto: "¿Está seguro que desea eliminar el título 'OT Opciones para jefaturas'? Se eliminarán todas las funciones asociadas (3). Esta acción no se puede deshacer."
   - Botones: Cancelar, Eliminar
5. Usuario hace clic en botón "Eliminar"
6. Sistema cierra modal
7. Sistema ejecuta DELETE `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/46`
8. Backend verifica que título pertenece al grupo:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS 
   WHERE TITU_ID = 46 AND TITU_GRUP_ID = 123;
   -- Result: 1 (existe y pertenece)
   ```
9. Backend cuenta funciones asociadas (para auditoría):
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS_FUNCIONES 
   WHERE TIFU_TITU_ID = 46;
   -- Result: 3
   ```
10. Backend guarda datos para auditoría:
    ```java
    Map<String, Object> valoresAnteriores = Map.of(
        "nombre", "OT Opciones para jefaturas",
        "orden", 2,
        "funciones_eliminadas", 3
    );
    ```
11. Backend ejecuta DELETE con CASCADE:
    ```sql
    DELETE FROM BR_TITULOS WHERE TITU_ID = 46;
    -- ON DELETE CASCADE elimina automáticamente:
    --   BR_TITULOS_FUNCIONES (3 registros)
    ```
12. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_ANTERIORES, AUDI_JUSTIFICACION
    ) VALUES (
      'DELETE', 'BR_TITULOS', 46,
      JSON_OBJECT(
        'nombre' VALUE 'OT Opciones para jefaturas',
        'grupoId' VALUE 123,
        'funciones_eliminadas' VALUE 3
      ),
      'Se eliminó el título OT Opciones para jefaturas del grupo Sistema OT (3 funciones)'
    );
    ```
13. Backend retorna 200 OK:
    ```json
    {
      "mensaje": "Título eliminado exitosamente",
      "eliminados": {
        "titulo": 1,
        "funciones": 3
      }
    }
    ```
14. Sistema muestra alerta verde "Título eliminado exitosamente" (image-0027)
15. Sistema remueve acordeón "OT Opciones para jefaturas" de la lista visual
16. Sistema ahora muestra solo 1 título: "OT Reportes" (orden=1)
17. NO se reordenan los TITU_ORDEN en BD (mantiene gaps: orden 1 existe, orden 2 vacío)

### Flujo 2: Cancelación de Eliminación

1. Usuario sigue pasos 1-4 del Flujo 1
2. Usuario hace clic en botón "Cancelar"
3. Sistema cierra modal ConfirmDialog inmediatamente
4. Sistema NO ejecuta DELETE
5. Título permanece visible sin cambios
6. Usuario puede continuar operando con el título

### Flujo 3: Título No Existe (404)

1. Usuario sigue pasos 1-7 del Flujo 1
2. Backend ejecuta verificación:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS 
   WHERE TITU_ID = 999 AND TITU_GRUP_ID = 123;
   -- Result: 0 (no existe)
   ```
3. Backend lanza NotFoundException
4. Backend retorna 404 Not Found:
   ```json
   {
     "error": "No encontrado",
     "mensaje": "Título ID 999 no existe o no pertenece al grupo 123"
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos:
   - "Título no encontrado. Es posible que ya haya sido eliminado."
6. Sistema actualiza vista del grupo (re-ejecuta búsqueda)
7. Título desaparece de lista (si fue eliminado por otro usuario concurrente)

## Notas Técnicas

### Frontend (React)

**Componente:** TitulosAccordion

**Manejo de eliminación:**
```jsx
const TitulosAccordion = ({ grupo }) => {
  const dispatch = useDispatch();
  const [tituloAEliminar, setTituloAEliminar] = useState(null);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  
  const handleDeleteClick = (titulo) => {
    setTituloAEliminar(titulo);
    setShowConfirm(true);
  };
  
  const handleConfirmDelete = async () => {
    setIsDeleting(true);
    
    try {
      await dispatch(deleteTitulo({ 
        grupoId: grupo.grupoId, 
        tituloId: tituloAEliminar.tituloId 
      })).unwrap();
      
      message.success('Título eliminado exitosamente', 3);
      setShowConfirm(false);
      setTituloAEliminar(null);
    } catch (error) {
      message.error(error || 'Error al eliminar título. Intente nuevamente.', 5);
      setShowConfirm(false);
    } finally {
      setIsDeleting(false);
    }
  };
  
  return (
    <div className="titulos-accordion">
      {grupo.titulos.map(titulo => (
        <Collapse key={titulo.tituloId}>
          <Panel
            header={
              <div className="titulo-header">
                <span>{titulo.nombre} ({titulo.funciones.length})</span>
                <Button
                  icon={<DeleteOutlined />}
                  danger
                  size="small"
                  onClick={(e) => {
                    e.stopPropagation(); // Evitar expandir acordeón
                    handleDeleteClick(titulo);
                  }}
                />
              </div>
            }
          >
            {/* Lista de funciones */}
          </Panel>
        </Collapse>
      ))}
      
      <ConfirmDialog
        visible={showConfirm}
        title="¿Está seguro que desea eliminar este título?"
        content={`Se eliminará el título "${tituloAEliminar?.nombre}" y todas sus funciones asociadas (${tituloAEliminar?.funciones.length}). Esta acción no se puede deshacer.`}
        onConfirm={handleConfirmDelete}
        onCancel={() => setShowConfirm(false)}
        confirmLoading={isDeleting}
      />
    </div>
  );
};
```

**Redux Async Thunk:**
```javascript
export const deleteTitulo = createAsyncThunk(
  'grupos/deleteTitulo',
  async ({ grupoId, tituloId }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.delete(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}/titulos/${tituloId}`
      );
      
      return { grupoId, tituloId, eliminados: response.data.eliminados };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al eliminar título'
      );
    }
  }
);
```

**Reducer:**
```javascript
extraReducers: (builder) => {
  builder.addCase(deleteTitulo.fulfilled, (state, action) => {
    if (state.grupoActual?.grupoId === action.payload.grupoId) {
      // Remover título de lista
      state.grupoActual.titulos = state.grupoActual.titulos.filter(
        t => t.tituloId !== action.payload.tituloId
      );
    }
  });
}
```

### Backend (Spring Boot)

**Endpoint:** DELETE `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}`

**Controller:**
```java
@DeleteMapping("/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}")
public ResponseEntity<DeleteTituloResponse> deleteTitulo(
    @PathVariable String rut,
    @PathVariable String dv,
    @PathVariable Long grupoId,
    @PathVariable Long tituloId
) {
    validateRutFromToken(rut, dv);
    
    DeleteTituloResponse response = grupoService.deleteTitulo(
        grupoId, tituloId, rut + "-" + dv
    );
    
    return ResponseEntity.ok(response);
}
```

**Service:**
```java
@Transactional
public DeleteTituloResponse deleteTitulo(Long grupoId, Long tituloId, String rutUsuario) {
    // 1. Verificar que título existe y pertenece al grupo
    Titulo titulo = tituloRepository.findByIdAndGrupoId(tituloId, grupoId)
        .orElseThrow(() -> new NotFoundException(
            "Título ID " + tituloId + " no existe o no pertenece al grupo " + grupoId
        ));
    
    // 2. Contar funciones asociadas (para auditoría)
    long funcionesCount = tituloFuncionRepository.countByTituloId(tituloId);
    
    // 3. Guardar datos para auditoría
    Map<String, Object> valoresAnteriores = Map.of(
        "nombre", titulo.getNombre(),
        "orden", titulo.getOrden(),
        "grupoId", grupoId,
        "funciones_eliminadas", funcionesCount
    );
    
    // 4. Eliminar título (CASCADE automático)
    tituloRepository.delete(titulo);
    // ON DELETE CASCADE elimina automáticamente BR_TITULOS_FUNCIONES
    
    // 5. Registrar auditoría
    auditoriaService.registrar(
        "BR_TITULOS",
        "DELETE",
        tituloId,
        valoresAnteriores,
        null,
        rutUsuario,
        "Se eliminó el título " + titulo.getNombre() + 
        " del grupo " + grupoId + 
        " (" + funcionesCount + " funciones)"
    );
    
    return DeleteTituloResponse.builder()
        .mensaje("Título eliminado exitosamente")
        .eliminados(Map.of(
            "titulo", 1,
            "funciones", funcionesCount
        ))
        .build();
}
```

### Base de Datos

**Query de verificación:**
```sql
SELECT COUNT(*) 
FROM BR_TITULOS 
WHERE TITU_ID = :tituloId 
  AND TITU_GRUP_ID = :grupoId;
```

**Query de eliminación (CASCADE automático):**
```sql
DELETE FROM BR_TITULOS WHERE TITU_ID = :tituloId;
-- ON DELETE CASCADE en BR_TITULOS_FUNCIONES (FK TIFU_TITU_ID)
-- elimina automáticamente todas las funciones asociadas
```

**Impacto:**
- BR_TITULOS: 1 registro eliminado
- BR_TITULOS_FUNCIONES: N registros eliminados (CASCADE)
- BR_GRUPOS: SIN cambios (grupo permanece intacto)

## Testing

### Frontend

```javascript
describe('TitulosAccordion - Eliminar Título', () => {
  it('debe mostrar modal de confirmación al hacer clic en eliminar', () => {
    const titulo = { tituloId: 46, nombre: 'OT Opciones', funciones: [{}, {}, {}] };
    render(<TitulosAccordion grupo={{ grupoId: 123, titulos: [titulo] }} />);
    
    fireEvent.click(screen.getByRole('button', { name: /delete/ }));
    
    expect(screen.getByText(/¿Está seguro que desea eliminar/)).toBeInTheDocument();
    expect(screen.getByText(/OT Opciones/)).toBeInTheDocument();
    expect(screen.getByText(/3/)).toBeInTheDocument(); // cantidad funciones
  });
  
  it('debe eliminar título exitosamente tras confirmación', async () => {
    const mockDelete = vi.fn().mockResolvedValue({ eliminados: { titulo: 1, funciones: 3 } });
    const titulo = { tituloId: 46, nombre: 'OT Opciones', funciones: [{}, {}, {}] };
    
    render(<TitulosAccordion grupo={{ grupoId: 123, titulos: [titulo] }} />);
    
    fireEvent.click(screen.getByRole('button', { name: /delete/ }));
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }));
    
    await waitFor(() => {
      expect(mockDelete).toHaveBeenCalledWith({ grupoId: 123, tituloId: 46 });
      expect(screen.getByText(/Título eliminado exitosamente/)).toBeInTheDocument();
    });
  });
});
```

### Backend

```java
@Test
void deleteTitulo_conTituloExistente_debeEliminarExitosamente() {
    Titulo titulo = Titulo.builder().id(46L).grupoId(123L).nombre("OT Opciones").orden(2).build();
    when(tituloRepository.findByIdAndGrupoId(46L, 123L)).thenReturn(Optional.of(titulo));
    when(tituloFuncionRepository.countByTituloId(46L)).thenReturn(3L);
    
    DeleteTituloResponse response = grupoService.deleteTitulo(123L, 46L, "12345678-9");
    
    assertEquals(1, response.getEliminados().get("titulo"));
    assertEquals(3L, response.getEliminados().get("funciones"));
    
    verify(tituloRepository, times(1)).delete(titulo);
    verify(auditoriaService, times(1)).registrar(eq("BR_TITULOS"), eq("DELETE"), eq(46L), any(), any(), any(), any());
}

@Test
void deleteTitulo_conTituloNoPerteneciente_debeLanzarNotFoundException() {
    when(tituloRepository.findByIdAndGrupoId(46L, 123L)).thenReturn(Optional.empty());
    
    assertThrows(NotFoundException.class, () -> {
        grupoService.deleteTitulo(123L, 46L, "12345678-9");
    });
    
    verify(tituloRepository, never()).delete(any());
}
```

## Glosario

- **DELETE CASCADE**: Mecanismo de FK que elimina automáticamente registros relacionados cuando se elimina el padre
- **Gap en orden**: Huecos en secuencia de TITU_ORDEN tras eliminaciones (ej: 1, 3, 5) - comportamiento esperado
- **Eliminación concurrente**: Caso edge donde 2 usuarios intentan eliminar el mismo título simultáneamente (HTTP 404)
- **Acordeón**: Componente colapsable que muestra/oculta contenido (Ant Design Collapse/Panel)
