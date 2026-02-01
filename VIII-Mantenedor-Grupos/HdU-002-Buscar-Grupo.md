# HdU-002: Buscar Grupo

## Información General

**ID:** HdU-002  
**Módulo:** VIII - Mantenedor de Grupos  
**Prioridad:** Alta  
**Estimación:** 3 puntos  

## Historia de Usuario

**Como** Administrador Nacional del SII  
**Quiero** buscar un grupo específico por su ID y estado de vigencia  
**Para** visualizar su estructura completa (títulos y funciones) y gestionar su información  

## Mockups de Referencia

- **image-0135.png**: SearchBar con dropdown de grupos, toggle "Vigente/No Vigente" y lupa
- **image-0127.png**: Resultado de búsqueda mostrando grupo "Sistema OT" expandido con títulos y funciones

## Criterios de Aceptación

**AC-001:** El sistema debe mostrar en la cabecera un SearchBar con los siguientes elementos:
- Dropdown "Grupo" (obligatorio, lista todos los grupos vigentes por defecto)
- Toggle "Vigente/No Vigente" (switch on/off, por defecto "Vigente"=ON)
- Botón lupa (ejecuta búsqueda)
- Botón "Agregar Grupo" (icono +)

**AC-002:** El dropdown "Grupo" debe cargar dinámicamente la lista de grupos desde BR_GRUPOS filtrando por el estado del toggle vigente

**AC-003:** Si el toggle está en "Vigente" (ON), el dropdown debe mostrar solo grupos con GRUP_VIGENTE='S'

**AC-004:** Si el toggle está en "No Vigente" (OFF), el dropdown debe mostrar solo grupos con GRUP_VIGENTE='N'

**AC-005:** Al cambiar el estado del toggle, el sistema debe:
- Vaciar la selección actual del dropdown
- Recargar automáticamente la lista de grupos según el nuevo filtro
- Mantener el botón lupa deshabilitado hasta nueva selección

**AC-006:** El botón lupa debe estar deshabilitado (gris) mientras no se haya seleccionado un grupo del dropdown

**AC-007:** Al hacer clic en el botón lupa con un grupo seleccionado, el sistema debe ejecutar GET /buscar y mostrar:
- Nombre del grupo (título principal)
- Cantidad de usuarios (clickeable, abre modal de usuarios)
- Toggle vigente/no vigente (switch habilitado para modificar)
- Botón eliminar (icono papelera, solo si grupo sin usuarios activos)
- Lista de títulos ordenados por TITU_ORDEN (acordeones colapsables)
- Dentro de cada título: lista de funciones asociadas con botón eliminar por función

**AC-008:** Si la búsqueda retorna un grupo exitosamente (200 OK), el sistema debe renderizar el componente GroupSection con los datos recibidos

**AC-009:** Si el grupo no existe (404 Not Found), el sistema debe mostrar mensaje:
- "Grupo no encontrado. Verifique el ID seleccionado."
- Limpiar el área de resultados

**AC-010:** Si ocurre un error de servidor (500), el sistema debe mostrar:
- "Error al cargar el grupo. Intente nuevamente."
- Registrar error en logs del frontend (console.error con stack trace)

## Flujos Principales

### Flujo 1: Búsqueda Exitosa de Grupo Vigente

1. Usuario accede a pantalla principal del módulo
2. Sistema carga SearchBar con toggle "Vigente" activado (ON)
3. Sistema carga dropdown "Grupo" con grupos vigentes (GRUP_VIGENTE='S')
4. Usuario abre dropdown y ve lista: "Sistema OT (123)", "Gestión de Deudas (124)"
5. Usuario selecciona "Sistema OT (123)"
6. Sistema habilita botón lupa (cambia de gris a verde)
7. Usuario hace clic en botón lupa
8. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=123`
9. Backend retorna 200 OK con payload:
   ```json
   {
     "grupoId": 123,
     "nombre": "Sistema OT",
     "cantidadUsuarios": 100,
     "vigente": "S",
     "titulos": [
       {
         "tituloId": 45,
         "nombre": "OT Reportes",
         "orden": 1,
         "funciones": [
           { "funcionId": 15, "nombre": "csdfcasc", "descripcion": "Consulta reportes OT" },
           { "funcionId": 16, "nombre": "Función 2", "descripcion": null }
         ]
       },
       {
         "tituloId": 46,
         "nombre": "OT Opciones para jefaturas",
         "orden": 2,
         "funciones": [
           { "funcionId": 17, "nombre": "Función 1", "descripcion": null }
         ]
       }
     ]
   }
   ```
10. Sistema renderiza GroupSection mostrando:
    - Título: "Sistema OT"
    - Subtítulo: "100 usuarios" (clickeable, con icono persona)
    - Toggle vigente activado (verde, switch ON)
    - Botón papelera (si cantidadUsuarios=0, deshabilitado si >0)
11. Sistema renderiza 2 acordeones TitulosAccordion:
    - "OT Reportes" (orden 1) con 2 funciones
    - "OT Opciones para jefaturas" (orden 2) con 1 función
12. Usuario expande acordeón "OT Reportes" (click en título)
13. Sistema muestra lista de funciones:
    - "csdfcasc - Consulta reportes OT" con icono X (eliminar)
    - "Función 2" con icono X (eliminar)
14. Usuario visualiza estructura completa del grupo (image-0127)

### Flujo 2: Cambio de Filtro Vigente a No Vigente

1. Usuario sigue pasos 1-3 del Flujo 1
2. Usuario hace clic en toggle "Vigente" (cambia de ON a OFF)
3. Sistema detecta cambio de estado
4. Sistema vacía selección actual del dropdown "Grupo"
5. Sistema ejecuta nueva consulta con filtro GRUP_VIGENTE='N'
6. Sistema recarga dropdown con grupos no vigentes: "Grupo Antiguo (200)", "Sistema Legacy (201)"
7. Sistema deshabilita botón lupa (gris)
8. Usuario selecciona "Grupo Antiguo (200)"
9. Sistema habilita botón lupa
10. Usuario hace clic en lupa
11. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=N&grupoId=200`
12. Sistema renderiza grupo no vigente con toggle desactivado (gris, switch OFF)

### Flujo 3: Grupo No Encontrado (404)

1. Usuario sigue pasos 1-7 del Flujo 1
2. Sistema ejecuta GET `/acaj-ms/api/v1/12.345.678-9/grupos/buscar?vigente=S&grupoId=999`
3. Backend retorna 404 Not Found:
   ```json
   { "error": "No encontrado", "mensaje": "Grupo ID 999 no existe" }
   ```
4. Sistema muestra mensaje de error en área de resultados:
   - Icono advertencia (triángulo amarillo)
   - Texto: "Grupo no encontrado. Verifique el ID seleccionado."
5. Sistema limpia cualquier resultado previo
6. Sistema mantiene SearchBar con selección actual visible

## Notas Técnicas

### Frontend (React)

**Componentes involucrados:**
- SearchBar (contenedor de filtros)
- GroupsMainPage (orquesta búsqueda y resultados)
- GroupSection (resultado individual del grupo)
- TitulosAccordion (lista de títulos colapsables)

**Estado Redux:**
```javascript
const gruposSlice = createSlice({
  name: 'grupos',
  initialState: {
    listaGrupos: [],      // Para dropdown
    grupoActual: null,    // Resultado de búsqueda
    filtroVigente: 'S',   // Estado del toggle
    loading: false,
    error: null
  },
  reducers: {
    setFiltroVigente(state, action) {
      state.filtroVigente = action.payload;
      state.grupoActual = null; // Limpiar resultado al cambiar filtro
    }
  },
  extraReducers: (builder) => {
    builder
      .addCase(searchGrupo.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(searchGrupo.fulfilled, (state, action) => {
        state.loading = false;
        state.grupoActual = action.payload;
      })
      .addCase(searchGrupo.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
        state.grupoActual = null;
      });
  }
});
```

**Async Thunk:**
```javascript
export const searchGrupo = createAsyncThunk(
  'grupos/search',
  async ({ grupoId, vigente }, { getState, rejectWithValue }) => {
    try {
      const state = getState();
      const { rut, dv } = state.auth.user;
      
      const response = await axios.get(
        `/acaj-ms/api/v1/${rut}-${dv}/grupos/buscar`,
        { params: { vigente, grupoId } }
      );
      
      return response.data;
    } catch (error) {
      return rejectWithValue(
        error.response?.data?.mensaje || 'Error al cargar el grupo'
      );
    }
  }
);
```

**Componente SearchBar:**
```jsx
const SearchBar = () => {
  const dispatch = useDispatch();
  const { listaGrupos, filtroVigente } = useSelector(state => state.grupos);
  const [selectedGrupo, setSelectedGrupo] = useState(null);
  
  useEffect(() => {
    // Recargar lista al cambiar filtro vigente
    dispatch(fetchGruposDropdown(filtroVigente));
    setSelectedGrupo(null);
  }, [filtroVigente, dispatch]);
  
  const handleSearch = () => {
    if (selectedGrupo) {
      dispatch(searchGrupo({ 
        grupoId: selectedGrupo, 
        vigente: filtroVigente 
      }));
    }
  };
  
  return (
    <div className="search-bar">
      <Select
        placeholder="Grupo"
        value={selectedGrupo}
        onChange={setSelectedGrupo}
        options={listaGrupos.map(g => ({ 
          value: g.grupoId, 
          label: `${g.nombre} (${g.grupoId})` 
        }))}
      />
      
      <Switch
        checkedChildren="Vigente"
        unCheckedChildren="No Vigente"
        checked={filtroVigente === 'S'}
        onChange={(checked) => 
          dispatch(setFiltroVigente(checked ? 'S' : 'N'))
        }
      />
      
      <Button
        icon={<SearchOutlined />}
        disabled={!selectedGrupo}
        onClick={handleSearch}
      />
      
      <Button icon={<PlusOutlined />} onClick={onOpenCreateModal} />
    </div>
  );
};
```

### Backend (Spring Boot)

**Endpoint:** GET `/acaj-ms/api/v1/{rut}-{dv}/grupos/buscar`

**Controller:**
```java
@GetMapping("/{rut}-{dv}/grupos/buscar")
public ResponseEntity<GrupoDetalleResponse> buscar(
    @PathVariable String rut,
    @PathVariable String dv,
    @RequestParam(required = true) String vigente,
    @RequestParam(required = true) Long grupoId
) {
    validateRutFromToken(rut, dv);
    
    GrupoDetalleResponse grupo = grupoService.buscar(grupoId, vigente);
    
    return ResponseEntity.ok(grupo);
}
```

**Service:**
```java
public GrupoDetalleResponse buscar(Long grupoId, String vigente) {
    // Validar parámetro vigente
    if (!"S".equals(vigente) && !"N".equals(vigente)) {
        throw new BadRequestException("Parámetro vigente debe ser 'S' o 'N'");
    }
    
    // Buscar grupo
    Grupo grupo = grupoRepository.findByIdAndVigente(grupoId, vigente)
        .orElseThrow(() -> new NotFoundException("Grupo ID " + grupoId + " no existe"));
    
    // Cargar títulos y funciones
    List<Titulo> titulos = tituloRepository.findByGrupoIdOrderByOrden(grupoId);
    
    List<TituloDto> titulosDto = titulos.stream()
        .map(titulo -> {
            List<Funcion> funciones = tituloFuncionRepository
                .findFuncionesByTituloId(titulo.getId());
            
            return TituloDto.builder()
                .tituloId(titulo.getId())
                .nombre(titulo.getNombre())
                .orden(titulo.getOrden())
                .funciones(funciones.stream()
                    .map(f -> FuncionDto.builder()
                        .funcionId(f.getId())
                        .nombre(f.getNombre())
                        .descripcion(f.getDescripcion())
                        .build())
                    .collect(Collectors.toList()))
                .build();
        })
        .collect(Collectors.toList());
    
    // Contar usuarios activos
    long cantidadUsuarios = usuarioGrupoRepository
        .countByGrupoIdAndActivo(grupoId, "S");
    
    return GrupoDetalleResponse.builder()
        .grupoId(grupo.getId())
        .nombre(grupo.getNombre())
        .cantidadUsuarios(cantidadUsuarios)
        .vigente(grupo.getVigente())
        .titulos(titulosDto)
        .build();
}
```

### Base de Datos

**Query principal (JOIN múltiple):**
```sql
SELECT 
  g.GRUP_ID,
  g.GRUP_NOMBRE,
  g.GRUP_VIGENTE,
  (SELECT COUNT(*) 
   FROM BR_USUARIO_GRUPO 
   WHERE USGR_GRUP_ID = g.GRUP_ID AND USGR_ACTIVO = 'S') AS cantidad_usuarios,
  t.TITU_ID,
  t.TITU_NOMBRE,
  t.TITU_ORDEN,
  f.FUNC_ID,
  f.FUNC_NOMBRE,
  f.FUNC_DESCRIPCION
FROM BR_GRUPOS g
LEFT JOIN BR_TITULOS t ON t.TITU_GRUP_ID = g.GRUP_ID
LEFT JOIN BR_TITULOS_FUNCIONES tf ON tf.TIFU_TITU_ID = t.TITU_ID
LEFT JOIN BR_FUNCIONES f ON f.FUNC_ID = tf.TIFU_FUNC_ID
WHERE g.GRUP_ID = :grupoId
  AND g.GRUP_VIGENTE = :vigente
ORDER BY t.TITU_ORDEN, f.FUNC_NOMBRE;
```

**Query para dropdown (lista de grupos):**
```sql
SELECT GRUP_ID, GRUP_NOMBRE
FROM BR_GRUPOS
WHERE GRUP_VIGENTE = :vigente
ORDER BY GRUP_NOMBRE;
```

## Dependencias

**Funcionales:**
- BR_GRUPOS (tabla principal)
- BR_TITULOS (títulos del grupo)
- BR_TITULOS_FUNCIONES (relación con funciones)
- BR_FUNCIONES (datos de funciones)
- BR_USUARIO_GRUPO (conteo de usuarios)

**Técnicas:**
- Ant Design Select (dropdown con búsqueda)
- Ant Design Switch (toggle vigente/no vigente)
- Redux Toolkit Query (caching automático)

## Testing

### Frontend (Vitest + React Testing Library)

```javascript
describe('SearchBar', () => {
  it('debe recargar dropdown al cambiar toggle vigente', async () => {
    const { rerender } = render(<SearchBar />);
    
    // Verificar carga inicial con vigente='S'
    expect(await screen.findByText(/Sistema OT/)).toBeInTheDocument();
    
    // Cambiar toggle a 'N'
    fireEvent.click(screen.getByRole('switch'));
    
    // Verificar recarga con vigente='N'
    await waitFor(() => {
      expect(screen.queryByText(/Sistema OT/)).not.toBeInTheDocument();
      expect(screen.getByText(/Grupo Antiguo/)).toBeInTheDocument();
    });
  });
  
  it('debe deshabilitar botón lupa si no hay grupo seleccionado', () => {
    render(<SearchBar />);
    
    const lupaButton = screen.getByRole('button', { name: /search/ });
    expect(lupaButton).toBeDisabled();
  });
});
```

### Backend (JUnit 5 + Mockito)

```java
@Test
void buscar_conGrupoExistente_debeRetornarGrupoCompleto() {
    // Arrange
    Grupo grupo = Grupo.builder().id(123L).nombre("Sistema OT").vigente("S").build();
    when(grupoRepository.findByIdAndVigente(123L, "S")).thenReturn(Optional.of(grupo));
    when(tituloRepository.findByGrupoIdOrderByOrden(123L)).thenReturn(List.of(titulo1, titulo2));
    when(usuarioGrupoRepository.countByGrupoIdAndActivo(123L, "S")).thenReturn(100L);
    
    // Act
    GrupoDetalleResponse response = grupoService.buscar(123L, "S");
    
    // Assert
    assertEquals(123L, response.getGrupoId());
    assertEquals("Sistema OT", response.getNombre());
    assertEquals(100L, response.getCantidadUsuarios());
    assertEquals(2, response.getTitulos().size());
}

@Test
void buscar_conGrupoNoExistente_debeLanzarNotFoundException() {
    when(grupoRepository.findByIdAndVigente(999L, "S")).thenReturn(Optional.empty());
    
    assertThrows(NotFoundException.class, () -> {
        grupoService.buscar(999L, "S");
    });
}
```

## Glosario

- **Toggle Vigente**: Switch on/off que filtra grupos por estado de vigencia
- **Acordeón**: Componente UI colapsable (expand/collapse) que muestra títulos y sus funciones
- **Dropdown dinámico**: Select que recarga opciones según filtros aplicados
- **Grupo vigente**: Grupo activo (GRUP_VIGENTE='S') que puede asignarse a usuarios nuevos
- **Grupo no vigente**: Grupo inactivo (GRUP_VIGENTE='N') visible solo para consulta e historial
