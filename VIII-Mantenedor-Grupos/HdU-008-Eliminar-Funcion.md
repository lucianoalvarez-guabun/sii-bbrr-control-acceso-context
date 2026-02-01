# HdU-008: Eliminar Función de Título

## Información General

**ID:** HdU-008  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Media  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** eliminar una función específica de un título  
**Para** ajustar los permisos del título sin tener que eliminarlo completamente  

## Mockups de Referencia

- **image-0127.png**: Lista de funciones con botón eliminar (X) por función
- **image-0034.png**: ConfirmDialog "¿Está seguro que desea eliminar...?"
- **image-0027.png**: Alerta de éxito tras eliminación

## Criterios de Aceptación

**AC-001:** Cada función en la lista (dentro del acordeón del título) debe mostrar un botón eliminar (icono X) al lado derecho

**AC-002:** Al hacer clic en botón eliminar, el sistema debe mostrar modal de confirmación (ConfirmDialog) con:
- Icono advertencia (triángulo amarillo)
- Mensaje: "¿Está seguro que desea eliminar la función [NOMBRE_FUNCION] del título [NOMBRE_TITULO]? Esta acción no se puede deshacer."
- Botón "Cancelar" (gris)
- Botón "Eliminar" (rojo)

**AC-003:** Si usuario hace clic en "Cancelar", el sistema debe cerrar modal sin ejecutar eliminación

**AC-004:** Si usuario hace clic en "Eliminar", el sistema debe:
- Verificar que el título tenga al menos 2 funciones (no permitir eliminar la última)
- Ejecutar DELETE `/{grupoId}/titulos/{tituloId}/funciones/{funcionId}`
- Eliminar registro en BR_TITULOS_FUNCIONES

**AC-005:** Si la eliminación es exitosa (200 OK), el sistema debe:
- Cerrar modal de confirmación
- Mostrar alerta verde "Función eliminada exitosamente" por 3 segundos
- Remover la función de la lista visual del título
- Actualizar contador de funciones del título

**AC-006:** Si el título solo tiene 1 función (última), el botón eliminar debe estar deshabilitado (gris) con tooltip "No se puede eliminar la última función del título"

**AC-007:** Si se intenta eliminar la última función vía API (bypass UI), el sistema debe retornar 409 Conflict:
- "No se puede eliminar la última función del título."

**AC-008:** Si la función no existe o ya fue eliminada (404 Not Found), el sistema debe mostrar:
- "Función no encontrada. Es posible que ya haya sido eliminada."
- Actualizar vista del título

**AC-009:** El sistema debe registrar auditoría con operación='DELETE'

**AC-010:** La eliminación solo afecta la relación (BR_TITULOS_FUNCIONES), NO elimina la función de BR_FUNCIONES (función sigue existiendo para otros títulos)

## Flujos Principales

### Flujo 1: Eliminación Exitosa de Función

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Usuario expande título "OT Reportes" (tituloId=45)
3. Sistema muestra 3 funciones:
   - "csdfcasc" (funcionId=15) con botón X habilitado
   - "Función 2" (funcionId=16) con botón X habilitado
   - "Función 3" (funcionId=19) con botón X habilitado
4. Usuario hace clic en botón X de "Función 2"
5. Sistema abre modal ConfirmDialog (image-0034):
   - Icono advertencia
   - Texto: "¿Está seguro que desea eliminar la función 'Función 2' del título 'OT Reportes'? Esta acción no se puede deshacer."
   - Botones: Cancelar, Eliminar
6. Usuario hace clic en botón "Eliminar"
7. Sistema cierra modal
8. Sistema ejecuta DELETE `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/45/funciones/16`
9. Backend verifica cantidad de funciones del título:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS_FUNCIONES 
   WHERE TIFU_TITU_ID = 45;
   -- Result: 3 (OK, tiene más de 1)
   ```
10. Backend ejecuta DELETE:
    ```sql
    DELETE FROM BR_TITULOS_FUNCIONES 
    WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 16;
    ```
11. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_ANTERIORES, AUDI_JUSTIFICACION
    ) VALUES (
      'DELETE', 'BR_TITULOS_FUNCIONES', NULL,
      JSON_OBJECT(
        'tituloId' VALUE 45,
        'funcionId' VALUE 16,
        'tituloNombre' VALUE 'OT Reportes',
        'funcionNombre' VALUE 'Función 2'
      ),
      'Se eliminó la función Función 2 del título OT Reportes del grupo Sistema OT'
    );
    ```
12. Backend retorna 200 OK:
    ```json
    {
      "mensaje": "Función eliminada exitosamente"
    }
    ```
13. Sistema muestra alerta verde "Función eliminada exitosamente" (image-0027)
14. Sistema remueve "Función 2" de la lista visual
15. Sistema actualiza contador: "OT Reportes (2)" (antes era 3)
16. Funciones restantes: "csdfcasc", "Función 3"

### Flujo 2: Intento de Eliminar Última Función (UI Bloqueado)

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Usuario expande título "Título con 1 Función" (tituloId=50)
3. Sistema muestra 1 función:
   - "Función Única" (funcionId=25) con botón X deshabilitado (gris)
4. Usuario hace hover sobre botón X deshabilitado
5. Sistema muestra tooltip: "No se puede eliminar la última función del título"
6. Usuario NO puede hacer clic (botón disabled)

**Caso Edge:** Si usuario intenta eliminar vía API directamente (bypass UI):
1. Backend ejecuta verificación de cantidad de funciones
2. Backend encuentra COUNT=1
3. Backend lanza ConflictException
4. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "No se puede eliminar la última función del título."
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos

### Flujo 3: Cancelación de Eliminación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón "Cancelar"
3. Sistema cierra modal ConfirmDialog inmediatamente
4. Sistema NO ejecuta DELETE
5. Función permanece visible sin cambios
6. Usuario puede continuar operando con la función

### Flujo 4: Función No Existe (404)

1. Usuario sigue pasos 1-8 del Flujo 1
2. Backend ejecuta DELETE pero no encuentra registro (ya eliminado concurrentemente)
3. Backend lanza NotFoundException
4. Backend retorna 404 Not Found:
   ```json
   {
     "error": "No encontrado",
     "mensaje": "Función ID 16 no existe en el título 45"
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos:
   - "Función no encontrada. Es posible que ya haya sido eliminada."
6. Sistema actualiza vista del título (re-ejecuta búsqueda)
7. Función desaparece de lista (si fue eliminada por otro usuario)

## Notas Técnicas

### Frontend (React)

**Componente:** TitulosAccordion (sección de funciones)

**Manejo de eliminación:**
```jsx
const FuncionList = ({ grupo, titulo }) => {
  const dispatch = useDispatch();
  const [funcionAEliminar, setFuncionAEliminar] = useState(null);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  
  const handleDeleteClick = (funcion) => {
    // Verificar que no sea la última función
    if (titulo.funciones.length <= 1) {
      message.warning('No se puede eliminar la última función del título');
      return;
    }
    
    setFuncionAEliminar(funcion);
    setShowConfirm(true);
  };
  
  const handleConfirmDelete = async () => {
    setIsDeleting(true);
    
    try {
      await dispatch(deleteFuncionFromTitulo({ 
        grupoId: grupo.grupoId,
        tituloId: titulo.tituloId, 
        funcionId: funcionAEliminar.funcionId 
      })).unwrap();
      
      message.success('Función eliminada exitosamente', 3);
      setShowConfirm(false);
      setFuncionAEliminar(null);
    } catch (error) {
      message.error(error || 'Error al eliminar función. Intente nuevamente.', 5);
      setShowConfirm(false);
    } finally {
      setIsDeleting(false);
    }
  };
  
  const isLastFunction = titulo.funciones.length <= 1;
  
  return (
    <div className="funcion-list">
      {titulo.funciones.map(funcion => (
        <div key={funcion.funcionId} className="funcion-item">
          <span>{funcion.nombre}</span>
          {funcion.descripcion && <span className="descripcion">{funcion.descripcion}</span>}
          
          <Tooltip title={isLastFunction ? 'No se puede eliminar la última función del título' : ''}>
            <Button
              icon={<CloseOutlined />}
              danger
              size="small"
              disabled={isLastFunction}
              onClick={() => handleDeleteClick(funcion)}
            />
          </Tooltip>
        </div>
      ))}
      
      <ConfirmDialog
        visible={showConfirm}
        title="¿Está seguro que desea eliminar esta función?"
        content={`Se eliminará la función "${funcionAEliminar?.nombre}" del título "${titulo.nombre}". Esta acción no se puede deshacer.`}
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
export const deleteFuncionFromTitulo = createAsyncThunk(
  'grupos/deleteFuncionFromTitulo',
  async ({ grupoId, tituloId, funcionId }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.delete(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}/titulos/${tituloId}/funciones/${funcionId}`
      );
      
      return { tituloId, funcionId };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al eliminar función'
      );
    }
  }
);
```

**Reducer:**
```javascript
extraReducers: (builder) => {
  builder.addCase(deleteFuncionFromTitulo.fulfilled, (state, action) => {
    if (state.grupoActual) {
      // Buscar título y remover función
      const titulo = state.grupoActual.titulos.find(
        t => t.tituloId === action.payload.tituloId
      );
      
      if (titulo) {
        titulo.funciones = titulo.funciones.filter(
          f => f.funcionId !== action.payload.funcionId
        );
      }
    }
  });
}
```

### Backend (Spring Boot)

**Endpoint:** DELETE `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}`

**Controller:**
```java
@DeleteMapping("/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones/{funcionId}")
public ResponseEntity<DeleteFuncionResponse> deleteFuncionFromTitulo(
    @PathVariable String rut,
    @PathVariable String dv,
    @PathVariable Long grupoId,
    @PathVariable Long tituloId,
    @PathVariable Long funcionId
) {
    validateRutFromToken(rut, dv);
    
    DeleteFuncionResponse response = grupoService.deleteFuncionFromTitulo(
        grupoId, tituloId, funcionId, rut + "-" + dv
    );
    
    return ResponseEntity.ok(response);
}
```

**Service:**
```java
@Transactional
public DeleteFuncionResponse deleteFuncionFromTitulo(
    Long grupoId, Long tituloId, Long funcionId, String rutUsuario
) {
    // 1. Verificar que título existe y pertenece al grupo
    Titulo titulo = tituloRepository.findByIdAndGrupoId(tituloId, grupoId)
        .orElseThrow(() -> new NotFoundException("Título no existe o no pertenece al grupo"));
    
    // 2. Verificar cantidad de funciones del título (no permitir eliminar la última)
    long funcionesCount = tituloFuncionRepository.countByTituloId(tituloId);
    
    if (funcionesCount <= 1) {
        throw new ConflictException("No se puede eliminar la última función del título.");
    }
    
    // 3. Buscar relación título-función
    TituloFuncion tituloFuncion = tituloFuncionRepository
        .findByTituloIdAndFuncionId(tituloId, funcionId)
        .orElseThrow(() -> new NotFoundException(
            "Función ID " + funcionId + " no existe en el título " + tituloId
        ));
    
    // 4. Obtener datos para auditoría
    Funcion funcion = funcionRepository.findById(funcionId)
        .orElseThrow(() -> new NotFoundException("Función no existe"));
    
    Map<String, Object> valoresAnteriores = Map.of(
        "tituloId", tituloId,
        "funcionId", funcionId,
        "tituloNombre", titulo.getNombre(),
        "funcionNombre", funcion.getNombre(),
        "grupoId", grupoId
    );
    
    // 5. Eliminar relación (solo elimina registro en BR_TITULOS_FUNCIONES, NO en BR_FUNCIONES)
    tituloFuncionRepository.delete(tituloFuncion);
    
    // 6. Registrar auditoría
    auditoriaService.registrar(
        "BR_TITULOS_FUNCIONES",
        "DELETE",
        null,
        valoresAnteriores,
        null,
        rutUsuario,
        "Se eliminó la función " + funcion.getNombre() + 
        " del título " + titulo.getNombre() + 
        " del grupo " + grupoId
    );
    
    return DeleteFuncionResponse.builder()
        .mensaje("Función eliminada exitosamente")
        .build();
}
```

### Base de Datos

**Query verificar cantidad de funciones:**
```sql
SELECT COUNT(*) 
FROM BR_TITULOS_FUNCIONES 
WHERE TIFU_TITU_ID = :tituloId;
```

**Query eliminar relación:**
```sql
DELETE FROM BR_TITULOS_FUNCIONES 
WHERE TIFU_TITU_ID = :tituloId 
  AND TIFU_FUNC_ID = :funcionId;
```

**Impacto:**
- BR_TITULOS_FUNCIONES: 1 registro eliminado (solo la relación)
- BR_FUNCIONES: SIN cambios (función permanece en catálogo para otros títulos)
- BR_TITULOS: SIN cambios (título permanece intacto)

## Testing

### Frontend

```javascript
describe('FuncionList - Eliminar Función', () => {
  it('debe deshabilitar botón eliminar si es la última función', () => {
    const titulo = { tituloId: 45, nombre: 'OT Reportes', funciones: [{ funcionId: 15, nombre: 'Única' }] };
    
    render(<FuncionList grupo={{ grupoId: 123 }} titulo={titulo} />);
    
    const deleteButton = screen.getByRole('button', { name: /close/ });
    expect(deleteButton).toBeDisabled();
  });
  
  it('debe mostrar modal de confirmación al hacer clic en eliminar', () => {
    const titulo = { 
      tituloId: 45, 
      nombre: 'OT Reportes', 
      funciones: [
        { funcionId: 15, nombre: 'Función 1' },
        { funcionId: 16, nombre: 'Función 2' }
      ] 
    };
    
    render(<FuncionList grupo={{ grupoId: 123 }} titulo={titulo} />);
    
    const deleteButtons = screen.getAllByRole('button', { name: /close/ });
    fireEvent.click(deleteButtons[1]); // Segunda función
    
    expect(screen.getByText(/¿Está seguro que desea eliminar/)).toBeInTheDocument();
    expect(screen.getByText(/Función 2/)).toBeInTheDocument();
  });
  
  it('debe eliminar función exitosamente tras confirmación', async () => {
    const mockDelete = vi.fn().mockResolvedValue({});
    const titulo = { 
      tituloId: 45, 
      funciones: [
        { funcionId: 15, nombre: 'Función 1' },
        { funcionId: 16, nombre: 'Función 2' }
      ] 
    };
    
    render(<FuncionList grupo={{ grupoId: 123 }} titulo={titulo} />);
    
    const deleteButtons = screen.getAllByRole('button', { name: /close/ });
    fireEvent.click(deleteButtons[1]);
    
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }));
    
    await waitFor(() => {
      expect(mockDelete).toHaveBeenCalledWith({ 
        grupoId: 123, 
        tituloId: 45, 
        funcionId: 16 
      });
      expect(screen.getByText(/Función eliminada exitosamente/)).toBeInTheDocument();
    });
  });
});
```

### Backend

```java
@Test
void deleteFuncionFromTitulo_conUltimaFuncion_debeLanzarConflictException() {
    when(tituloRepository.findByIdAndGrupoId(45L, 123L)).thenReturn(Optional.of(titulo));
    when(tituloFuncionRepository.countByTituloId(45L)).thenReturn(1L);
    
    assertThrows(ConflictException.class, () -> {
        grupoService.deleteFuncionFromTitulo(123L, 45L, 15L, "12345678-9");
    });
    
    verify(tituloFuncionRepository, never()).delete(any());
}

@Test
void deleteFuncionFromTitulo_conMultiplesFunciones_debeEliminarRelacion() {
    when(tituloRepository.findByIdAndGrupoId(45L, 123L)).thenReturn(Optional.of(titulo));
    when(tituloFuncionRepository.countByTituloId(45L)).thenReturn(3L);
    when(tituloFuncionRepository.findByTituloIdAndFuncionId(45L, 16L))
        .thenReturn(Optional.of(tituloFuncion));
    when(funcionRepository.findById(16L)).thenReturn(Optional.of(funcion));
    
    DeleteFuncionResponse response = grupoService.deleteFuncionFromTitulo(
        123L, 45L, 16L, "12345678-9"
    );
    
    assertEquals("Función eliminada exitosamente", response.getMensaje());
    verify(tituloFuncionRepository, times(1)).delete(tituloFuncion);
    verify(auditoriaService, times(1)).registrar(
        eq("BR_TITULOS_FUNCIONES"), eq("DELETE"), any(), any(), any(), any(), any()
    );
}

@Test
void deleteFuncionFromTitulo_conFuncionNoAsignada_debeLanzarNotFoundException() {
    when(tituloRepository.findByIdAndGrupoId(45L, 123L)).thenReturn(Optional.of(titulo));
    when(tituloFuncionRepository.countByTituloId(45L)).thenReturn(3L);
    when(tituloFuncionRepository.findByTituloIdAndFuncionId(45L, 999L))
        .thenReturn(Optional.empty());
    
    assertThrows(NotFoundException.class, () -> {
        grupoService.deleteFuncionFromTitulo(123L, 45L, 999L, "12345678-9");
    });
}
```

## Glosario

- **Eliminar relación**: Eliminar solo el vínculo entre título y función (BR_TITULOS_FUNCIONES), NO la función del catálogo
- **Última función**: Restricción de negocio que impide eliminar la única función restante de un título
- **Tooltip**: Mensaje emergente informativo que aparece al hacer hover sobre un elemento
- **Eliminación concurrente**: Caso edge donde 2 usuarios intentan eliminar la misma función simultáneamente (HTTP 404)
