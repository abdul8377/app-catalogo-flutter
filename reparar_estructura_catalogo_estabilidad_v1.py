from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

STRUCTURE_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/widgets/"
    / "estructura_catalogo_corregida.dart"
)
MANAGER_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/pages/"
    / "gestionar_atributos_categoria.dart"
)
INTEGRATED_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/pages/"
    / "estructura_catalogo_integrada.dart"
)
TEST_PATH = ROOT / "test/estructura_catalogo_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
    label: str,
) -> str:
    start_count = source.count(start_marker)
    end_count = source.count(end_marker)
    if start_count != 1 or end_count != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio={start_count}, final={end_count}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


def matching_brace(source: str, opening: int) -> int:
    depth = 0
    index = opening
    quote: str | None = None
    triple = False
    line_comment = False
    block_comment = 0

    while index < len(source):
        char = source[index]
        nxt = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue

        if block_comment:
            if char == "/" and nxt == "*":
                block_comment += 1
                index += 2
                continue
            if char == "*" and nxt == "/":
                block_comment -= 1
                index += 2
                continue
            index += 1
            continue

        if quote is not None:
            if triple:
                if source.startswith(quote * 3, index):
                    quote = None
                    triple = False
                    index += 3
                    continue
                index += 1
                continue
            if char == "\\":
                index += 2
                continue
            if char == quote:
                quote = None
            index += 1
            continue

        if char == "/" and nxt == "/":
            line_comment = True
            index += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = 1
            index += 2
            continue
        if char in ("'", '"'):
            if source.startswith(char * 3, index):
                quote = char
                triple = True
                index += 3
            else:
                quote = char
                index += 1
            continue

        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
        index += 1

    fail("No se encontró el cierre de un bloque Dart.")
    raise AssertionError


def replace_class(
    source: str,
    class_marker: str,
    replacement: str,
    label: str,
) -> str:
    count = source.count(class_marker)
    if count != 1:
        fail(
            f"No se pudo localizar “{label}”. "
            f"Se esperaba 1 clase y se encontraron {count}."
        )
    start = source.index(class_marker)
    opening = source.find("{", start)
    if opening < 0:
        fail(f"No se encontró el cuerpo de “{label}”.")
    end = matching_brace(source, opening) + 1
    while end < len(source) and source[end] in " \t\r\n":
        end += 1
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


def remove_controller_disposals(
    source: str,
    start_marker: str,
    end_marker: str,
    label: str,
) -> str:
    if source.count(start_marker) != 1 or source.count(end_marker) != 1:
        fail(f"No se pudo delimitar el formulario “{label}”.")
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    block = source[start:end]
    updated, count = re.subn(
        r"(?m)^\s*[A-Za-z_][A-Za-z0-9_]*Controller\.dispose\(\);\s*\n",
        "",
        block,
    )
    if count == 0:
        fail(f"No se encontraron controladores temporales en “{label}”.")
    return source[:start] + updated + source[end:]


for path in (STRUCTURE_PATH, MANAGER_PATH, INTEGRATED_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

structure = STRUCTURE_PATH.read_text(encoding="utf-8")
manager = MANAGER_PATH.read_text(encoding="utf-8")
integrated = INTEGRATED_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

if "String _brandCompanyFilterId" in structure:
    fail("El archivo de estructura no corresponde al estado esperado.")
if "String? _brandCompanyFilterId;" not in structure:
    fail("No se encontró el filtro de empresas de la fase 1B.")
if "Gestionar atributos · ${widget.categoryName}" not in manager:
    fail("No se encontró el encabezado actual de Gestionar atributos.")
if "key: ValueKey(snapshot)," not in integrated:
    fail("No se encontró la clave que reinicia el módulo tras guardar.")

# ---------------------------------------------------------------------------
# 1. El panel conserva pestaña y selección al actualizarse el BLoC.
# ---------------------------------------------------------------------------

integrated = replace_once(
    integrated,
    "                        key: ValueKey(snapshot),\n",
    "",
    "conservar el estado del panel al actualizar el snapshot",
)

sync_code = r'''  @override
  void didUpdateWidget(covariant CatalogStructurePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final companiesChanged =
        _companiesFingerprint(oldWidget.companies) !=
        _companiesFingerprint(widget.companies);
    final brandsChanged =
        _brandsFingerprint(oldWidget.brands) !=
        _brandsFingerprint(widget.brands);
    final categoriesChanged =
        _categoriesFingerprint(oldWidget.categories) !=
        _categoriesFingerprint(widget.categories);
    final attributesChanged =
        _attributesFingerprint(oldWidget.attributes) !=
        _attributesFingerprint(widget.attributes);
    final relationsChanged =
        _relationsFingerprint(oldWidget.relations) !=
        _relationsFingerprint(widget.relations);

    final selectedCategoryName = _firstWhereOrNull(
      _categories,
      (item) => item.id == _selectedCategoryId,
    )?.name;
    final selectedCompanyName = _firstWhereOrNull(
      _companies,
      (item) => item.id == _selectedCompanyId,
    )?.name;
    final selectedBrandName = _firstWhereOrNull(
      _brands,
      (item) => item.id == _selectedBrandId,
    )?.name;

    if (companiesChanged) _companies = [...widget.companies];
    if (brandsChanged) _brands = [...widget.brands];
    if (categoriesChanged) _categories = [...widget.categories];
    if (attributesChanged) _attributes = [...widget.attributes];
    if (relationsChanged) {
      _relations = [...widget.relations];
      _savedRelations = _relationMap(_relations);
      _workingRelations = _copyRelationMap(_savedRelations);
    }

    if (_selectedCategoryId != null &&
        !_categories.any((item) => item.id == _selectedCategoryId)) {
      _selectedCategoryId = _firstWhereOrNull(
        _categories,
        (item) => item.name == selectedCategoryName,
      )?.id;
      _selectedCategoryId ??= _categories.isEmpty ? null : _categories.first.id;
    }

    if (_selectedCompanyId != null &&
        !_companies.any((item) => item.id == _selectedCompanyId)) {
      _selectedCompanyId = _firstWhereOrNull(
        _companies,
        (item) => item.name == selectedCompanyName,
      )?.id;
      _selectedCompanyId ??= _companies.isEmpty ? null : _companies.first.id;
    }

    if (_selectedBrandId != null &&
        !_brands.any((item) => item.id == _selectedBrandId)) {
      _selectedBrandId = _firstWhereOrNull(
        _brands,
        (item) => item.name == selectedBrandName,
      )?.id;
      _selectedBrandId ??= _firstBrandIdFor(_selectedCompanyId);
    }

    if (_brandCompanyFilterId != null &&
        !_companies.any((item) => item.id == _brandCompanyFilterId)) {
      _brandCompanyFilterId = null;
    }
  }

  int _companiesFingerprint(List<CatalogCompany> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.name,
        item.initials,
        item.ruc,
        item.phone,
        item.address,
        item.brandCount,
        item.productCount,
        item.active,
      ),
    ),
  );

  int _brandsFingerprint(List<CatalogBrand> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.companyId,
        item.name,
        item.initials,
        item.productCount,
        item.active,
      ),
    ),
  );

  int _categoriesFingerprint(List<CatalogCategory> items) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.parentId,
        item.name,
        item.description,
        item.directProductCount,
        item.includingDescendantProductCount,
        item.active,
      ),
    ),
  );

  int _attributesFingerprint(
    List<CategoryAttributeDefinition> items,
  ) => Object.hashAll(
    items.map(
      (item) => Object.hash(
        item.id,
        item.categoryId,
        item.name,
        item.type,
        Object.hashAll(item.units),
        Object.hashAll(item.options),
        item.required,
        item.filterable,
        item.variantAxis,
        item.multiple,
        item.active,
        item.usedByProductCount,
      ),
    ),
  );

  int _relationsFingerprint(List<BrandCategoryRelation> items) =>
      Object.hashAll(
        items.map(
          (item) => Object.hash(
            item.brandId,
            item.categoryId,
            item.activeProductCount,
          ),
        ),
      );
'''

sync_anchor = "  Map<String, Set<String>> _relationMap("
if structure.count(sync_anchor) != 1:
    fail("No se encontró dónde insertar la sincronización del panel.")
structure = structure.replace(sync_anchor, sync_code + "\n" + sync_anchor, 1)

# ---------------------------------------------------------------------------
# 2. Los controladores de los diálogos no se destruyen durante la animación.
# ---------------------------------------------------------------------------

structure = remove_controller_disposals(
    structure,
    "  Future<void> _showCompanyForm({CatalogCompany? existing}) async {",
    "  Future<void> _showBrandForm({CatalogBrand? existing}) async {",
    "empresa",
)
structure = remove_controller_disposals(
    structure,
    "  Future<void> _showBrandForm({CatalogBrand? existing}) async {",
    "  Future<void> _showCategoryForm({",
    "marca",
)
structure = remove_controller_disposals(
    structure,
    "  Future<void> _showCategoryForm({",
    "  Future<void> _showAttributeForm(",
    "categoría",
)

# ---------------------------------------------------------------------------
# 3. Encabezado adaptable de Gestionar atributos.
# ---------------------------------------------------------------------------

new_header = r'''  Widget _buildHeader() {
    final ownCount = _effectiveAttributes
        .where((item) => !item.inherited)
        .length;
    final inheritedCount = _effectiveAttributes
        .where((item) => item.inherited)
        .length;
    final hasPendingSync = _effectiveAttributes.any(
      (item) => item.syncState == AttributeSyncState.pending,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;

          final heading = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Volver a categorías',
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed:
                    widget.onBack ??
                    () {
                      Navigator.maybePop(context);
                    },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestionar atributos · ${widget.categoryName}',
                      softWrap: true,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Define los datos técnicos que se solicitarán al '
                      'registrar productos de esta categoría.',
                      softWrap: true,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: [
              _SecondaryButton(
                label: 'Vista previa del formulario',
                icon: Icons.visibility_outlined,
                onPressed: _showFormPreview,
              ),
              _PrimaryButton(
                label: 'Nuevo atributo',
                icon: Icons.add_rounded,
                onPressed: _startCreating,
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                heading,
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: actions,
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 20),
                    Flexible(child: actions),
                  ],
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoPill(
                    icon: Icons.account_tree_outlined,
                    label: 'Ruta: ${widget.categoryPath.join(' > ')}',
                  ),
                  _InfoPill(
                    icon: Icons.data_object_rounded,
                    label:
                        '${_effectiveAttributes.length} atributos · '
                        '$ownCount propios · $inheritedCount heredados',
                  ),
                  if (hasPendingSync)
                    const _InfoPill(
                      icon: Icons.cloud_upload_outlined,
                      label:
                          'Guardada localmente · Pendiente de sincronización',
                      background: Color(0xFFFFF4CC),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
'''
manager = replace_between(
    manager,
    "  Widget _buildHeader() {",
    "  Widget _buildListPanel() {",
    new_header,
    "encabezado adaptable de Gestionar atributos",
)

# ---------------------------------------------------------------------------
# 4. ListTile y derivados deben tener un Material inmediato.
# ---------------------------------------------------------------------------

selection_tile = r'''class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? _catalogYellow : _catalogBorder,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: enabled,
          minTileHeight: 58,
          leading: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? const Color(0xFFE7AD00) : _catalogBorder,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _catalogMuted, fontSize: 11),
          ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
'''
structure = replace_class(
    structure,
    "class _SelectionTile extends StatelessWidget {",
    selection_tile,
    "selección de empresa o marca",
)

relation_tile = r'''class _RelationCategoryTile extends StatelessWidget {
  const _RelationCategoryTile({
    required this.category,
    required this.depth,
    required this.checked,
    required this.added,
    required this.removalPending,
    required this.locked,
    required this.productCount,
    required this.brandName,
    required this.onChanged,
    required this.onViewProducts,
  });

  final CatalogCategory category;
  final int depth;
  final bool checked;
  final bool added;
  final bool removalPending;
  final bool locked;
  final int productCount;
  final String brandName;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onViewProducts;

  @override
  Widget build(BuildContext context) {
    final status = added
        ? 'Añadida en esta edición'
        : removalPending
        ? 'Eliminación pendiente'
        : locked
        ? 'Vinculada · $productCount productos activos'
        : checked
        ? 'Ya vinculada'
        : 'Disponible';
    final background = removalPending
        ? _catalogRedSoft
        : added
        ? _catalogGreenSoft
        : checked
        ? const Color(0xFFFFFAE8)
        : Colors.white;
    final borderColor = removalPending
        ? const Color(0xFFF4A6A1)
        : added
        ? const Color(0xFF99D6B7)
        : checked
        ? _catalogYellow
        : _catalogBorder;

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, bottom: 7),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: checked,
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          secondary: locked
              ? IconButton(
                  tooltip: 'Ver productos afectados de $brandName',
                  onPressed: onViewProducts,
                  icon: const Icon(Icons.lock_outline_rounded),
                )
              : null,
          title: Text(
            category.name,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            status,
            style: TextStyle(
              color: removalPending
                  ? _catalogRed
                  : added
                  ? _catalogGreen
                  : _catalogMuted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
'''
structure = replace_class(
    structure,
    "class _RelationCategoryTile extends StatelessWidget {",
    relation_tile,
    "relación entre marca y categoría",
)

editor_switch = r'''class _EditorSwitch extends StatelessWidget {
  const _EditorSwitch({
    required this.title,
    required this.value,
    required this.readOnly,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }
}
'''
manager = replace_class(
    manager,
    "class _EditorSwitch extends StatelessWidget {",
    editor_switch,
    "interruptores del editor de atributos",
)

preview_old = r'''      case CategoryAttributeDataType.yesNo:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: attribute.helpText == null
              ? null
              : Text(attribute.helpText!),
          value: false,
          onChanged: null,
        );
'''
preview_new = r'''      case CategoryAttributeDataType.yesNo:
        return Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: attribute.helpText == null
                ? null
                : Text(attribute.helpText!),
            value: false,
            onChanged: null,
          ),
        );
'''
manager = replace_once(
    manager,
    preview_old,
    preview_new,
    "vista previa del atributo Sí/No",
)

# ---------------------------------------------------------------------------
# 5. Prueba de regresión: crear categoría no reinicia ni rompe el overlay.
# ---------------------------------------------------------------------------

new_test = r'''  testWidgets(
    'crear una categoría conserva la pestaña y no rompe el diálogo',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        RepositoryProvider<EstructuraCatalogoRepository>.value(
          value: _EstructuraRepositoryFake(),
          child: const MaterialApp(home: EstructuraCatalogoPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categorías').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nueva categoría raíz'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('estructura_categoria_nombre')),
        'Categoría temporal',
      );
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva categoría raíz'), findsOneWidget);
      expect(find.text('Nueva empresa'), findsNothing);
      expect(find.text('Categoría temporal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

'''

test_anchor = "  testWidgets('el modo vendedor no presenta acciones administrativas', (\n"
if tests.count(test_anchor) != 1:
    fail("No se encontró dónde insertar la prueba de creación de categorías.")
tests = tests.replace(test_anchor, new_test + test_anchor, 1)

updates = {
    STRUCTURE_PATH: structure,
    MANAGER_PATH: manager,
    INTEGRATED_PATH: integrated,
    TEST_PATH: tests,
}

for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado de {path.relative_to(ROOT)} quedó vacío.")

backup_dir = ROOT / (
    ".backup_estructura_catalogo_estabilidad_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nEncabezado adaptable y estabilidad de categorías corregidos.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
