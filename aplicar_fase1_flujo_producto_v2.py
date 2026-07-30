from __future__ import annotations

from pathlib import Path
import re
import shutil
from datetime import datetime

ROOT = Path.cwd()

FILES = {
    "page": ROOT / "lib/features/catalogo/presentation/pages/producto_form_page.dart",
    "bloc": ROOT / "lib/features/catalogo/presentation/bloc/producto_form_bloc.dart",
    "state": ROOT / "lib/features/catalogo/presentation/bloc/producto_form_state.dart",
    "single": ROOT / "lib/features/catalogo/presentation/widgets/producto_unico_step.dart",
    "variants": ROOT / "lib/features/catalogo/presentation/widgets/producto_variantes_step.dart",
    "tests": ROOT / "test/producto_form_page_test.dart",
}

MARKER = "static const _pasosInternos = [0, 1, 3, 4, 5, 6];"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se escribió ningún archivo.")


def read(path: Path) -> str:
    if not path.exists():
        fail(f"No se encontró {path}")
    return path.read_text(encoding="utf-8")


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar ‘{label}’. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return content.replace(old, new, 1)


def regex_once(
    content: str,
    pattern: str,
    replacement: str,
    label: str,
    *,
    flags: int = re.DOTALL,
) -> str:
    updated, count = re.subn(pattern, replacement, content, count=1, flags=flags)
    if count != 1:
        fail(
            f"No se pudo aplicar ‘{label}’. "
            f"Se esperaba 1 bloque compatible y se encontraron {count}."
        )
    return updated


def optional_replace(content: str, old: str, new: str) -> str:
    return content.replace(old, new)


contents = {name: read(path) for name, path in FILES.items()}

if MARKER in contents["page"]:
    fail("La fusión del flujo ya parece estar aplicada.")

# ---------------------------------------------------------------------------
# BLoC: paso combinado 1 -> 3 y regreso 3 -> 1.
# ---------------------------------------------------------------------------
bloc = contents["bloc"]

bloc = regex_once(
    bloc,
    r"""    on<ProductoFormPasoSiguiente>\(\(_, emit\) \{
.*?
    \}\);""",
    """    on<ProductoFormPasoSiguiente>((_, emit) {
      if (!state.pasoValido) {
        emit(state.copyWith(error: state.mensajePasoInvalido));
      } else if (state.paso < 6) {
        final siguiente = state.paso == 1 ? 3 : state.paso + 1;
        emit(state.copyWith(paso: siguiente, limpiarError: true));
      }
    });""",
    "salto del paso combinado al paso de venta",
)

bloc = regex_once(
    bloc,
    r"""    on<ProductoFormPasoAnterior>\(\(_, emit\) \{
.*?
    \}\);""",
    """    on<ProductoFormPasoAnterior>((_, emit) {
      if (state.paso > 0) {
        final anterior = state.paso == 3 ? 1 : state.paso - 1;
        emit(state.copyWith(paso: anterior, limpiarError: true));
      }
    });""",
    "regreso desde venta al paso combinado",
)

bloc = regex_once(
    bloc,
    r"""    on<ProductoFormTipoCambiado>\(
.*?
    \);""",
    """    on<ProductoFormTipoCambiado>((event, emit) {
      if (event.tipo == state.tipoRegistro) return;
      emit(
        state.copyWith(
          tipoRegistro: event.tipo,
          codigo: '',
          variantes: const [],
          edicionVariantePendiente: false,
          limpiarError: true,
        ),
      );
    });""",
    "reinicio seguro al cambiar el tipo de registro",
)
contents["bloc"] = bloc

# ---------------------------------------------------------------------------
# Estado: el paso 1 valida nombre y variantes.
# ---------------------------------------------------------------------------
state = contents["state"]
state = replace_once(
    state,
    """    1 => nombre.trim().isNotEmpty,
    2 => variantesValidas,
""",
    """    1 => nombre.trim().isNotEmpty && variantesValidas,
    2 => variantesValidas,
""",
    "validación del paso combinado",
)

state = regex_once(
    state,
    r"""  String get mensajePasoInvalido => switch \(paso\) \{
.*?
  \};""",
    """  String get mensajePasoInvalido => switch (paso) {
    0 => 'Completa la empresa, marca, categoría y subcategoría requeridas.',
    1 when nombre.trim().isEmpty =>
      tipoRegistro == 'unico'
          ? 'Ingresa el nombre comercial del producto.'
          : 'Ingresa el nombre general del producto.',
    1 when edicionVariantePendiente =>
      'Guarda o cancela los cambios de la variante antes de continuar.',
    1 when variantes.isEmpty =>
      tipoRegistro == 'unico'
          ? 'Completa los datos del producto único.'
          : 'Agrega al menos una variante para continuar.',
    1 when !variantes.any((variante) => variante.activa) =>
      'Activa al menos una variante para continuar.',
    1 when !variantesCompletas =>
      'Completa el código interno y el nombre de todas las variantes.',
    1 when !variantesConSkuUnico =>
      'Corrige los códigos internos duplicados antes de continuar.',
    1 when tipoRegistro == 'unico' && variantes.length != 1 =>
      'Un producto único debe tener exactamente una variante.',
    2 when edicionVariantePendiente =>
      'Guarda o cancela los cambios de la variante antes de continuar.',
    2 when variantes.isEmpty => 'Agrega al menos una variante para continuar.',
    2 when !variantes.any((variante) => variante.activa) =>
      'Activa al menos una variante para continuar.',
    2 when !variantesCompletas =>
      'Completa el código interno y el nombre de todas las variantes.',
    2 when !variantesConSkuUnico =>
      'Corrige los códigos internos duplicados antes de continuar.',
    2 when tipoRegistro == 'unico' && variantes.length != 1 =>
      'Un producto único debe tener exactamente una variante.',
    3 => 'Agrega al menos una presentación para continuar.',
    _ => 'Revisa los datos requeridos antes de continuar.',
  };""",
    "mensajes del paso combinado",
)

state = replace_once(
    state,
    """    if (nombre.trim().isEmpty) return editando ? 0 : 1;
    if (!variantesValidas) return editando ? 1 : 2;
""",
    """    if (nombre.trim().isEmpty || !variantesValidas) return 1;
""",
    "primer paso inválido combinado",
)
contents["state"] = state

# ---------------------------------------------------------------------------
# Página: indicador de seis pasos y paso 2 combinado.
# ---------------------------------------------------------------------------
page = contents["page"]
page = replace_once(
    page,
    "              if (state.paso < 3) _BottomNavigation(state: state),",
    "              if (state.paso <= 1) _BottomNavigation(state: state),",
    "barra inferior del flujo combinado",
)

step_indicator = r'''class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.paso, required this.tipoRegistro});

  final int paso;
  final String tipoRegistro;

  static const _pasosInternos = [0, 1, 3, 4, 5, 6];
  static const _nombres = [
    'Empresa, marca y categoría',
    'Producto y variantes',
    'Venta, presentaciones y logística',
    'Precios',
    'Imágenes y archivos',
    'Publicación y revisión',
  ];
  static const _subtitulos = [
    'Selecciona la clasificación comercial del producto.',
    'Define el producto vendible y sus variantes en una sola pantalla.',
    'Configura unidades de venta, equivalencias y empaques.',
    'Asigna precios o deja combinaciones pendientes de cotización.',
    'Adjunta fotografías y define la imagen principal.',
    'Comprueba la información antes de publicar el producto.',
  ];

  int get _indiceVisual {
    final index = _pasosInternos.indexOf(paso);
    return index < 0 ? 1 : index;
  }

  String get _nombreActual {
    if (_indiceVisual != 1) return _nombres[_indiceVisual];
    return switch (tipoRegistro) {
      'matriz' => 'Producto y matriz de variantes',
      'unico' => 'Producto único',
      _ => 'Producto y lista de variantes',
    };
  }

  String get _subtituloActual {
    if (_indiceVisual != 1) return _subtitulos[_indiceVisual];
    return switch (tipoRegistro) {
      'matriz' => 'Define el nombre general y genera combinaciones por dos ejes.',
      'unico' =>
        'Completa el único artículo vendible; la familia se creará automáticamente.',
      _ => 'Define el nombre general y registra sus artículos vendibles.',
    };
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontalPadding = constraints.maxWidth < 500 ? 16.0 : 28.0;
      final current = _indiceVisual;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          14,
          horizontalPadding,
          16,
        ),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  children: [
                    for (var index = 0; index < _pasosInternos.length; index++) ...[
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index <= current
                                ? const Color(0xFFFFC500)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                      Tooltip(
                        message: 'Ir al paso ${index + 1}: ${_nombres[index]}',
                        child: Semantics(
                          button: true,
                          selected: index == current,
                          label: 'Paso ${index + 1}: ${_nombres[index]}',
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: ValueKey('paso_flujo_${index + 1}'),
                              customBorder: const CircleBorder(),
                              onTap: () => context.read<ProductoFormBloc>().add(
                                ProductoFormPasoSeleccionado(
                                  _pasosInternos[index],
                                ),
                              ),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index <= current
                                      ? const Color(0xFFFFC500)
                                      : Colors.white,
                                  border: Border.all(
                                    color: index <= current
                                        ? const Color(0xFFFFC500)
                                        : const Color(0xFFD0D5DD),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: constraints.maxWidth < 500 ? 12 : 16),
            Text(
              _nombreActual,
              style: GoogleFonts.inter(
                color: const Color(0xFF1A1A1A),
                fontSize: constraints.maxWidth < 500 ? 18 : 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtituloActual,
              style: GoogleFonts.inter(
                color: const Color(0xFF667085),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    },
  );
}

'''

page = regex_once(
    page,
    r"""class _StepIndicator extends StatelessWidget \{
.*?
\}

class _PasoActual extends StatelessWidget""",
    step_indicator + "class _PasoActual extends StatelessWidget",
    "indicador de seis pasos",
)

paso_actual = r'''class _PasoActual extends StatelessWidget {
  const _PasoActual({required this.state, super.key});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) {
    if (state.paso == 3) {
      return ProductoVentaLogisticaStep(state: state);
    }
    if (state.paso == 4) {
      return ProductoPreciosStep(state: state);
    }
    if (state.paso == 5) {
      return ProductoImagenesStep(state: state);
    }
    if (state.paso == 6) {
      return ProductoRevisionStep(state: state);
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: switch (state.paso) {
          0 => _PasoClasificacion(state: state),
          1 || 2 => _PasoFamiliaTipo(state: state),
          _ => _PasoEstado(state: state),
        },
      ),
    );
  }
}

'''

page = regex_once(
    page,
    r"""class _PasoActual extends StatelessWidget \{
.*?
\}

class _PasoClasificacion extends StatelessWidget""",
    paso_actual + "class _PasoClasificacion extends StatelessWidget",
    "contenido del paso combinado",
)

combined_step = r'''class _PasoFamiliaTipo extends StatelessWidget {
  const _PasoFamiliaTipo({required this.state});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: _configurationCard(context),
      ),
      const SizedBox(height: 14),
      Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey('editor-${state.tipoRegistro}'),
            child: switch (state.tipoRegistro) {
              'matriz' => ProductoMatrizStep(state: state),
              'unico' => ProductoUnicoStep(state: state),
              _ => ProductoVariantesStep(state: state),
            },
          ),
        ),
      ),
    ],
  );

  Widget _configurationCard(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD5DDE8)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Cómo se organiza este producto?',
            style: TextStyle(
              color: Color(0xFF20242B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Elige una opción. Los datos del artículo se completan debajo.',
            style: TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final options = [
                _typeOption(
                  context,
                  value: 'unico',
                  title: 'Producto único',
                  subtitle: 'Un solo artículo vendible',
                  icon: Icons.inventory_2_outlined,
                ),
                _typeOption(
                  context,
                  value: 'variantes',
                  title: 'Lista de variantes',
                  subtitle: 'Medidas o modelos independientes',
                  icon: Icons.view_list_outlined,
                ),
                _typeOption(
                  context,
                  value: 'matriz',
                  title: 'Matriz',
                  subtitle: 'Combinaciones de dos ejes',
                  icon: Icons.grid_view_outlined,
                ),
              ];
              if (compact) {
                return Column(
                  children: [
                    for (var index = 0; index < options.length; index++) ...[
                      options[index],
                      if (index < options.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < options.length; index++) ...[
                    Expanded(child: options[index]),
                    if (index < options.length - 1)
                      const SizedBox(width: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (state.tipoRegistro == 'unico')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: Color(0xFF8A6700)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El nombre general se tomará del nombre comercial del '
                      'producto. No tendrás que escribirlo dos veces.',
                      style: TextStyle(
                        color: Color(0xFF5F4A00),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final name = TextFormField(
                  key: const Key('familia_nombre'),
                  initialValue: state.nombre,
                  onChanged: (value) => context.read<ProductoFormBloc>().add(
                    ProductoFormFamiliaCambiada(nombre: value),
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nombre general del producto *',
                    hintText: 'Ej. Broca para metal HSS',
                    helperText:
                        'Agrupa medidas, modelos o versiones del mismo producto.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                );
                final description = TextFormField(
                  key: const Key('familia_descripcion'),
                  initialValue: state.descripcion,
                  onChanged: (value) => context.read<ProductoFormBloc>().add(
                    ProductoFormFamiliaCambiada(descripcion: value),
                  ),
                  maxLines: compact ? 3 : 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción general',
                    hintText:
                        'Características compartidas por todas las variantes.',
                    border: OutlineInputBorder(),
                  ),
                );
                if (compact) {
                  return Column(
                    children: [
                      name,
                      const SizedBox(height: 12),
                      description,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    Expanded(child: description),
                  ],
                );
              },
            ),
        ],
      ),
    ),
  );

  Widget _typeOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = state.tipoRegistro == value;
    return InkWell(
      onTap: () =>
          context.read<ProductoFormBloc>().add(ProductoFormTipoCambiado(value)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFC500).withValues(alpha: .12)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFC500)
                : const Color(0xFFD5DDE8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF20242B)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF20242B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFC500),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

'''

page = regex_once(
    page,
    r"""class _PasoFamiliaTipo extends StatefulWidget \{
.*?
\}

class _PasoGeneralEdicion extends StatelessWidget""",
    combined_step + "class _PasoGeneralEdicion extends StatelessWidget",
    "fusión de familia, tipo y variantes",
)

page = optional_replace(
    page,
    "(state.paso == 2 && state.edicionVariantePendiente)",
    "(state.paso == 1 && state.edicionVariantePendiente)",
)
page = optional_replace(
    page,
    """if (state.paso == 2 &&
                       state.tipoRegistro == 'unico' &&""",
    """if (state.paso == 1 &&
                       state.tipoRegistro == 'unico' &&""",
)
page = regex_once(
    page,
    r"""            label: Text\(
              state\.paso == 6
.*?
            \),""",
    """            label: Text(
              state.paso == 6
                  ? 'Publicar'
                  : state.paso == 1
                  ? compact
                        ? 'Siguiente'
                        : 'Siguiente: venta y empaques'
                  : 'Continuar',
            ),""",
    "texto del botón siguiente",
)
contents["page"] = page

# ---------------------------------------------------------------------------
# Producto único: familia automática y atributos desde categoría.
# ---------------------------------------------------------------------------
single = contents["single"]
single = regex_once(
    single,
    r"""  List<_SingleAttributeTemplate> get _singleSuggestedTemplates \{
.*?
  \}

  @override
  void initState""",
    r"""  List<_SingleAttributeTemplate> get _singleSuggestedTemplates =>
      widget.state.atributosDisponibles.map((definition) {
        final kind = switch (definition.tipo) {
          'numero' || 'numero_unidad' => _SingleAttributeKind.number,
          'lista_unica' => _SingleAttributeKind.selection,
          _ => _SingleAttributeKind.text,
        };
        return _SingleAttributeTemplate(
          name: definition.nombre,
          kind: kind,
          units: kind == _SingleAttributeKind.number
              ? definition.unidades
              : const [],
          defaultUnit: definition.unidadPredeterminada,
          options: kind == _SingleAttributeKind.selection
              ? definition.opciones
              : const [],
        );
      }).toList();

  @override
  void initState""",
    "atributos del producto único desde la categoría",
)
single = replace_once(
    single,
    """        ProductoFormFamiliaCambiada(
          descripcion: _singleDescriptionController.text,
        ),""",
    """        ProductoFormFamiliaCambiada(
          nombre: _singleNameController.text,
          descripcion: _singleDescriptionController.text,
        ),""",
    "nombre automático de familia para producto único",
)
single = optional_replace(
    single,
    "title: 'Atributos técnicos sugeridos para $_singleCategoryLabel',",
    "title: 'Características técnicas de $_singleCategoryLabel',",
)
single = optional_replace(
    single,
    "'Puedes completar, editar, eliminar o añadir atributos.'",
    "'Los campos provienen de la categoría. Puedes añadir una característica excepcional.'",
)
single = optional_replace(
    single,
    "label: const Text('Añadir atributo'),",
    "label: const Text('Añadir característica adicional'),",
)
single = optional_replace(
    single,
    "editing ? 'Editar atributo' : 'Añadir atributo'",
    "editing ? 'Editar característica' : 'Añadir característica'",
)
contents["single"] = single

# ---------------------------------------------------------------------------
# Lista de variantes: decimales, fracciones y números mixtos.
# ---------------------------------------------------------------------------
variants = contents["variants"]
variants = replace_once(
    variants,
    """                            return RegExp(
                                  r'^\\d*(?:[.,]\\d*)?$',
                                ).hasMatch(newValue.text)
""",
    """                            return RegExp(
                                  r'^[0-9\\s/.,]*$',
                                ).hasMatch(newValue.text)
""",
    "entrada de fracciones en atributos de variante",
)
variants = replace_once(
    variants,
    """    final number = double.tryParse(value.replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return '${spec.nombre} debe ser mayor que cero.';
    }
    return null;
  }
""",
    """    final number = _parseVariantNumber(value);
    if (number == null || number <= 0) {
      return '${spec.nombre} debe ser un número, fracción o número mixto válido.';
    }
    return null;
  }

  double? _parseVariantNumber(String raw) {
    final value = raw.trim().replaceAll(',', '.');
    final mixed = RegExp(r'^(\\d+)\\s+(\\d+)\\s*/\\s*(\\d+)$').firstMatch(value);
    if (mixed != null) {
      final whole = double.parse(mixed.group(1)!);
      final numerator = double.parse(mixed.group(2)!);
      final denominator = double.parse(mixed.group(3)!);
      return denominator == 0 ? null : whole + numerator / denominator;
    }
    final fraction = RegExp(r'^(\\d+)\\s*/\\s*(\\d+)$').firstMatch(value);
    if (fraction != null) {
      final numerator = double.parse(fraction.group(1)!);
      final denominator = double.parse(fraction.group(2)!);
      return denominator == 0 ? null : numerator / denominator;
    }
    return double.tryParse(value);
  }
""",
    "validación de fracciones en atributos de variante",
)
contents["variants"] = variants

# ---------------------------------------------------------------------------
# Pruebas principales.
# ---------------------------------------------------------------------------
tests = contents["tests"]
first_test = r'''  testWidgets('el indicador usa seis pasos y permite navegar por número', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();

    expect(find.byKey(const ValueKey('paso_flujo_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_6')), findsOneWidget);
    expect(find.byKey(const ValueKey('paso_flujo_7')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('paso_flujo_3')));
    await tester.pumpAndSettle();

    expect(bloc.state.paso, 3);

    await tester.tap(find.byKey(const ValueKey('paso_flujo_2')));
    await tester.pumpAndSettle();

    expect(bloc.state.paso, 1);
    expect(tester.takeException(), isNull);
  });

'''
tests = regex_once(
    tests,
    r"""  testWidgets\('el indicador permanece visible y permite navegar por número'.*?
  \}\);

""",
    first_test,
    "prueba del indicador de seis pasos",
)

combined_test = r'''  testWidgets('el paso 2 combina tipo, familia y variantes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<CatalogoRepository>.value(
        value: _FakeCatalogoRepository(),
        child: const MaterialApp(home: ProductoFormPage()),
      ),
    );
    await tester.pumpAndSettle();

    final bloc = tester.element(find.byType(Scaffold)).read<ProductoFormBloc>();

    Future<void> selectDropdown(int index, String value) async {
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(index));
      await tester.pumpAndSettle();
      await tester.tap(find.text(value).last);
      await tester.pumpAndSettle();
    }

    await selectDropdown(0, 'DINA');
    await selectDropdown(1, 'DINA');
    await selectDropdown(2, 'Pernería');
    await selectDropdown(3, 'Pernos métricos');

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(bloc.state.paso, 1);
    expect(find.text('¿Cómo se organiza este producto?'), findsOneWidget);
    expect(find.text('Atributos de la categoría'), findsNothing);

    await tester.tap(find.text('Lista de variantes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('familia_nombre')), findsOneWidget);
    expect(find.text('Variantes creadas'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('familia_nombre')),
      'Familia de prueba',
    );
    await tester.pump();

    expect(bloc.state.nombre, 'Familia de prueba');
    expect(bloc.state.tipoRegistro, 'variantes');
    expect(tester.takeException(), isNull);
  });

'''
tests = regex_once(
    tests,
    r"""  testWidgets\('los pasos 1 y 2 conservan el nuevo diseño y su flujo'.*?
  \}\);

""",
    combined_test,
    "prueba del paso combinado",
)

tests = optional_replace(
    tests,
    "..add(const ProductoFormPasoSeleccionado(2));",
    "..add(const ProductoFormPasoSeleccionado(1));",
)
tests = optional_replace(
    tests,
    "expect(bloc.state.paso, 2);\n      expect(find.text('Ingresa el nombre comercial.')",
    "expect(bloc.state.paso, 1);\n      expect(find.text('Ingresa el nombre comercial.')",
)
tests = optional_replace(
    tests,
    "for (var i = 0; i < 3; i++) {",
    "for (var i = 0; i < 2; i++) {",
)
contents["tests"] = tests

# Renumerar títulos visibles de módulos posteriores.
renumber = {
    "Paso 4 · Venta, logística y contenido": "Paso 3 · Venta, logística y contenido",
    "Paso 5 · Precios": "Paso 4 · Precios",
    "Paso 6 · Imágenes": "Paso 5 · Imágenes",
    "Paso 7 · Revisar y activar": "Paso 6 · Revisar y activar",
    "Paso 7 · Revisión y activación": "Paso 6 · Revisión y activación",
}
for old, new in renumber.items():
    contents["tests"] = contents["tests"].replace(old, new)

extra_files: dict[Path, str] = {}
widgets_dir = ROOT / "lib/features/catalogo/presentation/widgets"
for path in widgets_dir.glob("*.dart"):
    text = read(path)
    updated = text
    for old, new in renumber.items():
        updated = updated.replace(old, new)
    if updated != text:
        extra_files[path] = updated

# Escritura con respaldo, solo después de validar todos los bloques.
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_flujo_producto_{timestamp}"
all_updates = {FILES[name]: value for name, value in contents.items()}
all_updates.update(extra_files)

backup_dir.mkdir(parents=True, exist_ok=False)
for path in all_updates:
    relative = path.relative_to(ROOT)
    destination = backup_dir / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)

for path, value in all_updates.items():
    path.write_text(value, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nCambio de flujo aplicado.")
print("Ejecuta ahora:")
print("  dart format lib test")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
