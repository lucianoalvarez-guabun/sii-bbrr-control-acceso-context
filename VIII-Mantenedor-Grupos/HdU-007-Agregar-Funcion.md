# HdU-007: Agregar Función a Título

## Información General

**ID:** HdU-007  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 2 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** agregar una función adicional a un título existente  
**Para** expandir los permisos de un título sin tener que recrearlo  

## Mockups de Referencia

- **image-0143.png**: Modal "Agregar Función" con título read-only y dropdown función
- **image-0127.png**: Vista del título expandido mostrando funciones
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** Cada título en la lista debe mostrar un botón (+) "Agregar Función" dentro de su acordeón expandido

**AC-002:** Al hacer clic en "Agregar Función", el sistema debe abrir modal AddFuncionModal con:
- Campo "Título" (read-only, muestra nombre del título seleccionado)
- Dropdown "Seleccione Función" (obligatorio, solo funciones vigentes NO asignadas al título)
- Botón X (cancelar)
- Botón ✓ (guardar)

**AC-003:** El dropdown debe cargar SOLO funciones vigentes (FUNC_VIGENTE='S') que NO estén ya asignadas al título actual

**AC-004:** El dropdown debe permitir seleccionar UNA función a la vez (NO es multi-select)

**AC-005:** El sistema debe validar que se haya seleccionado una función del dropdown

**AC-006:** El sistema debe verificar que la función NO esté ya asignada al título (evitar duplicados en relación N:M)

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Crear registro en BR_TITULOS_FUNCIONES vinculando título con función
- Registrar auditoría con operación='INSERT'

**AC-008:** Si la creación es exitosa (201 Created), el sistema debe:
- Cerrar modal automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Agregar nueva función al final de la lista de funciones del título (dentro del acordeón)
- Actualizar contador de funciones del título en UI

**AC-009:** Si la función ya está asignada al título (409 Conflict), el sistema debe mostrar:
- "La función ya está asignada a este título."
- Mantener modal abierto
- Marcar dropdown con borde rojo

**AC-010:** Si ocurre un error de servidor (500), el sistema debe:
- Mostrar mensaje "Error al agregar función. Intente nuevamente."
- Mantener modal abierto con datos ingresados

## Flujos Principales

### Flujo 1: Agregar Función Exitosamente

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Sistema muestra grupo con título "OT Reportes" (tituloId=45, orden=1)
3. Usuario expande acordeón "OT Reportes"
4. Sistema muestra 2 funciones actuales:
   - "csdfcasc" (funcionId=15)
   - "Función 2" (funcionId=16)
5. Usuario hace clic en botón (+) "Agregar Función"
6. Sistema abre modal AddFuncionModal (image-0143)
7. Sistema muestra campo "Título" read-only con valor "OT Reportes"
8. Sistema carga dropdown "Seleccione Función" con funciones vigentes NO asignadas:
   - Consulta todas las funciones vigentes (FUNC_VIGENTE='S')
   - Filtra las ya asignadas al título (15, 16)
   - Dropdown muestra: "Función 1" (17), "Función 3" (19), "Función 4" (20)
9. Usuario selecciona "Función 3" (funcionId=19) del dropdown
10. Usuario hace clic en botón ✓
11. Sistema valida función seleccionada → OK
12. Sistema ejecuta POST `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos/45/funciones` con body:
    ```json
    {
      "funcionId": 19
    }
    ```
13. Backend verifica que función NO esté ya asignada:
    ```sql
    SELECT COUNT(*) 
    FROM BR_TITULOS_FUNCIONES 
    WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 19;
    -- Result: 0 (no existe, OK)
    ```
14. Backend ejecuta INSERT:
    ```sql
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (
      45, 19, SYSDATE, '12.345.678-9'
    );
    ```
15. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_NUEVOS, AUDI_JUSTIFICACION
    ) VALUES (
      'INSERT', 'BR_TITULOS_FUNCIONES', NULL,
      JSON_OBJECT(
        'tituloId' VALUE 45,
        'funcionId' VALUE 19,
        'tituloNombre' VALUE 'OT Reportes',
        'funcionNombre' VALUE 'Función 3'
      ),
      'Se agregó la función Función 3 al título OT Reportes del grupo Sistema OT'
    );
    ```
16. Backend retorna 201 Created:
    ```json
    {
      "mensaje": "Función agregada exitosamente"
    }
    ```
17. Sistema cierra modal
18. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
19. Sistema agrega "Función 3" al final de la lista de funciones en el acordeón
20. Sistema actualiza contador de funciones: "OT Reportes (3)" (image-0127)

### Flujo 2: Función Duplicada (409 Conflict)

1. Usuario sigue pasos 1-8 del Flujo 1
2. Usuario selecciona "csdfcasc" (funcionId=15) del dropdown (ya asignada)
3. Usuario hace clic en botón ✓
4. Sistema ejecuta POST con funcionId=15
5. Backend verifica duplicado:
   ```sql
   SELECT COUNT(*) 
   FROM BR_TITULOS_FUNCIONES 
   WHERE TIFU_TITU_ID = 45 AND TIFU_FUNC_ID = 15;
   -- Result: 1 (ya existe, CONFLICT)
   ```
6. Backend lanza ConflictException
7. Backend retorna 409 Conflict:
   ```json
   {
     "error": "Conflicto",
     "mensaje": "La función ya está asignada a este título."
   }
   ```
8. Sistema muestra mensaje de error bajo dropdown:
   - "La función ya está asignada a este título."
   - Marca dropdown con borde rojo
9. Modal permanece abierto
10. Usuario selecciona otra función (19)
11. Sistema elimina mensaje de error
12. Usuario hace clic en ✓ nuevamente
13. Sistema continúa con pasos 12-20 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-9 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema cierra modal sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Lista de funciones permanece sin cambios

## Notas Técnicas

### Frontend (React)

**Componente:** AddFuncionModal

**Estado local:**
```jsx
const AddFuncionModal = ({ visible, grupo, titulo, onClose }) => {
  const dispatch = useDispatch();
  const [funcionId, setFuncionId] = useState(null);
  const [error, setError] = useState('');
  const [funcionesDisponibles, setFuncionesDisponibles] = useState([]);
  
  useEffect(() => {
    if (visible) {
      // Cargar funciones vigentes NO asignadas al título
      dispatch(fetchFuncionesDisponibles(titulo.tituloId)).then(data => {
        setFuncionesDisponibles(data.payload);
      });
    }
  }, [visible, titulo.tituloId, dispatch]);
  
  const validate = () => {
    if (!funcionId) {
      setError('Debe seleccionar una función');
      return false;
    }
    return true;
  };
  
  const handleSubmit = async () => {
    if (!validate()) return;
    
    try {
      await dispatch(addFuncionToTitulo({ 
        grupoId: grupo.grupoId,
        tituloId: titulo.tituloId, 
        funcionId 
      })).unwrap();
      
      message.success('Registro guardado correctamente', 3);
      setFuncionId(null);
      onClose();
    } catch (error) {
      if (error.includes('ya está asignada')) {
        setError(error);
      } else {
        message.error('Error al agregar función. Intente nuevamente.', 5);
      }
    }
  };
  
  return (
    <Modal
      open={visible}
      title="Agregar Función"
      onCancel={onClose}
      footer={[
        <Button key="cancel" onClick={onClose}>X</Button>,
        <Button key="submit" type="primary" onClick={handleSubmit}>✓</Button>
      ]}
    >
      <Form layout="vertical">
        <Form.Item label="Título">
          <Input value={titulo.nombre} disabled />
        </Form.Item>
        
        <Form.Item
          label="Seleccione Función"
          validateStatus={error ? 'error' : ''}
          help={error}
        >
          <Select
            placeholder="Seleccione una función"
            value={funcionId}
            onChange={(value) => {
              setFuncionId(value);
              setError('');
            }}
          >
            {funcionesDisponibles.map(func => (
              <Select.Option key={func.funcionId} value={func.funcionId}>
                {func.nombre}
              </Select.Option>
            ))}
          </Select>
        </Form.Item>
      </Form>
    </Modal>
  );
};
```

**Redux Async Thunk:**
```javascript
export const fetchFuncionesDisponibles = createAsyncThunk(
  'grupos/fetchFuncionesDisponibles',
  async (tituloId, { rejectWithValue }) => {
    try {
      // Obtener todas las funciones vigentes
      const allFunciones = await axios.get('/acaj-ms/api/v1/funciones?vigente=S');
      
      // Obtener funciones ya asignadas al título
      const asignadas = await axios.get(`/acaj-ms/api/v1/titulos/${tituloId}/funciones`);
      
      // Filtrar funciones no asignadas
      const asignadasIds = asignadas.data.map(f => f.funcionId);
      const disponibles = allFunciones.data.filter(
        f => !asignadasIds.includes(f.funcionId)
      );
      
      return disponibles;
    } catch (error) {
      return rejectWithValue('Error al cargar funciones disponibles');
    }
  }
);

export const addFuncionToTitulo = createAsyncThunk(
  'grupos/addFuncionToTitulo',
  async ({ grupoId, tituloId, funcionId }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.post(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}/titulos/${tituloId}/funciones`,
        { funcionId }
      );
      
      return { tituloId, funcionId };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al agregar función'
      );
    }
  }
);
```

### Backend (Spring Boot)

**Endpoint:** POST `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos/{tituloId}/funciones`

**DTO Request:**
```java
public class AddFuncionToTituloRequest {
    @NotNull(message = "Función es obligatoria")
    private Long funcionId;
}
```

**Service:**
```java
@Transactional
public AddFuncionResponse addFuncionToTitulo(
    Long grupoId, Long tituloId, Long funcionId, String rutUsuario
) {
    // 1. Verificar que título existe y pertenece al grupo
    Titulo titulo = tituloRepository.findByIdAndGrupoId(tituloId, grupoId)
        .orElseThrow(() -> new NotFoundException("Título no existe o no pertenece al grupo"));
    
    // 2. Verificar que función existe y está vigente
    Funcion funcion = funcionRepository.findById(funcionId)
        .orElseThrow(() -> new NotFoundException("Función ID " + funcionId + " no existe"));
    
    if (!"S".equals(funcion.getVigente())) {
        throw new BadRequestException("Función no vigente");
    }
    
    // 3. Verificar que función NO esté ya asignada al título
    boolean exists = tituloFuncionRepository.existsByTituloIdAndFuncionId(tituloId, funcionId);
    
    if (exists) {
        throw new ConflictException("La función ya está asignada a este título.");
    }
    
    // 4. Crear relación título-función
    TituloFuncion tituloFuncion = TituloFuncion.builder()
        .tituloId(tituloId)
        .funcionId(funcionId)
        .fechaCreacion(LocalDate.now())
        .usuarioCreacion(rutUsuario)
        .build();
    
    tituloFuncionRepository.save(tituloFuncion);
    
    // 5. Auditoría
    auditoriaService.registrar(
        "BR_TITULOS_FUNCIONES",
        "INSERT",
        null,
        null,
        Map.of(
            "tituloId", tituloId,
            "funcionId", funcionId,
            "tituloNombre", titulo.getNombre(),
            "funcionNombre", funcion.getNombre()
        ),
        rutUsuario,
        "Se agregó la función " + funcion.getNombre() + 
        " al título " + titulo.getNombre() + 
        " del grupo " + grupoId
    );
    
    return AddFuncionResponse.builder()
        .mensaje("Función agregada exitosamente")
        .build();
}
```

### Base de Datos

**Query verificar duplicado:**
```sql
SELECT COUNT(*) 
FROM BR_TITULOS_FUNCIONES 
WHERE TIFU_TITU_ID = :tituloId 
  AND TIFU_FUNC_ID = :funcionId;
```

**Query INSERT:**
```sql
INSERT INTO BR_TITULOS_FUNCIONES (
  TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
) VALUES (
  :tituloId, :funcionId, SYSDATE, :rutUsuario
);
```

**Query cargar funciones disponibles (frontend):**
```sql
-- Funciones vigentes NO asignadas al título
SELECT f.FUNC_ID, f.FUNC_NOMBRE, f.FUNC_DESCRIPCION
FROM BR_FUNCIONES f
WHERE f.FUNC_VIGENTE = 'S'
  AND f.FUNC_ID NOT IN (
    SELECT TIFU_FUNC_ID 
    FROM BR_TITULOS_FUNCIONES 
    WHERE TIFU_TITU_ID = :tituloId
  )
ORDER BY f.FUNC_NOMBRE;
```

## Testing

### Frontend

```javascript
describe('AddFuncionModal', () => {
  it('debe mostrar título read-only', () => {
    render(<AddFuncionModal 
      visible={true} 
      titulo={{ tituloId: 45, nombre: 'OT Reportes' }} 
    />);
    
    const tituloInput = screen.getByLabelText(/Título/);
    expect(tituloInput).toHaveValue('OT Reportes');
    expect(tituloInput).toBeDisabled();
  });
  
  it('debe cargar solo funciones no asignadas al título', async () => {
    const funcionesDisponibles = [
      { funcionId: 17, nombre: 'Función 1' },
      { funcionId: 19, nombre: 'Función 3' }
    ];
    
    render(<AddFuncionModal 
      visible={true} 
      titulo={{ tituloId: 45, nombre: 'OT Reportes' }} 
    />);
    
    await waitFor(() => {
      expect(screen.getByText('Función 1')).toBeInTheDocument();
      expect(screen.getByText('Función 3')).toBeInTheDocument();
      expect(screen.queryByText('csdfcasc')).not.toBeInTheDocument(); // Ya asignada
    });
  });
  
  it('debe mostrar error si función ya está asignada', async () => {
    const mockAdd = vi.fn().mockRejectedValue('La función ya está asignada a este título.');
    
    render(<AddFuncionModal visible={true} titulo={{ tituloId: 45 }} />);
    
    fireEvent.change(screen.getByLabelText(/Seleccione Función/), { target: { value: 15 } });
    fireEvent.click(screen.getByRole('button', { name: /✓/ }));
    
    await waitFor(() => {
      expect(screen.getByText(/La función ya está asignada/)).toBeInTheDocument();
    });
  });
});
```

### Backend

```java
@Test
void addFuncionToTitulo_conFuncionDuplicada_debeLanzarConflictException() {
    when(tituloRepository.findByIdAndGrupoId(45L, 123L)).thenReturn(Optional.of(titulo));
    when(funcionRepository.findById(15L)).thenReturn(Optional.of(funcion));
    when(tituloFuncionRepository.existsByTituloIdAndFuncionId(45L, 15L)).thenReturn(true);
    
    assertThrows(ConflictException.class, () -> {
        grupoService.addFuncionToTitulo(123L, 45L, 15L, "12345678-9");
    });
    
    verify(tituloFuncionRepository, never()).save(any());
}

@Test
void addFuncionToTitulo_conFuncionNueva_debeCrearRelacion() {
    when(tituloRepository.findByIdAndGrupoId(45L, 123L)).thenReturn(Optional.of(titulo));
    when(funcionRepository.findById(19L)).thenReturn(Optional.of(funcionVigente));
    when(tituloFuncionRepository.existsByTituloIdAndFuncionId(45L, 19L)).thenReturn(false);
    
    AddFuncionResponse response = grupoService.addFuncionToTitulo(123L, 45L, 19L, "12345678-9");
    
    assertEquals("Función agregada exitosamente", response.getMensaje());
    verify(tituloFuncionRepository, times(1)).save(any(TituloFuncion.class));
    verify(auditoriaService, times(1)).registrar(eq("BR_TITULOS_FUNCIONES"), eq("INSERT"), any(), any(), any(), any(), any());
}
```

## Glosario

- **Read-only field**: Campo de formulario deshabilitado que muestra información contextual (no editable)
- **Dropdown filtrado**: Select que muestra solo opciones disponibles (excluye ya asignadas)
- **Relación N:M**: Relación muchos-a-muchos (un título puede tener muchas funciones, una función puede estar en muchos títulos)
- **Unicidad compuesta**: Constraint de PK compuesta (TIFU_TITU_ID, TIFU_FUNC_ID) que evita duplicados
