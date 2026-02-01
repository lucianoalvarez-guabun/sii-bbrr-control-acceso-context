# HdU-001: Crear Grupo

## Información General

**ID:** HdU-001  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 5 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** crear un nuevo grupo de permisos con su primer título y función  
**Para** estructurar los accesos de los usuarios a funcionalidades del sistema  

## Mockups de Referencia

- **Imagen 4 (inline)**: Formulario inline "Crear Grupo" expandido en pantalla principal
- **image-0027.png**: Alerta de éxito "Registro guardado correctamente"
- **image-0127.png**: Pantalla principal mostrando grupo recién creado

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar un botón "Agregar Grupo" en la cabecera de la pantalla principal (icono +)

**AC-002:** Al hacer clic en "Agregar Grupo", se debe desplegar un formulario inline (NO modal) en la pantalla principal con los siguientes campos:
- Input "Ingrese nombre del Grupo" (obligatorio, max 100 caracteres)
- Input "Ingrese nombre del Título" (obligatorio, max 100 caracteres)
- Dropdown "Seleccione Función" (obligatorio, carga funciones vigentes de BR_FUNCIONES)
- Botón X (cancelar, colapsa formulario sin guardar)
- Botón ✓ (guardar, ejecuta validaciones y creación)

**AC-003:** El sistema debe validar que el campo "nombre del Grupo" no esté vacío y no contenga más de 100 caracteres

**AC-004:** El sistema debe validar que el campo "nombre del Título" no esté vacío y no contenga más de 100 caracteres

**AC-005:** El sistema debe validar que se haya seleccionado al menos una función del dropdown

**AC-006:** El sistema debe verificar que el nombre del grupo NO exista previamente (case-insensitive: "Sistema OT" == "sistema ot")

**AC-007:** Si las validaciones son exitosas, el sistema debe:
- Generar un nuevo ID de grupo con SEQ_GRUPO_ID.NEXTVAL
- Crear registro en BR_GRUPOS con vigencia='S' y fecha_creacion=SYSDATE
- Generar un nuevo ID de título con SEQ_TITULO_ID.NEXTVAL
- Crear registro en BR_TITULOS con orden=1 vinculado al grupo
- Crear registro en BR_TITULOS_FUNCIONES vinculando título con función seleccionada
- Registrar auditoría en BR_AUDITORIA_CAMBIOS con operación='INSERT'

**AC-008:** Si la creación es exitosa, el sistema debe:
- Colapsar el formulario inline automáticamente
- Mostrar alerta verde "Registro guardado correctamente" por 3 segundos (image-0027)
- Mostrar el nuevo grupo en el área de resultados (como si se hubiera buscado)
- Limpiar los campos del formulario para próxima creación

**AC-009:** Si el nombre del grupo ya existe, el sistema debe mostrar error:
- "El nombre del grupo ya existe. Ingrese un nombre diferente."
- Mantener el formulario expandido con los datos ingresados
- Marcar el campo "nombre del Grupo" en rojo

**AC-010:** Si ocurre un error de servidor (500), el sistema debe mostrar:
- "Error al guardar el grupo. Intente nuevamente."
- Mantener el formulario expandido con los datos ingresados
- Registrar error en logs del backend con stack trace completo

## Flujos Principales

### Flujo 1: Creación Exitosa

1. Usuario hace clic en botón "Agregar Grupo" (icono + en SearchBar)
2. Sistema expande formulario CreateGroupForm inline debajo del SearchBar
3. Usuario ingresa "Sistema OT" en campo nombre del Grupo
4. Usuario ingresa "Reportes" en campo nombre del Título
5. Usuario selecciona "csdfcasc" (ID 15) del dropdown Función
6. Usuario hace clic en botón ✓
7. Sistema valida campos (no vacíos, max 100 caracteres, función seleccionada)
8. Sistema verifica que "Sistema OT" no existe en BR_GRUPOS
9. Sistema ejecuta transacción:
   - INSERT en BR_GRUPOS → grupoId=123
   - INSERT en BR_TITULOS → tituloId=45, orden=1
   - INSERT en BR_TITULOS_FUNCIONES → relación (45, 15)
   - INSERT en BR_AUDITORIA_CAMBIOS
10. Sistema colapsa formulario inline
11. Sistema muestra alerta verde "Registro guardado correctamente" (image-0027)
12. Sistema muestra el grupo recién creado en el área de resultados (como búsqueda automática)
13. Usuario visualiza grupo "Sistema OT" expandido con título "Reportes" (image-0127)

### Flujo 2: Nombre Duplicado

1. Usuario sigue pasos 1-6 del Flujo 1 pero ingresa "Sistema OT" (ya existe)
2. Sistema valida campos → OK
3. Sistema verifica existencia en BR_GRUPOS → encuentra match (case-insensitive)
4. Sistema retorna error 409 Conflict
5. Sistema muestra mensaje: "El nombre del grupo ya existe. Ingrese un nombre diferente."
6. Sistema marca campo "nombre del Grupo" en rojo con borde
7. Formulario permanece expandido con datos ingresados
8. Usuario corrige nombre a "Sistema OT v2"
9. Usuario hace clic en botón ✓
10. Sistema continúa con pasos 7-13 del Flujo 1

### Flujo 3: Cancelación

1. Usuario sigue pasos 1-5 del Flujo 1
2. Usuario hace clic en botón X (cancelar)
3. Sistema colapsa formulario inline sin ejecutar validaciones
4. Sistema NO guarda ningún dato
5. Sistema limpia campos del formulario
6. Pantalla principal permanece sin cambios (área de resultados intacta)

## Notas Técnicas

### Frontend (React)

**Componente:** CreateGroupForm (inline, NO modal)  
**Redux Action:** createGrupo (async thunk)  
**Validación:** maxLength 100 para nombre/título, required para función  

**Estado local del formulario:**
```javascript
const [visible, setVisible] = useState(false); // Controla expansión/colapso
const [form, setForm] = useState({
  nombre: '',
  titulo: '',
  funcionId: null
});

const [errors, setErrors] = useState({
  nombre: false,
  titulo: false,
  funcionId: false
});
```

**Validación frontend:**
```javascript
const validate = () => {
  const newErrors = {
    nombre: !form.nombre || form.nombre.length > 100,
    titulo: !form.titulo || form.titulo.length > 100,
    funcionId: !form.funcionId
  };
  setErrors(newErrors);
  return !Object.values(newErrors).some(Boolean);
};
```

### Backend (Spring Boot)

**Endpoint:** POST `/acaj-ms/api/v1/{rut}-{dv}/grupos/crear`

**DTO Request:**
```java
public class CreateGrupoRequest {
    @NotBlank(message = "Nombre del grupo es obligatorio")
    @Size(max = 100, message = "Nombre del grupo no puede exceder 100 caracteres")
    private String nombre;
    
    @NotBlank(message = "Nombre del título es obligatorio")
    @Size(max = 100, message = "Nombre del título no puede exceder 100 caracteres")
    private String titulo;
    
    @NotNull(message = "Función es obligatoria")
    private Long funcionId;
}
```

**Validación backend:**
```java
// 1. Verificar nombre duplicado
boolean exists = grupoRepository.existsByNombreIgnoreCase(request.getNombre());
if (exists) {
    throw new ConflictException("El nombre del grupo ya existe. Ingrese un nombre diferente.");
}

// 2. Verificar función vigente
Funcion funcion = funcionRepository.findById(request.getFuncionId())
    .orElseThrow(() -> new NotFoundException("Función no existe"));
    
if (!"S".equals(funcion.getVigente())) {
    throw new BadRequestException("Función no vigente");
}

// 3. Verificar perfil administrador
if (!hasRole("ADMIN_NACIONAL")) {
    throw new ForbiddenException("Sin permisos para crear grupos");
}
```

**Lógica de transacción:**
```java
@Transactional
public CreateGrupoResponse crear(String rut, CreateGrupoRequest request) {
    // 1. Crear grupo
    Grupo grupo = Grupo.builder()
        .id(grupoSequence.nextVal())
        .nombre(request.getNombre())
        .vigente("S")
        .fechaCreacion(LocalDate.now())
        .usuarioCreacion(rut)
        .build();
    grupoRepository.save(grupo);
    
    // 2. Crear título
    Titulo titulo = Titulo.builder()
        .id(tituloSequence.nextVal())
        .grupoId(grupo.getId())
        .nombre(request.getTitulo())
        .orden(1)
        .fechaCreacion(LocalDate.now())
        .usuarioCreacion(rut)
        .build();
    tituloRepository.save(titulo);
    
    // 3. Crear relación título-función
    TituloFuncion tituloFuncion = TituloFuncion.builder()
        .tituloId(titulo.getId())
        .funcionId(request.getFuncionId())
        .fechaCreacion(LocalDate.now())
        .usuarioCreacion(rut)
        .build();
    tituloFuncionRepository.save(tituloFuncion);
    
    // 4. Auditoría
    auditoriaService.registrar("BR_GRUPOS", "INSERT", grupo.getId(), 
        null, grupo.toJson(), rut, "Se creó el Grupo " + grupo.getNombre());
    
    return CreateGrupoResponse.builder()
        .grupoId(grupo.getId())
        .codigo(grupo.getId())
        .nombre(grupo.getNombre())
        .vigente("S")
        .mensaje("Grupo creado exitosamente")
        .build();
}
```

### Base de Datos

**Tablas afectadas:**
- BR_GRUPOS (INSERT 1 registro)
- BR_TITULOS (INSERT 1 registro)
- BR_TITULOS_FUNCIONES (INSERT 1 registro)
- BR_AUDITORIA_CAMBIOS (INSERT 1 registro)

**Query de verificación de duplicados:**
```sql
SELECT COUNT(*) 
FROM BR_GRUPOS 
WHERE UPPER(GRUP_NOMBRE) = UPPER(:nombre);
```

**Secuencias utilizadas:**
- SEQ_GRUPO_ID → genera GRUP_ID
- SEQ_TITULO_ID → genera TITU_ID

## Dependencias

**Funcionales:**
- Módulo VII (BR_FUNCIONES debe existir con funciones vigentes)
- Módulo V (BR_RELACIONADOS para usuario creador)
- Sistema de autenticación (JWT con RUT en claims)

**Técnicas:**
- Redux Toolkit (state management)
- Ant Design (Modal, Input, Select, Alert)
- Axios (HTTP client)
- Spring Boot Validation
- Oracle 19c (sequences, transactions)

## Testing

### Frontend (Vitest + React Testing Library)

```javascript
describe('CreateGroupForm', () => {
  it('debe mostrar errores si campos obligatorios están vacíos', () => {
    render(<CreateGroupForm visible={true} />);
    
    fireEvent.click(screen.getByRole('button', { name: /✓/ }));
    
    expect(screen.getByText(/Nombre del grupo es obligatorio/)).toBeInTheDocument();
    expect(screen.getByText(/Nombre del título es obligatorio/)).toBeInTheDocument();
    expect(screen.getByText(/Función es obligatoria/)).toBeInTheDocument();
  });
  
  it('debe crear grupo exitosamente con datos válidos', async () => {
    const mockCreate = vi.fn().mockResolvedValue({ grupoId: 123 });
    
    render(<CreateGroupForm visible={true} onCreate={mockCreate} />);
    
    fireEvent.change(screen.getByLabelText(/nombre del Grupo/), { 
      target: { value: 'Sistema OT' } 
    });
    fireEvent.change(screen.getByLabelText(/nombre del Título/), { 
      target: { value: 'Reportes' } 
    });
    fireEvent.change(screen.getByLabelText(/Seleccione Función/), { 
      target: { value: 15 } 
    });
    
    fireEvent.click(screen.getByRole('button', { name: /✓/ }));
    
    await waitFor(() => {
      expect(mockCreate).toHaveBeenCalledWith({
        nombre: 'Sistema OT',
        titulo: 'Reportes',
        funcionId: 15
      });
    });
  });
});
```

### Backend (JUnit 5 + Mockito)

```java
@Test
void crear_conNombreDuplicado_debeLanzarConflictException() {
    // Arrange
    CreateGrupoRequest request = new CreateGrupoRequest("Sistema OT", "Reportes", 15L);
    when(grupoRepository.existsByNombreIgnoreCase("Sistema OT")).thenReturn(true);
    
    // Act & Assert
    assertThrows(ConflictException.class, () -> {
        grupoService.crear("12345678-9", request);
    });
    
    verify(grupoRepository, never()).save(any());
}

@Test
void crear_conDatosValidos_debeCrearGrupoTituloYFuncion() {
    // Arrange
    CreateGrupoRequest request = new CreateGrupoRequest("Sistema OT", "Reportes", 15L);
    when(grupoRepository.existsByNombreIgnoreCase(anyString())).thenReturn(false);
    when(funcionRepository.findById(15L)).thenReturn(Optional.of(funcionVigente));
    when(grupoSequence.nextVal()).thenReturn(123L);
    when(tituloSequence.nextVal()).thenReturn(45L);
    
    // Act
    CreateGrupoResponse response = grupoService.crear("12345678-9", request);
    
    // Assert
    assertEquals(123L, response.getGrupoId());
    verify(grupoRepository, times(1)).save(any(Grupo.class));
    verify(tituloRepository, times(1)).save(any(Titulo.class));
    verify(tituloFuncionRepository, times(1)).save(any(TituloFuncion.class));
    verify(auditoriaService, times(1)).registrar(eq("BR_GRUPOS"), eq("INSERT"), eq(123L), any(), any(), any(), any());
}
```

## Glosario

- **Grupo**: Conjunto de permisos (funciones) agrupados por contexto funcional (ej: "Sistema OT", "Gestión de Deudas")
- **Título**: Sección colapsable dentro de un grupo que agrupa funciones relacionadas (ej: "Reportes", "OT Opciones para jefaturas")
- **Función**: Permiso atómico que habilita una acción específica en el sistema (ej: "Consulta reportes OT", "Aprobar solicitud")
- **Vigente**: Estado activo del grupo (S=Sí, N=No). Grupos no vigentes no se pueden asignar a usuarios nuevos
- **Orden**: Posición de visualización de títulos dentro de un grupo (1=primero, 2=segundo, etc.)
