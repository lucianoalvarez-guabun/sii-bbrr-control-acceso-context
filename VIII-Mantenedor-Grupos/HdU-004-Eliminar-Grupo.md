# HdU-004: Eliminar Grupo

## Información General

**ID:** HdU-004  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** eliminar un grupo que ya no se utiliza  
**Para** mantener limpia la base de datos y evitar confusiones con grupos obsoletos  

## Mockups de Referencia

- **image-0034.png**: ConfirmDialog con advertencia "¿Está seguro que desea eliminar...?"
- **image-0127.png**: GroupSection con botón papelera (eliminar)
- **image-0027.png**: Alerta de éxito tras eliminación

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón papelera (icono delete) en el GroupSection junto al nombre del grupo

**AC-002:** Si el grupo tiene usuarios activos (cantidadUsuarios > 0), el botón papelera debe estar deshabilitado (gris) con tooltip "Grupo con usuarios activos"

**AC-003:** Si el grupo NO tiene usuarios activos (cantidadUsuarios = 0), el botón papelera debe estar habilitado (rojo)

**AC-004:** Al hacer clic en botón papelera habilitado, el sistema debe mostrar modal de confirmación (ConfirmDialog) con:
- Icono advertencia (triángulo amarillo)
- Mensaje: "¿Está seguro que desea eliminar el grupo [NOMBRE_GRUPO]? Esta acción no se puede deshacer."
- Botón "Cancelar" (gris)
- Botón "Eliminar" (rojo)

**AC-005:** Si usuario hace clic en "Cancelar", el sistema debe cerrar modal sin ejecutar eliminación

**AC-006:** Si usuario hace clic en "Eliminar", el sistema debe ejecutar DELETE `/{grupoId}` y eliminar:
- Registro en BR_GRUPOS (grupoId)
- Todos los registros en BR_TITULOS (por FK CASCADE)
- Todos los registros en BR_TITULOS_FUNCIONES (por FK CASCADE)
- Registros en BR_USUARIO_GRUPO_ORDEN (si existen)

**AC-007:** Si la eliminación es exitosa (200 OK), el sistema debe:
- Cerrar modal de confirmación
- Mostrar alerta verde "Grupo eliminado exitosamente" por 3 segundos
- Remover el grupo de la lista visual
- Limpiar el área de resultados

**AC-008:** Si el grupo tiene usuarios activos y se intenta eliminar (409 Conflict), el sistema debe mostrar:
- "No se puede eliminar el grupo porque tiene usuarios activos asociados."
- Cerrar modal de confirmación
- Mantener grupo visible

**AC-009:** Si el grupo no existe (404 Not Found), el sistema debe mostrar:
- "Grupo no encontrado. Es posible que ya haya sido eliminado."
- Actualizar lista de grupos

**AC-010:** El sistema debe registrar auditoría con operación='DELETE' incluyendo toda la estructura eliminada (grupo, títulos, funciones)

## Flujos Principales

### Flujo 1: Eliminación Exitosa (Sin Usuarios)

1. Usuario busca grupo "Sistema Test" con filtro "Vigente"
2. Sistema muestra GroupSection con cantidadUsuarios=0
3. Sistema habilita botón papelera (rojo, clickeable)
4. Usuario hace clic en botón papelera
5. Sistema abre modal ConfirmDialog (image-0034):
   - Icono advertencia
   - Texto: "¿Está seguro que desea eliminar el grupo Sistema Test? Esta acción no se puede deshacer."
   - Botones: Cancelar (gris), Eliminar (rojo)
6. Usuario hace clic en botón "Eliminar"
7. Sistema cierra modal
8. Sistema ejecuta DELETE `/acaj-ms/api/v1/12.345.678-9/grupos/123`
9. Backend verifica usuarios activos:
   ```sql
   SELECT COUNT(*) FROM BR_USUARIO_GRUPO 
   WHERE USGR_GRUP_ID = 123 AND USGR_ACTIVO = 'S';
   -- Result: 0
   ```
10. Backend ejecuta DELETE con CASCADE:
    ```sql
    DELETE FROM BR_GRUPOS WHERE GRUP_ID = 123;
    -- Cascade elimina automáticamente:
    --   BR_TITULOS (2 registros)
    --   BR_TITULOS_FUNCIONES (5 registros)
    ```
11. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_ANTERIORES,
      AUDI_JUSTIFICACION
    ) VALUES (
      'DELETE', 'BR_GRUPOS', 123,
      JSON_OBJECT(
        'nombre' VALUE 'Sistema Test',
        'titulos_eliminados' VALUE 2,
        'funciones_eliminadas' VALUE 5
      ),
      'Se eliminó el grupo Sistema Test (2 títulos, 5 funciones)'
    );
    ```
12. Backend retorna 200 OK:
    ```json
    {
      "mensaje": "Grupo eliminado exitosamente",
      "eliminados": {
        "grupo": 1,
        "titulos": 2,
        "funciones": 5
      }
    }
    ```
13. Sistema muestra alerta verde "Grupo eliminado exitosamente" (image-0027)
14. Sistema remueve grupo de lista visual
15. Sistema limpia área de resultados mostrando mensaje "Seleccione un grupo para ver detalles"

### Flujo 2: Intento de Eliminar Grupo con Usuarios (409 Conflict)

1. Usuario sigue pasos 1-6 del Flujo 1, pero grupo tiene cantidadUsuarios=100
2. Sistema muestra botón papelera deshabilitado (gris)
3. Usuario hace hover sobre botón papelera
4. Sistema muestra tooltip: "Grupo con usuarios activos"
5. Usuario NO puede hacer clic (botón disabled)

**Caso Edge:** Si usuario intenta eliminar vía API directamente (bypass UI):
1. Backend ejecuta verificación de usuarios activos
2. Backend encuentra 100 usuarios activos
3. Backend lanza ConflictException
4. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "No se puede eliminar el grupo porque tiene usuarios activos asociados."
   }
   ```
5. Sistema muestra mensaje de error en alerta roja por 5 segundos

### Flujo 3: Cancelación de Eliminación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón "Cancelar"
3. Sistema cierra modal ConfirmDialog inmediatamente
4. Sistema NO ejecuta DELETE
5. Sistema mantiene grupo visible sin cambios
6. Usuario puede continuar operando con el grupo

## Notas Técnicas

### Frontend (React)

**Componente:** GroupSection con ConfirmDialog

**Estado local:**
```jsx
const GroupSection = ({ grupo }) => {
  const dispatch = useDispatch();
  const [showConfirm, setShowConfirm] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  
  const handleDelete = async () => {
    setIsDeleting(true);
    
    try {
      await dispatch(deleteGrupo(grupo.grupoId)).unwrap();
      
      message.success('Grupo eliminado exitosamente', 3);
      setShowConfirm(false);
      
      // Limpiar área de resultados
      dispatch(clearGrupoActual());
    } catch (error) {
      message.error(error || 'Error al eliminar grupo', 5);
      setShowConfirm(false);
    } finally {
      setIsDeleting(false);
    }
  };
  
  const canDelete = grupo.cantidadUsuarios === 0;
  
  return (
    <div className="group-section">
      <h3>{grupo.nombre}</h3>
      
      <Tooltip title={canDelete ? '' : 'Grupo con usuarios activos'}>
        <Button
          icon={<DeleteOutlined />}
          danger
          disabled={!canDelete}
          onClick={() => setShowConfirm(true)}
        />
      </Tooltip>
      
      <ConfirmDialog
        visible={showConfirm}
        title="¿Está seguro que desea eliminar el grupo?"
        content={`Esta acción eliminará el grupo "${grupo.nombre}" y todos sus títulos y funciones. Esta acción no se puede deshacer.`}
        onConfirm={handleDelete}
        onCancel={() => setShowConfirm(false)}
        confirmLoading={isDeleting}
      />
    </div>
  );
};
```

**Componente ConfirmDialog:**
```jsx
const ConfirmDialog = ({ visible, title, content, onConfirm, onCancel, confirmLoading }) => {
  return (
    <Modal
      open={visible}
      title={<><WarningOutlined style={{ color: '#faad14' }} /> {title}</>}
      onCancel={onCancel}
      footer={[
        <Button key="cancel" onClick={onCancel}>
          Cancelar
        </Button>,
        <Button
          key="confirm"
          type="primary"
          danger
          loading={confirmLoading}
          onClick={onConfirm}
        >
          Eliminar
        </Button>
      ]}
    >
      <p>{content}</p>
    </Modal>
  );
};
```

**Redux Async Thunk:**
```javascript
export const deleteGrupo = createAsyncThunk(
  'grupos/delete',
  async (grupoId, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.delete(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}`
      );
      
      return { grupoId, eliminados: response.data.eliminados };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al eliminar grupo'
      );
    }
  }
);
```

### Backend (Spring Boot)

**Endpoint:** DELETE `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}`

**Controller:**
```java
@DeleteMapping("/{rut}-{dv}/grupos/{grupoId}")
public ResponseEntity<DeleteGrupoResponse> delete(
    @PathVariable String rut,
    @PathVariable String dv,
    @PathVariable Long grupoId
) {
    validateRutFromToken(rut, dv);
    
    DeleteGrupoResponse response = grupoService.delete(grupoId, rut + "-" + dv);
    
    return ResponseEntity.ok(response);
}
```

**Service:**
```java
@Transactional
public DeleteGrupoResponse delete(Long grupoId, String rutUsuario) {
    // 1. Verificar que grupo existe
    Grupo grupo = grupoRepository.findById(grupoId)
        .orElseThrow(() -> new NotFoundException("Grupo ID " + grupoId + " no existe"));
    
    // 2. Verificar usuarios activos
    long usuariosActivos = usuarioGrupoRepository.countByGrupoIdAndActivo(grupoId, "S");
    
    if (usuariosActivos > 0) {
        throw new ConflictException(
            "No se puede eliminar el grupo porque tiene " + usuariosActivos + " usuarios activos asociados."
        );
    }
    
    // 3. Contar registros a eliminar (para auditoría)
    long titulosCount = tituloRepository.countByGrupoId(grupoId);
    long funcionesCount = tituloFuncionRepository.countByGrupoId(grupoId);
    
    // 4. Guardar datos para auditoría
    Map<String, Object> valoresAnteriores = Map.of(
        "nombre", grupo.getNombre(),
        "vigente", grupo.getVigente(),
        "titulos_eliminados", titulosCount,
        "funciones_eliminadas", funcionesCount
    );
    
    // 5. Eliminar (CASCADE automático)
    grupoRepository.delete(grupo);
    // ON DELETE CASCADE elimina:
    //   - BR_TITULOS (por FK TITU_GRUP_ID)
    //   - BR_TITULOS_FUNCIONES (por FK TIFU_TITU_ID via BR_TITULOS)
    
    // 6. Eliminar orden de usuarios (si existe)
    usuarioGrupoOrdenRepository.deleteByGrupoId(grupoId);
    
    // 7. Registrar auditoría
    auditoriaService.registrar(
        "BR_GRUPOS",
        "DELETE",
        grupoId,
        valoresAnteriores,
        null,
        rutUsuario,
        "Se eliminó el grupo " + grupo.getNombre() + 
        " (" + titulosCount + " títulos, " + funcionesCount + " funciones)"
    );
    
    return DeleteGrupoResponse.builder()
        .mensaje("Grupo eliminado exitosamente")
        .eliminados(Map.of(
            "grupo", 1,
            "titulos", titulosCount,
            "funciones", funcionesCount
        ))
        .build();
}
```

### Base de Datos

**Queries ejecutadas:**

1. **Verificar usuarios activos:**
```sql
SELECT COUNT(*) 
FROM BR_USUARIO_GRUPO 
WHERE USGR_GRUP_ID = :grupoId 
  AND USGR_ACTIVO = 'S';
```

2. **Contar títulos y funciones (para auditoría):**
```sql
SELECT COUNT(*) FROM BR_TITULOS WHERE TITU_GRUP_ID = :grupoId;

SELECT COUNT(*) FROM BR_TITULOS_FUNCIONES tf
JOIN BR_TITULOS t ON t.TITU_ID = tf.TIFU_TITU_ID
WHERE t.TITU_GRUP_ID = :grupoId;
```

3. **Eliminar grupo (CASCADE automático):**
```sql
DELETE FROM BR_GRUPOS WHERE GRUP_ID = :grupoId;
```

**Impacto de CASCADE:**
- BR_TITULOS: todos los títulos del grupo (por FK TITU_GRUP_ID ON DELETE CASCADE)
- BR_TITULOS_FUNCIONES: todas las funciones de los títulos (por FK TIFU_TITU_ID ON DELETE CASCADE)

## Testing

### Frontend

```javascript
describe('GroupSection - Eliminar Grupo', () => {
  it('debe deshabilitar botón eliminar si grupo tiene usuarios', () => {
    render(<GroupSection grupo={{ grupoId: 123, nombre: 'Sistema OT', cantidadUsuarios: 100 }} />);
    
    const deleteButton = screen.getByRole('button', { name: /delete/ });
    expect(deleteButton).toBeDisabled();
  });
  
  it('debe mostrar modal de confirmación al hacer clic en eliminar', () => {
    render(<GroupSection grupo={{ grupoId: 123, nombre: 'Sistema Test', cantidadUsuarios: 0 }} />);
    
    fireEvent.click(screen.getByRole('button', { name: /delete/ }));
    
    expect(screen.getByText(/¿Está seguro que desea eliminar/)).toBeInTheDocument();
    expect(screen.getByText(/Esta acción no se puede deshacer/)).toBeInTheDocument();
  });
  
  it('debe eliminar grupo exitosamente tras confirmación', async () => {
    const mockDelete = vi.fn().mockResolvedValue({ eliminados: { grupo: 1, titulos: 2, funciones: 5 } });
    
    render(<GroupSection grupo={{ grupoId: 123, nombre: 'Sistema Test', cantidadUsuarios: 0 }} />);
    
    // Abrir modal
    fireEvent.click(screen.getByRole('button', { name: /delete/ }));
    
    // Confirmar eliminación
    fireEvent.click(screen.getByRole('button', { name: /Eliminar/ }));
    
    await waitFor(() => {
      expect(mockDelete).toHaveBeenCalledWith(123);
      expect(screen.getByText(/Grupo eliminado exitosamente/)).toBeInTheDocument();
    });
  });
});
```

### Backend

```java
@Test
void delete_conUsuariosActivos_debeLanzarConflictException() {
    when(grupoRepository.findById(123L)).thenReturn(Optional.of(grupo));
    when(usuarioGrupoRepository.countByGrupoIdAndActivo(123L, "S")).thenReturn(100L);
    
    assertThrows(ConflictException.class, () -> {
        grupoService.delete(123L, "12345678-9");
    });
    
    verify(grupoRepository, never()).delete(any());
}

@Test
void delete_sinUsuarios_debeEliminarExitosamente() {
    when(grupoRepository.findById(123L)).thenReturn(Optional.of(grupo));
    when(usuarioGrupoRepository.countByGrupoIdAndActivo(123L, "S")).thenReturn(0L);
    when(tituloRepository.countByGrupoId(123L)).thenReturn(2L);
    when(tituloFuncionRepository.countByGrupoId(123L)).thenReturn(5L);
    
    DeleteGrupoResponse response = grupoService.delete(123L, "12345678-9");
    
    assertEquals(1, response.getEliminados().get("grupo"));
    assertEquals(2L, response.getEliminados().get("titulos"));
    assertEquals(5L, response.getEliminados().get("funciones"));
    
    verify(grupoRepository, times(1)).delete(grupo);
    verify(auditoriaService, times(1)).registrar(eq("BR_GRUPOS"), eq("DELETE"), eq(123L), any(), any(), any(), any());
}
```

## Glosario

- **DELETE CASCADE**: Mecanismo de Oracle que elimina automáticamente registros relacionados cuando se elimina el registro padre
- **Conflict (409)**: Error HTTP que indica que la operación no se puede completar por conflicto de estado (ej: usuarios activos)
- **Soft Delete**: Eliminación lógica (no física) mediante campo activo/inactivo - NO aplicado en este módulo
- **Hard Delete**: Eliminación física del registro de la base de datos - usado en este módulo
