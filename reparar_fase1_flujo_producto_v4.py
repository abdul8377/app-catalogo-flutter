from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

PAGE = ROOT / 'lib/features/catalogo/presentation/pages/producto_form_page.dart'
STATE = ROOT / 'lib/features/catalogo/presentation/bloc/producto_form_state.dart'
MATRIX = ROOT / 'lib/features/catalogo/presentation/widgets/producto_matriz_step.dart'
SINGLE = ROOT / 'lib/features/catalogo/presentation/widgets/producto_unico_step.dart'
TEST = ROOT / 'test/producto_form_page_test.dart'

FILES = [PAGE, STATE, MATRIX, SINGLE, TEST]
MARKER = 'static const _pasosInternos = [0, 1, 3, 4, 5, 6];'


def fail(message: str) -> None:
    raise SystemExit(f'\nERROR: {message}\nNo se escribió ningún archivo.')


def read(path: Path) -> str:
    if not path.exists():
        fail(f'No se encontró {path}')
    return path.read_text(encoding='utf-8')


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        fail(
            f'No se pudo aplicar “{label}”. '
            f'Se esperaba 1 coincidencia y se encontraron {count}.'
        )
    return content.replace(old, new, 1)


def regex_once(content: str, pattern: str, replacement: str, label: str) -> str:
    updated, count = re.subn(
        pattern,
        replacement,
        content,
        count=1,
        flags=re.DOTALL,
    )
    if count != 1:
        fail(
            f'No se pudo aplicar “{label}”. '
            f'Se esperaba 1 bloque compatible y se encontraron {count}.'
        )
    return updated


originals = {path: read(path) for path in FILES}

if MARKER not in originals[PAGE]:
    fail(
        'No se encontró el flujo de seis pasos. '
        'Primero debe estar aplicada la fase 1 versión 3.'
    )

updates = dict(originals)

combined_class = r'''class _PasoFamiliaTipo extends StatelessWidget {
  const _PasoFamiliaTipo({required this.state});

  final ProductoFormState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 720;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 20,
              compact ? 10 : 20,
              compact ? 12 : 20,
              0,
            ),
            child: _configurationCard(context, compact: compact),
          ),
          SizedBox(height: compact ? 8 : 14),
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
    },
  );

  Widget _configurationCard(
    BuildContext context, {
    required bool compact,
  }) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFD5DDE8)),
    ),
    child: Padding(
      padding: EdgeInsets.all(compact ? 14 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Cómo se organiza este producto?',
            style: TextStyle(
              color: const Color(0xFF20242B),
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 5),
            const Text(
              'Elige una opción. Los datos del artículo se completan debajo.',
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
          SizedBox(height: compact ? 10 : 14),
          _typeSelector(context, compact: compact),
          SizedBox(height: compact ? 12 : 16),
          if (state.tipoRegistro == 'unico')
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: compact ? 9 : 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFF8A6700),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'El nombre general se tomará del nombre comercial.',
                      style: TextStyle(
                        color: Color(0xFF5F4A00),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            _familyFields(context, compact: compact),
        ],
      ),
    ),
  );

  Widget _typeSelector(
    BuildContext context, {
    required bool compact,
  }) {
    final options = [
      (
        value: 'unico',
        title: 'Producto único',
        subtitle: 'Un artículo',
        icon: Icons.inventory_2_outlined,
      ),
      (
        value: 'variantes',
        title: 'Lista de variantes',
        subtitle: 'Medidas o modelos',
        icon: Icons.view_list_outlined,
      ),
      (
        value: 'matriz',
        title: 'Matriz',
        subtitle: 'Dos ejes',
        icon: Icons.grid_view_outlined,
      ),
    ];

    if (compact) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < options.length; index++) ...[
              SizedBox(
                width: 176,
                child: _typeOption(
                  context,
                  value: options[index].value,
                  title: options[index].title,
                  subtitle: options[index].subtitle,
                  icon: options[index].icon,
                  compact: true,
                ),
              ),
              if (index < options.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          Expanded(
            child: _typeOption(
              context,
              value: options[index].value,
              title: options[index].title,
              subtitle: options[index].subtitle,
              icon: options[index].icon,
              compact: false,
            ),
          ),
          if (index < options.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _familyFields(
    BuildContext context, {
    required bool compact,
  }) {
    final name = TextFormField(
      key: const Key('familia_nombre'),
      initialValue: state.nombre,
      onChanged: (value) => context.read<ProductoFormBloc>().add(
        ProductoFormFamiliaCambiada(nombre: value),
      ),
      decoration: const InputDecoration(
        labelText: 'Nombre general del producto *',
        hintText: 'Ej. Broca para metal HSS',
        helperText: 'Agrupa las medidas o modelos del mismo producto.',
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
      maxLines: compact ? 2 : 3,
      decoration: const InputDecoration(
        labelText: 'Descripción general',
        hintText: 'Características compartidas por las variantes.',
        border: OutlineInputBorder(),
      ),
    );

    if (compact) {
      return Column(
        children: [
          name,
          const SizedBox(height: 10),
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
  }

  Widget _typeOption(
    BuildContext context, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool compact,
  }) {
    final selected = state.tipoRegistro == value;

    return InkWell(
      onTap: () =>
          context.read<ProductoFormBloc>().add(ProductoFormTipoCambiado(value)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 64 : 76),
        padding: EdgeInsets.all(compact ? 10 : 12),
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
            Icon(icon, color: const Color(0xFF20242B), size: compact ? 20 : 24),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF20242B),
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFC500),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

'''

updates[PAGE] = regex_once(
    updates[PAGE],
    r'''class _PasoFamiliaTipo extends StatelessWidget \{
.*?
\}

class _PasoGeneralEdicion extends StatelessWidget''',
    combined_class + 'class _PasoGeneralEdicion extends StatelessWidget',
    'encabezado combinado adaptable',
)

updates[STATE] = regex_once(
    updates[STATE],
    r'''  List<AtributoDef> get atributosDisponibles \{
.*?
  \}''',
    '''  List<AtributoDef> get atributosDisponibles {
    final formData = datos;
    if (formData == null) return const [];

    final subcategory = subcategoria;
    if (subcategory != null) {
      final values = formData.atributos[subcategory];
      if (values != null && values.isNotEmpty) return values;
    }

    final category = categoria;
    return category == null
        ? const []
        : formData.atributos[category] ?? const [];
  }''',
    'herencia de atributos de categoría',
)

updates[MATRIX] = replace_once(
    updates[MATRIX],
    '''        _buildMatrixTextField(
          label: 'Código / SKU',
''',
    '''        _buildMatrixTextField(
          fieldKey: const Key('matriz_sku'),
          label: 'Código / SKU',
''',
    'clave del código matricial',
)

updates[MATRIX] = replace_once(
    updates[MATRIX],
    '''        _buildMatrixTextField(
          label: 'Nombre generado',
''',
    '''        _buildMatrixTextField(
          fieldKey: const Key('matriz_nombre'),
          label: 'Nombre generado',
''',
    'clave del nombre matricial',
)

updates[MATRIX] = replace_once(
    updates[MATRIX],
    '''  Widget _buildMatrixTextField({
    required String label,
''',
    '''  Widget _buildMatrixTextField({
    Key? fieldKey,
    required String label,
''',
    'parámetro de clave matricial',
)

updates[MATRIX] = replace_once(
    updates[MATRIX],
    '''      TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        onChanged: (_) => _markMatrixEditorDirty(),
        decoration: _matrixInputDecoration(hint: hint),
      ),
''',
    '''      TextFormField(
        key: fieldKey,
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        onChanged: (_) => _markMatrixEditorDirty(),
        decoration: _matrixInputDecoration(hint: hint),
      ),
''',
    'uso de la clave matricial',
)

updates[SINGLE] = regex_once(
    updates[SINGLE],
    r'''
  Widget _buildSingleInformationPanel\(\) => Card\(
.*?
  Widget _buildSingleSectionTitle''',
    '\n  Widget _buildSingleSectionTitle',
    'panel informativo obsoleto',
)

updates[SINGLE] = regex_once(
    updates[SINGLE],
    r'''
  Widget _buildSingleInformationRow\(IconData icon, String text\) => Padding\(
.*?
  Widget _buildSingleTextField''',
    '\n  Widget _buildSingleTextField',
    'ayudantes informativos obsoletos',
)

updates[SINGLE] = updates[SINGLE].replace(
    'activado en el paso 7.',
    'activado en el paso 6.',
)

updates[TEST] = replace_once(
    updates[TEST],
    '''      final matrixFields = find.byType(TextFormField);
      await tester.enterText(matrixFields.at(0), 'MATRIX-EDITADO');
      await tester.enterText(matrixFields.at(1), 'Perno hexagonal editado');
''',
    '''      await tester.enterText(
        find.byKey(const Key('matriz_sku')),
        'MATRIX-EDITADO',
      );
      await tester.enterText(
        find.byKey(const Key('matriz_nombre')),
        'Perno hexagonal editado',
      );
''',
    'campos correctos del editor matricial',
)

attribute_definitions = '''        atributos: {
          'Pernería': [
            AtributoDef(
              nombre: 'Diámetro',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm', 'in', '″'],
              unidadPredeterminada: 'mm',
            ),
            AtributoDef(
              nombre: 'Largo',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm', 'cm', 'in', '″'],
              unidadPredeterminada: 'mm',
            ),
          ],
          'Pernos métricos': [
            AtributoDef(
              nombre: 'Diámetro',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm'],
              unidadPredeterminada: 'mm',
            ),
            AtributoDef(
              nombre: 'Largo',
              tipo: 'numero_unidad',
              esVariante: true,
              requerido: true,
              unidades: ['mm'],
              unidadPredeterminada: 'mm',
            ),
          ],
        },
'''

updates[TEST] = replace_once(
    updates[TEST],
    "        atributos: {'Pernería': []},\n",
    attribute_definitions,
    'atributos del repositorio falso',
)

timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
backup_dir = ROOT / f'.backup_reparacion_flujo_{timestamp}'
backup_dir.mkdir(parents=True, exist_ok=False)

for path in FILES:
    relative = path.relative_to(ROOT)
    destination = backup_dir / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)

for path, content in updates.items():
    path.write_text(content, encoding='utf-8', newline='\n')
    print(f'Modificado: {path.relative_to(ROOT)}')

print(f'\nRespaldo creado en: {backup_dir}')
print('\nReparación aplicada correctamente.')
print('Ejecuta:')
print('  dart format lib test')
print('  flutter test test/producto_form_page_test.dart')
print('  flutter analyze')
