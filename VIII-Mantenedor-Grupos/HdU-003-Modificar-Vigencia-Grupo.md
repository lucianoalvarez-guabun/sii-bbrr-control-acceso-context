# HdU-003: Modificar Vigencia de Grupo

## Información General

**ID:** HdU-003  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Media  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** activar o desactivar la vigencia de un grupo  
**Para** controlar qué grupos están disponibles para asignación a usuarios sin eliminarlos permanentemente  

## Mockups de Referencia

- **image-0127.png**: GroupSection mostrando toggle vigente (switch on/off)
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un toggle (switch) de vigencia en el GroupSection junto al nombre del grupo

**AC-002:** Si el grupo está vigente (GRUP_VIGENTE='S'), el switch debe estar activado (ON, color verde)

**AC-003:** Si el grupo NO está vigente (GRUP_VIGENTE='N'), el switch debe estar desactivado (OFF, color gris)

**AC-004:** Al hacer clic en el switch, el sistema debe cambiar el estado de vigencia de forma inmediata (sin confirmación)

**AC-005:** El sistema debe ejecutar PUT `/{grupoId}/vigencia` con el nuevo valor ('S' o 'N')

**AC-006:** Si la actualización es exitosa (200 OK), el sistema debe:
- Actualizar visualmente el switch al nuevo estado
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Registrar auditoría con operación='UPDATE'

**AC-007:** Si el grupo tiene usuarios activos (cantidadUsuarios > 0) y se intenta cambiar a NO vigente, el sistema debe permitir el cambio con advertencia posterior

**AC-008:** Si ocurre un error de servidor (500), el sistema debe:
- Revertir el switch a su estado anterior
- Mostrar mensaje "Error al actualizar vigencia. Intente nuevamente."

**AC-009:** El cambio de vigencia NO debe afectar las asignaciones existentes de usuarios al grupo (BR_USUARIO_GRUPO permanece intacto)

**AC-010:** El sistema debe actualizar automáticamente el dropdown de búsqueda si el grupo ya no cumple el filtro vigente actual

## Flujos Principales

### Flujo 1: Cambiar de Vigente a No Vigente

1. Usuario busca grupo "Sistema OT" con filtro "Vigente" (vigente='S')
2. Sistema muestra GroupSection con switch vigente activado (verde, ON)
3. Usuario hace clic en switch
4. Sistema cambia visualmente switch a OFF (gris)
5. Sistema ejecuta PUT `/acaj-ms/api/v1/12.345.678-9/grupos/123/vigencia` con body:
   ```json
   { "vigente": "N" }
   ```
6. Backend valida grupo existe
7. Backend ejecuta UPDATE en BR_GRUPOS:
   ```sql
   UPDATE BR_GRUPOS 
   SET GRUP_VIGENTE = 'N',
       GRUP_FECHA_MODIFICACION = SYSDATE,
       GRUP_USUARIO_MODIFICACION = '12.345.678-9'
   WHERE GRUP_ID = 123;
   ```
8. Backend registra auditoría:
   ```sql
   INSERT INTO BR_AUDITORIA_CAMBIOS (
     AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
     AUDI_VALORES_ANTERIORES, AUDI_VALORES_NUEVOS,
     AUDI_JUSTIFICACION
   ) VALUES (
     'UPDATE', 'BR_GRUPOS', 123,
     JSON_OBJECT('vigente' VALUE 'S'),
     JSON_OBJECT('vigente' VALUE 'N'),
     'Se modificó la vigencia del Grupo Sistema OT a No Vigente'
   );
   ```
9. Backend retorna 200 OK:
   ```json
   {
     "mensaje": "Vigencia actualizada",
     "grupoId": 123,
     "nuevaVigencia": "N"
   }
   ```
10. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
11. Sistema mantiene switch en estado OFF
12. Grupo desaparece del dropdown de búsqueda (filtrado por vigente='S')

### Flujo 2: Cambiar de No Vigente a Vigente

1. Usuario busca grupo "Grupo Antiguo" con filtro "No Vigente" (vigente='N')
2. Sistema muestra GroupSection con switch desactivado (gris, OFF)
3. Usuario hace clic en switch
4. Sistema cambia visualmente switch a ON (verde)
5. Sistema ejecuta PUT con body `{ "vigente": "S" }`
6. Backend actualiza GRUP_VIGENTE='S'
7. Sistema muestra alerta verde "Registro guardado correctamente"
8. Grupo aparece en dropdown de búsqueda con filtro "Vigente"

### Flujo 3: Error de Servidor (500)

1. Usuario sigue pasos 1-5 del Flujo 1
2. Backend lanza SQLException por lock de tabla
3. Backend retorna 500 Internal Server Error:
   ```json
   {
     "error": "Servidor",
     "mensaje": "Error al actualizar vigencia. Intente nuevamente."
   }
   ```
4. Sistema revierte switch a estado anterior (ON)
5. Sistema muestra mensaje de error en alerta roja por 5 segundos
6. Sistema registra error en console.error con stack trace

## Notas Técnicas

### Frontend (React)

**Componente:** GroupSection

**Manejo de estado local:**
```jsx
const GroupSection = ({ grupo }) => {
  const dispatch = useDispatch();
  const [isUpdating, setIsUpdating] = useState(false);
  
  const handleToggleVigencia = async (checked) => {
    const newVigente = checked ? 'S' : 'N';
    setIsUpdating(true);
    
    try {
      await dispatch(toggleVigencia({ 
        grupoId: grupo.grupoId, 
        vigente: newVigente 
      })).unwrap();
      
      message.success('Registro guardado correctamente', 3);
    } catch (error) {
      message.error(error || 'Error al actualizar vigencia. Intente nuevamente.', 5);
    } finally {
      setIsUpdating(false);
    }
  };
  
  return (
    <div className="group-section">
      <h3>{grupo.nombre}</h3>
      
      <Switch
        checked={grupo.vigente === 'S'}
        onChange={handleToggleVigencia}
        loading={isUpdating}
        checkedChildren="Vigente"
        unCheckedChildren="No Vigente"
      />
      
      {/* ... resto del componente ... */}
    </div>
  );
};
```

**Redux Async Thunk:**
```javascript
export const toggleVigencia = createAsyncThunk(
  'grupos/toggleVigencia',
  async ({ grupoId, vigente }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.put(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}/vigencia`,
        { vigente }
      );
      
      return { grupoId, nuevaVigencia: vigente };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al actualizar vigencia'
      );
    }
  }
);
```

**Reducer:**
```javascript
extraReducers: (builder) => {
  builder.addCase(toggleVigencia.fulfilled, (state, action) => {
    if (state.grupoActual?.grupoId === action.payload.grupoId) {
      state.grupoActual.vigente = action.payload.nuevaVigencia;
    }
  });
}
```

### Backend (Spring Boot)

**Endpoint:** PUT `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/vigencia`

**Controller:**
```java
@PutMapping("/{rut}-{dv}/grupos/{grupoId}/vigencia")
public ResponseEntity<UpdateVigenciaResponse> updateVigencia(
    @PathVariable String rut,
    @PathVariable String dv,
    @PathVariable Long grupoId,
    @Valid @RequestBody UpdateVigenciaRequest request
) {
    validateRutFromToken(rut, dv);
    
    UpdateVigenciaResponse response = grupoService.updateVigencia(
        grupoId, request.getVigente(), rut + "-" + dv
    );
    
    return ResponseEntity.ok(response);
}
```

**DTO Request:**
```java
public class UpdateVigenciaRequest {
    @NotBlank(message = "Vigente es obligatorio")
    @Pattern(regexp = "^[SN]$", message = "Vigente debe ser 'S' o 'N'")
    private String vigente;
}
```

**Service:**
```java
@Transactional
public UpdateVigenciaResponse updateVigencia(Long grupoId, String vigente, String rutUsuario) {
    // 1. Buscar grupo
    Grupo grupo = grupoRepository.findById(grupoId)
        .orElseThrow(() -> new NotFoundException("Grupo ID " + grupoId + " no existe"));
    
    // 2. Guardar valor anterior para auditoría
    String vigenciaAnterior = grupo.getVigente();
    
    // 3. Actualizar vigencia
    grupo.setVigente(vigente);
    grupo.setFechaModificacion(LocalDate.now());
    grupo.setUsuarioModificacion(rutUsuario);
    grupoRepository.save(grupo);
    
    // 4. Registrar auditoría
    String estadoNuevo = "S".equals(vigente) ? "Vigente" : "No Vigente";
    auditoriaService.registrar(
        "BR_GRUPOS",
        "UPDATE",
        grupoId,
        Map.of("vigente", vigenciaAnterior),
        Map.of("vigente", vigente),
        rutUsuario,
        "Se modificó la vigencia del Grupo " + grupo.getNombre() + " a " + estadoNuevo
    );
    
    return UpdateVigenciaResponse.builder()
        .mensaje("Vigencia actualizada")
        .grupoId(grupoId)
        .nuevaVigencia(vigente)
        .build();
}
```

### Base de Datos

**Query de actualización:**
```sql
UPDATE BR_GRUPOS 
SET GRUP_VIGENTE = :vigente,
    GRUP_FECHA_MODIFICACION = SYSDATE,
    GRUP_USUARIO_MODIFICACION = :rutUsuario
WHERE GRUP_ID = :grupoId;
```

**Impacto:**
- Afecta 1 registro en BR_GRUPOS
- NO afecta BR_USUARIO_GRUPO (asignaciones permanecen activas)
- Inserta 1 registro en BR_AUDITORIA_CAMBIOS

## Testing

### Frontend

```javascript
describe('GroupSection - Toggle Vigencia', () => {
  it('debe cambiar vigencia de S a N exitosamente', async () => {
    const mockToggle = vi.fn().mockResolvedValue({ nuevaVigencia: 'N' });
    
    render(<GroupSection grupo={{ grupoId: 123, nombre: 'Sistema OT', vigente: 'S' }} />);
    
    const switchElement = screen.getByRole('switch');
    expect(switchElement).toBeChecked();
    
    fireEvent.click(switchElement);
    
    await waitFor(() => {
      expect(mockToggle).toHaveBeenCalledWith({ grupoId: 123, vigente: 'N' });
      expect(screen.getByText(/Registro guardado correctamente/)).toBeInTheDocument();
    });
  });
  
  it('debe revertir switch si falla la actualización', async () => {
    const mockToggle = vi.fn().mockRejectedValue(new Error('500'));
    
    render(<GroupSection grupo={{ grupoId: 123, vigente: 'S' }} />);
    
    fireEvent.click(screen.getByRole('switch'));
    
    await waitFor(() => {
      expect(screen.getByText(/Error al actualizar vigencia/)).toBeInTheDocument();
      expect(screen.getByRole('switch')).toBeChecked(); // Revertido
    });
  });
});
```

### Backend

```java
@Test
void updateVigencia_conGrupoExistente_debeActualizarExitosamente() {
    Grupo grupo = Grupo.builder().id(123L).nombre("Sistema OT").vigente("S").build();
    when(grupoRepository.findById(123L)).thenReturn(Optional.of(grupo));
    
    UpdateVigenciaResponse response = grupoService.updateVigencia(123L, "N", "12345678-9");
    
    assertEquals("N", response.getNuevaVigencia());
    verify(grupoRepository, times(1)).save(argThat(g -> "N".equals(g.getVigente())));
    verify(auditoriaService, times(1)).registrar(eq("BR_GRUPOS"), eq("UPDATE"), eq(123L), any(), any(), any(), any());
}
```

## Glosario

- **Vigencia**: Estado activo/inactivo de un grupo (S=activo, N=inactivo)
- **Switch**: Componente UI de toggle on/off (Ant Design Switch)
- **Optimistic Update**: Actualización visual inmediata antes de confirmar con backend
- **Rollback**: Reversión del estado visual si backend falla
