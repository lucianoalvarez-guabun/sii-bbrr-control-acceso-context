# HdU-005: Agregar Título a Grupo

## Información General

**ID:** HdU-005  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** agregar un nuevo título con sus funciones a un grupo existente  
**Para** expandir la estructura de permisos del grupo sin crear uno nuevo  

## Mockups de Referencia

- **image-0139.png**: Modal "Agregar Título" con input título y dropdown funciones múltiples
- **image-0127.png**: Vista del grupo con títulos en acordeones colapsables
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón (+) "Agregar Título" en la sección de títulos del grupo (bajo el último título)

**AC-002:** Al hacer clic en "Agregar Título", el sistema debe abrir modal AddTituloModal con:
- Input "Ingrese nombre del Título" (obligatorio, max 100 caracteres)
- Dropdown "Seleccione Función" (obligatorio, permite selección múltiple con checkboxes)
- Botón X (cancelar)
- Botón ✓ (guardar)

**AC-003:** El dropdown de funciones debe cargar todas las funciones vigentes de BR_FUNCIONES (FUNC_VIGENTE='S')

**AC-004:** El dropdown debe permitir seleccionar múltiples funciones a la vez (checkbox por función)

**AC-005:** El sistema debe validar que el campo "nombre del Título" no esté vacío y no exceda 100 caracteres

**AC-006:** El sistema debe validar que se haya seleccionado al menos UNA función del dropdown

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Generar nuevo ID de título con SEQ_TITULO_ID.NEXTVAL
- Calcular orden automático (MAX(TITU_ORDEN) + 1 del grupo)
- Crear registro en BR_TITULOS
- Crear N registros en BR_TITULOS_FUNCIONES (uno por cada función seleccionada)
- Registrar auditoría con operación='INSERT'

**AC-008:** Si la creación es exitosa (201 Created), el sistema debe:
- Cerrar modal automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos
- Agregar nuevo título al final de la lista de títulos del grupo (acordeón colapsado)
- Actualizar contador de títulos en UI

**AC-009:** Si el nombre del título ya existe dentro del mismo grupo, el sistema debe permitir el duplicado (NO es error)

**AC-010:** Si ocurre un error de servidor (500), el sistema debe:
- Mostrar mensaje "Error al agregar título. Intente nuevamente."
- Mantener modal abierto con datos ingresados
- Registrar error en logs

## Flujos Principales

### Flujo 1: Agregar Título con Múltiples Funciones

1. Usuario busca grupo "Sistema OT" (grupoId=123)
2. Sistema muestra grupo con 1 título existente: "OT Reportes" (orden 1)
3. Usuario hace clic en botón (+) "Agregar Título"
4. Sistema abre modal AddTituloModal vacío (image-0139)
5. Usuario ingresa "OT Opciones para jefaturas" en campo nombre del Título
6. Usuario abre dropdown "Seleccione Función"
7. Sistema muestra lista de funciones vigentes:
   - ☐ Función 1 (ID 17)
   - ☐ Función 2 (ID 18)
   - ☐ csdfcasc (ID 15)
   - ☐ Función 3 (ID 19)
8. Usuario selecciona 3 funciones:
   - ☑ Función 1 (ID 17)
   - ☑ Función 2 (ID 18)
   - ☐ csdfcasc (ID 15)
   - ☑ Función 3 (ID 19)
9. Sistema muestra contador "3 funciones seleccionadas"
10. Usuario hace clic en botón ✓
11. Sistema valida:
    - Título no vacío ✓
    - Título max 100 caracteres ✓
    - Al menos 1 función seleccionada ✓
12. Sistema ejecuta POST `/acaj-ms/api/v1/12.345.678-9/grupos/123/titulos` con body:
    ```json
    {
      "titulo": "OT Opciones para jefaturas",
      "funciones": [17, 18, 19]
    }
    ```
13. Backend calcula orden:
    ```sql
    SELECT COALESCE(MAX(TITU_ORDEN), 0) + 1 
    FROM BR_TITULOS 
    WHERE TITU_GRUP_ID = 123;
    -- Result: 2
    ```
14. Backend ejecuta INSERT título:
    ```sql
    INSERT INTO BR_TITULOS (
      TITU_ID, TITU_GRUP_ID, TITU_NOMBRE, TITU_ORDEN, 
      TITU_FECHA_CREACION, TITU_USUARIO_CREACION
    ) VALUES (
      SEQ_TITULO_ID.NEXTVAL, 123, 'OT Opciones para jefaturas', 2, 
      SYSDATE, '12.345.678-9'
    ) RETURNING TITU_ID INTO :tituloId;
    -- tituloId = 46
    ```
15. Backend ejecuta INSERT funciones (batch):
    ```sql
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 17, SYSDATE, '12.345.678-9');
    
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 18, SYSDATE, '12.345.678-9');
    
    INSERT INTO BR_TITULOS_FUNCIONES (
      TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION
    ) VALUES (46, 19, SYSDATE, '12.345.678-9');
    ```
16. Backend registra auditoría:
    ```sql
    INSERT INTO BR_AUDITORIA_CAMBIOS (
      AUDI_OPERACION, AUDI_TABLA, AUDI_REGISTRO_ID,
      AUDI_VALORES_NUEVOS, AUDI_JUSTIFICACION
    ) VALUES (
      'INSERT', 'BR_TITULOS', 46,
      JSON_OBJECT(
        'nombre' VALUE 'OT Opciones para jefaturas',
        'grupoId' VALUE 123,
        'funciones' VALUE JSON_ARRAY(17, 18, 19)
      ),
      'Se agregó el título OT Opciones para jefaturas al grupo Sistema OT con 3 funciones'
    );
    ```
17. Backend retorna 201 Created:
    ```json
    {
      "tituloId": 46,
      "orden": 2,
      "mensaje": "Título agregado exitosamente"
    }
    ```
18. Sistema cierra modal
19. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
20. Sistema agrega nuevo acordeón "OT Opciones para jefaturas (3)" al final de la lista
21. Usuario expande acordeón y visualiza 3 funciones: Función 1, Función 2, Función 3 (image-0127)

### Flujo 2: Error - No Selecciona Funciones

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario ingresa "Nuevo Título" en campo nombre
3. Usuario NO selecciona ninguna función del dropdown
4. Usuario hace clic en botón ✓
5. Sistema valida → encuentra error: 0 funciones seleccionadas
6. Sistema muestra mensaje de error bajo dropdown:
   - "Debe seleccionar al menos una función"
   - Marca dropdown con borde rojo
7. Modal permanece abierto
8. Usuario selecciona 1 función
9. Sistema elimina mensaje de error
10. Usuario hace clic en ✓ nuevamente
11. Sistema continúa con pasos 12-21 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-8 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema cierra modal sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Lista de títulos permanece sin cambios

## Notas Técnicas

### Frontend (React)

**Componente:** AddTituloModal

**Estado local:**
```jsx
const AddTituloModal = ({ visible, grupoId, onClose }) => {
  const dispatch = useDispatch();
  const [form, setForm] = useState({
    titulo: '',
    funciones: []
  });
  const [errors, setErrors] = useState({});
  const [funcionesVigentes, setFuncionesVigentes] = useState([]);
  
  useEffect(() => {
    if (visible) {
      // Cargar funciones vigentes
      dispatch(fetchFuncionesVigentes()).then(data => {
        setFuncionesVigentes(data.payload);
      });
    }
  }, [visible, dispatch]);
  
  const validate = () => {
    const newErrors = {};
    
    if (!form.titulo || form.titulo.trim() === '') {
      newErrors.titulo = 'Nombre del título es obligatorio';
    }
    if (form.titulo.length > 100) {
      newErrors.titulo = 'Nombre del título no puede exceder 100 caracteres';
    }
    if (form.funciones.length === 0) {
      newErrors.funciones = 'Debe seleccionar al menos una función';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = async () => {
    if (!validate()) return;
    
    try {
      await dispatch(addTitulo({ 
        grupoId, 
        titulo: form.titulo, 
        funciones: form.funciones 
      })).unwrap();
      
      message.success('Registro guardado correctamente', 3);
      setForm({ titulo: '', funciones: [] });
      onClose();
    } catch (error) {
      message.error(error || 'Error al agregar título. Intente nuevamente.', 5);
    }
  };
  
  return (
    <Modal
      open={visible}
      title="Agregar Título"
      onCancel={onClose}
      footer={[
        <Button key="cancel" onClick={onClose}>X</Button>,
        <Button key="submit" type="primary" onClick={handleSubmit}>✓</Button>
      ]}
    >
      <Form layout="vertical">
        <Form.Item
          label="Ingrese nombre del Título"
          validateStatus={errors.titulo ? 'error' : ''}
          help={errors.titulo}
        >
          <Input
            maxLength={100}
            value={form.titulo}
            onChange={e => setForm({ ...form, titulo: e.target.value })}
          />
        </Form.Item>
        
        <Form.Item
          label="Seleccione Función"
          validateStatus={errors.funciones ? 'error' : ''}
          help={errors.funciones}
        >
          <Select
            mode="multiple"
            placeholder="Seleccione una o más funciones"
            value={form.funciones}
            onChange={funciones => setForm({ ...form, funciones })}
          >
            {funcionesVigentes.map(func => (
              <Select.Option key={func.funcionId} value={func.funcionId}>
                {func.nombre}
              </Select.Option>
            ))}
          </Select>
          
          {form.funciones.length > 0 && (
            <div style={{ marginTop: 8, color: '#1890ff' }}>
              {form.funciones.length} funciones seleccionadas
            </div>
          )}
        </Form.Item>
      </Form>
    </Modal>
  );
};
```

**Redux Async Thunk:**
```javascript
export const addTitulo = createAsyncThunk(
  'grupos/addTitulo',
  async ({ grupoId, titulo, funciones }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.post(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/${grupoId}/titulos`,
        { titulo, funciones }
      );
      
      return { grupoId, tituloId: response.data.tituloId, orden: response.data.orden };
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al agregar título'
      );
    }
  }
);
```

### Backend (Spring Boot)

**Endpoint:** POST `/acaj-ms/api/v1/{rut}-{dv}/grupos/{grupoId}/titulos`

**DTO Request:**
```java
public class AddTituloRequest {
    @NotBlank(message = "Nombre del título es obligatorio")
    @Size(max = 100, message = "Nombre del título no puede exceder 100 caracteres")
    private String titulo;
    
    @NotEmpty(message = "Debe seleccionar al menos una función")
    private List<Long> funciones;
}
```

**Service:**
```java
@Transactional
public AddTituloResponse addTitulo(Long grupoId, AddTituloRequest request, String rutUsuario) {
    // 1. Verificar que grupo existe
    Grupo grupo = grupoRepository.findById(grupoId)
        .orElseThrow(() -> new NotFoundException("Grupo ID " + grupoId + " no existe"));
    
    // 2. Verificar que todas las funciones existen y están vigentes
    for (Long funcionId : request.getFunciones()) {
        Funcion funcion = funcionRepository.findById(funcionId)
            .orElseThrow(() -> new NotFoundException("Función ID " + funcionId + " no existe"));
        
        if (!"S".equals(funcion.getVigente())) {
            throw new BadRequestException("Función ID " + funcionId + " no vigente");
        }
    }
    
    // 3. Calcular orden (MAX + 1)
    Integer maxOrden = tituloRepository.findMaxOrdenByGrupoId(grupoId);
    int nuevoOrden = (maxOrden == null ? 0 : maxOrden) + 1;
    
    // 4. Crear título
    Titulo titulo = Titulo.builder()
        .id(tituloSequence.nextVal())
        .grupoId(grupoId)
        .nombre(request.getTitulo())
        .orden(nuevoOrden)
        .fechaCreacion(LocalDate.now())
        .usuarioCreacion(rutUsuario)
        .build();
    tituloRepository.save(titulo);
    
    // 5. Crear relaciones título-funciones (batch)
    List<TituloFuncion> tituloFunciones = request.getFunciones().stream()
        .map(funcionId -> TituloFuncion.builder()
            .tituloId(titulo.getId())
            .funcionId(funcionId)
            .fechaCreacion(LocalDate.now())
            .usuarioCreacion(rutUsuario)
            .build())
        .collect(Collectors.toList());
    
    tituloFuncionRepository.saveAll(tituloFunciones);
    
    // 6. Auditoría
    auditoriaService.registrar(
        "BR_TITULOS",
        "INSERT",
        titulo.getId(),
        null,
        Map.of(
            "nombre", titulo.getNombre(),
            "grupoId", grupoId,
            "funciones", request.getFunciones()
        ),
        rutUsuario,
        "Se agregó el título " + titulo.getNombre() + 
        " al grupo " + grupo.getNombre() + 
        " con " + request.getFunciones().size() + " funciones"
    );
    
    return AddTituloResponse.builder()
        .tituloId(titulo.getId())
        .orden(nuevoOrden)
        .mensaje("Título agregado exitosamente")
        .build();
}
```

### Base de Datos

**Query calcular orden:**
```sql
SELECT COALESCE(MAX(TITU_ORDEN), 0) + 1
FROM BR_TITULOS
WHERE TITU_GRUP_ID = :grupoId;
```

**INSERT título:**
```sql
INSERT INTO BR_TITULOS (
  TITU_ID, TITU_GRUP_ID, TITU_NOMBRE, TITU_ORDEN, 
  TITU_FECHA_CREACION, TITU_USUARIO_CREACION
) VALUES (
  SEQ_TITULO_ID.NEXTVAL, :grupoId, :titulo, :orden, 
  SYSDATE, :rutUsuario
) RETURNING TITU_ID INTO :tituloId;
```

**INSERT funciones (batch):**
```sql
INSERT ALL
  INTO BR_TITULOS_FUNCIONES (TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION)
    VALUES (:tituloId, :funcionId1, SYSDATE, :rutUsuario)
  INTO BR_TITULOS_FUNCIONES (TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION)
    VALUES (:tituloId, :funcionId2, SYSDATE, :rutUsuario)
  INTO BR_TITULOS_FUNCIONES (TIFU_TITU_ID, TIFU_FUNC_ID, TIFU_FECHA_CREACION, TIFU_USUARIO_CREACION)
    VALUES (:tituloId, :funcionId3, SYSDATE, :rutUsuario)
SELECT * FROM DUAL;
```

## Testing

### Frontend

```javascript
describe('AddTituloModal', () => {
  it('debe validar que al menos una función esté seleccionada', () => {
    render(<AddTituloModal visible={true} grupoId={123} />);
    
    fireEvent.change(screen.getByLabelText(/nombre del Título/), {
      target: { value: 'Nuevo Título' }
    });
    
    fireEvent.click(screen.getByRole('button', { name: /✓/ }));
    
    expect(screen.getByText(/Debe seleccionar al menos una función/)).toBeInTheDocument();
  });
  
  it('debe permitir selección múltiple de funciones', async () => {
    render(<AddTituloModal visible={true} grupoId={123} />);
    
    const select = screen.getByLabelText(/Seleccione Función/);
    
    fireEvent.change(select, { target: { value: [17, 18, 19] } });
    
    expect(screen.getByText(/3 funciones seleccionadas/)).toBeInTheDocument();
  });
});
```

### Backend

```java
@Test
void addTitulo_conMultiplesFunciones_debeCrearTituloYRelaciones() {
    AddTituloRequest request = new AddTituloRequest("OT Opciones", List.of(17L, 18L, 19L));
    when(grupoRepository.findById(123L)).thenReturn(Optional.of(grupo));
    when(funcionRepository.findById(anyLong())).thenReturn(Optional.of(funcionVigente));
    when(tituloRepository.findMaxOrdenByGrupoId(123L)).thenReturn(1);
    when(tituloSequence.nextVal()).thenReturn(46L);
    
    AddTituloResponse response = grupoService.addTitulo(123L, request, "12345678-9");
    
    assertEquals(46L, response.getTituloId());
    assertEquals(2, response.getOrden());
    verify(tituloRepository, times(1)).save(any(Titulo.class));
    verify(tituloFuncionRepository, times(1)).saveAll(argThat(list -> list.size() == 3));
}
```

## Glosario

- **Título**: Sección colapsable dentro de un grupo que agrupa funciones relacionadas
- **Orden automático**: Cálculo de posición secuencial (MAX + 1) para nuevos títulos
- **Selección múltiple**: Dropdown que permite elegir varias opciones con checkboxes
- **Batch INSERT**: Inserción de múltiples registros en una sola transacción para optimizar performance
