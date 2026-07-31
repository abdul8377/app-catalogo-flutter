from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

DESIGN_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/widgets/"
    / "estructura_catalogo_corregida.dart"
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


def _matching_brace(source: str, opening: int) -> int:
    depth = 0
    index = opening
    quote: str | None = None
    triple = False
    line_comment = False
    block_comment = 0

    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""

        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue

        if block_comment:
            if char == "/" and next_char == "*":
                block_comment += 1
                index += 2
                continue
            if char == "*" and next_char == "/":
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

        if char == "/" and next_char == "/":
            line_comment = True
            index += 2
            continue
        if char == "/" and next_char == "*":
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


def replace_block(source: str, marker: str, replacement: str, label: str) -> str:
    count = source.count(marker)
    if count != 1:
        fail(
            f"No se pudo localizar “{label}”. "
            f"Se esperaba 1 marcador y se encontraron {count}."
        )
    start = source.index(marker)
    opening = source.find("{", start)
    if opening < 0:
        fail(f"No se encontró la apertura del bloque “{label}”.")
    closing = _matching_brace(source, opening)
    end = closing + 1
    while end < len(source) and source[end] in " \t":
        end += 1
    if end < len(source) and source[end] == "\r":
        end += 1
    if end < len(source) and source[end] == "\n":
        end += 1
    return source[:start] + replacement.rstrip() + "\n" + source[end:]


def remove_member(source: str, marker: str, label: str) -> str:
    count = source.count(marker)
    if count != 1:
        fail(
            f"No se pudo retirar “{label}”. "
            f"Se esperaba 1 marcador y se encontraron {count}."
        )
    start = source.index(marker)
    arrow = source.find("=>", start)
    opening = source.find("{", start)

    if arrow >= 0 and (opening < 0 or arrow < opening):
        index = arrow + 2
        paren = bracket = brace = 0
        quote: str | None = None
        line_comment = False
        block_comment = 0
        while index < len(source):
            char = source[index]
            next_char = source[index + 1] if index + 1 < len(source) else ""
            if line_comment:
                if char == "\n":
                    line_comment = False
                index += 1
                continue
            if block_comment:
                if char == "*" and next_char == "/":
                    block_comment -= 1
                    index += 2
                else:
                    index += 1
                continue
            if quote is not None:
                if char == "\\":
                    index += 2
                    continue
                if char == quote:
                    quote = None
                index += 1
                continue
            if char == "/" and next_char == "/":
                line_comment = True
                index += 2
                continue
            if char == "/" and next_char == "*":
                block_comment += 1
                index += 2
                continue
            if char in ("'", '"'):
                quote = char
                index += 1
                continue
            if char == "(":
                paren += 1
            elif char == ")":
                paren -= 1
            elif char == "[":
                bracket += 1
            elif char == "]":
                bracket -= 1
            elif char == "{":
                brace += 1
            elif char == "}":
                brace -= 1
            elif (
                char == ";"
                and paren == 0
                and bracket == 0
                and brace == 0
            ):
                end = index + 1
                break
            index += 1
        else:
            fail(f"No se encontró el final de “{label}”.")
    else:
        if opening < 0:
            fail(f"No se encontró el cuerpo de “{label}”.")
        end = _matching_brace(source, opening) + 1

    while end < len(source) and source[end] in " \t":
        end += 1
    if end < len(source) and source[end] == "\r":
        end += 1
    if end < len(source) and source[end] == "\n":
        end += 1
    if end < len(source) and source[end] == "\n":
        end += 1
    return source[:start] + source[end:]


for path in (DESIGN_PATH, INTEGRATED_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

design = DESIGN_PATH.read_text(encoding="utf-8")
integrated = INTEGRATED_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

if "class CatalogStructurePanel" not in design:
    fail("No se encontró el panel integrado de estructura del catálogo.")
if "EstructuraCatalogoIntegradaView" not in integrated:
    fail("No se encontró el adaptador integrado del módulo.")

design = replace_once(
    design,
    "    this.onAttributesChanged,\n",
    "",
    "retirar callback simplificado de atributos",
)
design = replace_once(
    design,
    "  final ValueChanged<List<CategoryAttributeDefinition>>? "
    "onAttributesChanged;\n",
    "",
    "retirar propiedad simplificada de atributos",
)
integrated = replace_once(
    integrated,
    "                  onAttributesChanged: (items) =>\n"
    "                      _saveSimpleAttributes(context, snapshot, items),\n",
    "",
    "retirar guardado simplificado de atributos",
)

new_category_tabs = r'''  Widget _buildCategorySectionTabs() {
    return Row(
      children: [
        Expanded(
          child: _sectionTab(
            label: 'Resumen',
            selected: _categorySection == CategoryDetailSection.summary,
            onTap: () {
              setState(() {
                _categorySection = CategoryDetailSection.summary;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _sectionTab(
            label: 'Vista previa de atributos',
            selected: _categorySection == CategoryDetailSection.attributes,
            onTap: () {
              setState(() {
                _categorySection = CategoryDetailSection.attributes;
              });
            },
          ),
        ),
      ],
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildCategorySectionTabs() {",
    new_category_tabs,
    "pestañas del detalle de categoría",
)

new_attribute_preview = r'''  Widget _buildAttributeManager(CatalogCategory category) {
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final callback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('attributes'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _catalogBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Esta es una vista previa. La creación, edición, orden y '
              'configuración avanzada se realizan únicamente en la '
              'subpantalla Gestionar atributos.',
              style: TextStyle(
                color: _catalogText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoPill(label: '$ownCount propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
              _PrimaryButton(
                label: 'Abrir gestión de atributos',
                icon: Icons.tune_rounded,
                onPressed: callback == null
                    ? null
                    : () => callback(category.id),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (effective.isEmpty)
            const _EmptyState(
              title: 'Sin atributos definidos',
              message:
                  'Abre Gestionar atributos para definir los datos técnicos.',
              compact: true,
            )
          else
            ...effective.map(_buildAttributeCard),
        ],
      ),
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildAttributeManager(CatalogCategory category) {",
    new_attribute_preview,
    "vista previa de atributos",
)

new_attribute_card = r'''  Widget _buildAttributeCard(EffectiveCategoryAttribute item) {
    final attribute = item.definition;
    final details = <String>[
      _attributeTypeLabel(attribute.type),
      if (attribute.units.isNotEmpty) attribute.units.join(', '),
      if (attribute.required) 'Obligatorio',
      if (attribute.filterable) 'Filtrable',
      if (attribute.variantAxis) 'Posible eje',
      if (attribute.multiple) 'Selección múltiple',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.inherited ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: _catalogBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            attribute.variantAxis
                ? Icons.grid_view_rounded
                : Icons.data_object_rounded,
            color: attribute.active ? _catalogText : _catalogMuted,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      attribute.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _InfoPill(
                      label: item.inherited
                          ? 'Heredado de ${item.originCategory.name}'
                          : 'Propio de ${item.originCategory.name}',
                      color: item.inherited
                          ? _catalogBlueSoft
                          : const Color(0xFFF1F3F6),
                    ),
                    if (!attribute.active)
                      const _InfoPill(
                        label: 'Inactivo',
                        color: _catalogRedSoft,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.join(' · '),
                  style: const TextStyle(
                    color: _catalogMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (attribute.options.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: attribute.options
                        .take(6)
                        .map((value) => _InfoPill(label: value))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildAttributeCard(EffectiveCategoryAttribute item) {",
    new_attribute_card,
    "tarjeta de atributo de solo lectura",
)

design = remove_member(
    design,
    "  Future<void> _showAttributeForm(",
    "formulario simplificado de atributo",
)
design = remove_member(
    design,
    "  void _toggleAttributeStatus(",
    "cambio simplificado de estado de atributo",
)
design = remove_member(
    design,
    "List<String> _splitValues(",
    "separador usado solo por el formulario simplificado",
)

for marker, label in (
    (
        "  static void _saveSimpleAttributes(",
        "adaptador de guardado simplificado",
    ),
    (
        "  static AtributoCategoriaCatalogo _domainFromSimple(",
        "conversión simplificada de atributo",
    ),
    (
        "  static List<OpcionAtributoCategoriaCatalogo> _optionsFromSimple(",
        "conversión simplificada de opciones",
    ),
    (
        "  static String _domainSimpleType(",
        "conversión simplificada de tipo",
    ),
):
    integrated = remove_member(integrated, marker, label)

design = replace_once(
    design,
    "'Categorías globales con jerarquía, atributos e herencia.'",
    "'Categorías globales de dos niveles, con atributos e herencia.'",
    "descripción canónica de categorías",
)
design = replace_once(
    design,
    "          createLabel: 'Nueva categoría',\n"
    "          onCreate: _showCategoryForm,",
    "          createLabel: 'Nueva categoría raíz',\n"
    "          onCreate: _showCategoryForm,",
    "acción de nueva categoría raíz",
)
design = replace_once(
    design,
    "                    'Jerarquía global',",
    "                    'Categorías y subcategorías',",
    "título del árbol de categorías",
)

new_category_summary = r'''  Widget _buildCategorySummary(CatalogCategory category) {
    final parent = _categoryById(category.parentId);
    final children = _childrenOf(category.id);
    final relatedBrandIds = _savedRelations.entries
        .where((entry) {
          final rootId = category.parentId ?? category.id;
          return entry.value.contains(rootId);
        })
        .map((entry) => entry.key)
        .toSet();
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final attributeCallback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabelValue(
            label: 'Ruta',
            value: parent == null
                ? category.name
                : '${parent.name} > ${category.name}',
          ),
          const SizedBox(height: 14),
          _LabelValue(
            label: 'Tipo',
            value: parent == null ? 'Categoría principal' : 'Subcategoría',
          ),
          if (category.description != null &&
              category.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _LabelValue(label: 'Descripción', value: category.description!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subcategorías',
                  style: TextStyle(color: _catalogMuted, fontSize: 12),
                ),
              ),
              if (category.parentId == null)
                _SecondaryButton(
                  label: 'Añadir subcategoría',
                  icon: Icons.add_rounded,
                  onPressed: category.active
                      ? () => _showCategoryForm(
                          parentId: category.id,
                          createSubcategory: true,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (category.parentId != null)
            Text(
              'Pertenece a ${parent?.name ?? 'una categoría superior'}.',
              style: const TextStyle(color: _catalogMuted),
            )
          else if (children.isEmpty)
            const Text('Sin subcategorías')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children
                  .map(
                    (child) => ActionChip(
                      label: Text(child.name),
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = child.id;
                          _categorySection = CategoryDetailSection.summary;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  value: '${category.directProductCount}',
                  label: 'productos directos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${category.includingDescendantProductCount}',
                  label: 'incluyendo subcategorías',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${relatedBrandIds.length}',
                  label: 'marcas habilitadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: '$ownCount atributos propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showCategoryForm(existing: category),
              ),
              _SecondaryButton(
                label: 'Gestionar atributos',
                icon: Icons.tune_rounded,
                onPressed: attributeCallback == null
                    ? null
                    : () => attributeCallback(category.id),
              ),
              _SecondaryButton(
                label: 'Ver asignaciones',
                icon: Icons.link_rounded,
                onPressed: () {
                  final root = parent ?? category;
                  setState(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _relationCategoryQuery = root.name;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            category.parentId == null
                ? 'Al desactivar esta categoría, sus subcategorías dejarán de '
                      'estar disponibles para nuevos productos, pero conservarán '
                      'su estado y sus datos históricos.'
                : 'La disponibilidad también depende de que la categoría '
                      'superior permanezca activa.',
            style: const TextStyle(
              color: _catalogMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildCategorySummary(CatalogCategory category) {",
    new_category_summary,
    "resumen coherente de categoría",
)

new_append_category_rows = r'''  void _appendCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
  ) {
    final descendants = _descendantsOf(category.id);
    final query = _query.toLowerCase();
    final selfMatchesQuery = category.name.toLowerCase().contains(query);
    final descendantMatchesQuery = descendants.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    final selfMatchesStatus = _matchesStatus(category.active);
    final descendantMatchesStatus = descendants.any(
      (item) => _matchesStatus(item.active),
    );

    if (_query.isNotEmpty &&
        !selfMatchesQuery &&
        !descendantMatchesQuery) {
      return;
    }
    if (_filter != CatalogRecordFilter.all &&
        !selfMatchesStatus &&
        !descendantMatchesStatus) {
      return;
    }

    target.add(
      _CategoryTreeTile(
        category: category,
        depth: depth,
        selected: category.id == _selectedCategoryId,
        hasChildren: _childrenOf(category.id).isNotEmpty,
        onTap: () => setState(() {
          _selectedCategoryId = category.id;
          _categorySection = CategoryDetailSection.summary;
        }),
        onEdit: () => _showCategoryForm(existing: category),
        onAddChild: category.parentId == null && category.active
            ? () => _showCategoryForm(
                parentId: category.id,
                createSubcategory: true,
              )
            : null,
        onToggleStatus: () => _confirmCategoryStatusChange(category),
      ),
    );

    for (final child in _childrenOf(category.id)) {
      _appendCategoryRows(target, child, depth + 1);
    }
  }
'''
design = replace_block(
    design,
    "  void _appendCategoryRows(",
    new_append_category_rows,
    "construcción del árbol de categorías",
)

new_category_form = r'''  Future<void> _showCategoryForm({
    CatalogCategory? existing,
    String? parentId,
    bool createSubcategory = false,
  }) async {
    final isExistingChild = existing?.parentId != null;
    final isSubcategory = createSubcategory || isExistingChild;
    var selectedParentId = existing?.parentId ?? parentId;

    if (isSubcategory && selectedParentId == null) {
      _showMessage(
        'Selecciona primero una categoría principal.',
        error: true,
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    final activeRoots = _categories
        .where(
          (item) =>
              item.parentId == null &&
              (item.active || item.id == selectedParentId),
        )
        .toList();

    final title = existing == null
        ? isSubcategory
              ? 'Nueva subcategoría'
              : 'Nueva categoría raíz'
        : isExistingChild
        ? 'Editar subcategoría'
        : 'Editar categoría raíz';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSubcategory)
                          DropdownButtonFormField<String>(
                            initialValue: selectedParentId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoría superior *',
                              helperText:
                                  'La subcategoría heredará sus atributos.',
                            ),
                            items: activeRoots
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            validator: (value) => value == null
                                ? 'Selecciona una categoría superior.'
                                : null,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedParentId = value;
                              });
                            },
                          )
                        else
                          const InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Nivel',
                            ),
                            child: Text('Categoría principal'),
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('estructura_categoria_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: isSubcategory
                                ? 'Nombre de la subcategoría *'
                                : 'Nombre de la categoría *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final effectiveParent = isSubcategory
                                ? selectedParentId
                                : null;
                            final duplicate = _categories.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.parentId == effectiveParent &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'Ya existe un registro con ese nombre '
                                      'en el mismo nivel.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _catalogBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSubcategory
                                ? 'Las marcas se relacionan con la categoría '
                                      'principal. Esta subcategoría quedará '
                                      'disponible automáticamente.'
                                : 'Después podrás añadir subcategorías y '
                                      'gestionar los atributos técnicos.',
                            style: const TextStyle(
                              color: _catalogText,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(existing == null ? 'Crear' : 'Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final savedName = nameController.text.trim();
    final savedDescription = _emptyToNull(descriptionController.text);
    nameController.dispose();
    descriptionController.dispose();

    setState(() {
      if (existing == null) {
        final created = CatalogCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          parentId: isSubcategory ? selectedParentId : null,
          name: savedName,
          description: savedDescription,
          directProductCount: 0,
          includingDescendantProductCount: 0,
          active: true,
        );
        _categories.add(created);
        _selectedCategoryId = created.id;
      } else {
        final index = _categories.indexWhere(
          (item) => item.id == existing.id,
        );
        _categories[index] = existing.copyWith(
          parentId: isExistingChild ? selectedParentId : null,
          clearParent: !isExistingChild,
          name: savedName,
          description: savedDescription,
          active: existing.active,
        );
        _selectedCategoryId = existing.id;
      }
      _categorySection = CategoryDetailSection.summary;
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }
'''
design = replace_block(
    design,
    "  Future<void> _showCategoryForm(",
    new_category_form,
    "formulario explícito de categoría y subcategoría",
)

new_category_status = r'''  Future<void> _confirmCategoryStatusChange(
    CatalogCategory category,
  ) async {
    if (category.active) {
      final descendants = _descendantsOf(category.id);
      final confirmed = await _confirm(
        title: category.parentId == null
            ? 'Desactivar categoría'
            : 'Desactivar subcategoría',
        message: category.parentId == null
            ? 'La categoría dejará de estar disponible para nuevos productos. '
                  'Sus ${descendants.length} subcategorías quedarán bloqueadas '
                  'por dependencia, pero conservarán su estado y el historial.'
            : 'La subcategoría dejará de estar disponible para nuevos '
                  'productos. El historial se conservará.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    } else {
      final parent = _categoryById(category.parentId);
      if (parent != null && !parent.active) {
        _showMessage(
          'Primero activa la categoría superior ${parent.name}.',
          error: true,
        );
        return;
      }
    }

    setState(() {
      final index = _categories.indexWhere(
        (item) => item.id == category.id,
      );
      _categories[index] = category.copyWith(active: !category.active);
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }
'''
design = replace_block(
    design,
    "  Future<void> _confirmCategoryStatusChange(",
    new_category_status,
    "cambio coherente de estado de categoría",
)

new_tree_tile = r'''class _CategoryTreeTile extends StatelessWidget {
  const _CategoryTreeTile({
    required this.category,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    this.onAddChild,
  });

  final CatalogCategory category;
  final int depth;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onAddChild;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        border: Border.all(
          color: selected ? _catalogYellow : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            children: [
              SizedBox(width: 12 + depth * 22),
              Icon(
                hasChildren
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.subdirectory_arrow_right_rounded,
                size: 18,
                color: _catalogMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: category.active
                        ? _catalogText
                        : _catalogMuted,
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${category.includingDescendantProductCount} prod.',
                style: const TextStyle(
                  color: _catalogMuted,
                  fontSize: 12,
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones para ${category.name}',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'add_child') onAddChild?.call();
                  if (value == 'status') onToggleStatus();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  if (onAddChild != null)
                    const PopupMenuItem(
                      value: 'add_child',
                      child: Text('Añadir subcategoría'),
                    ),
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      category.active ? 'Desactivar' : 'Activar',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'''
design = replace_block(
    design,
    "class _CategoryTreeTile extends StatelessWidget {",
    new_tree_tile,
    "acciones del árbol de categorías",
)

new_company_card = r'''  Widget _buildCompanyCard(CatalogCompany company) {
    final companyBrands = _brands
        .where((brand) => brand.companyId == company.id)
        .toList();
    final categoryIds = <String>{};
    for (final brand in companyBrands) {
      categoryIds.addAll(_savedRelations[brand.id] ?? const <String>{});
    }

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(
                initials: company.initials,
                color: _catalogYellow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (company.ruc != null &&
                        company.ruc!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'RUC ${company.ruc}',
                        style: const TextStyle(
                          color: _catalogMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(active: company.active),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Marcas',
                  value: '${companyBrands.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Categorías vía marcas',
                  value: '${categoryIds.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Productos totales',
                  value: '${company.productCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showCompanyForm(existing: company),
              ),
              _SecondaryButton(
                label: 'Ver marcas',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  setState(() {
                    _tab = CatalogStructureTab.brands;
                    _selectedCompanyId = company.id;
                    _query = '';
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${company.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmCompanyStatusChange(company);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      company.active
                          ? 'Desactivar empresa'
                          : 'Activar empresa',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildCompanyCard(CatalogCompany company) {",
    new_company_card,
    "tarjeta de empresa",
)

new_brand_card = r'''  Widget _buildBrandCard(CatalogBrand brand) {
    final company = _companyById(brand.companyId);
    final relationIds = _savedRelations[brand.id] ?? const <String>{};
    final related = _categories
        .where(
          (category) =>
              category.parentId == null &&
              relationIds.contains(category.id),
        )
        .toList();

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(
                initials: brand.initials,
                color: const Color(0xFF2F66EB),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Empresa: ${company?.name ?? 'Sin empresa'}',
                      style: const TextStyle(
                        color: _catalogMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(active: brand.active),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Categorías principales habilitadas',
            style: TextStyle(color: _catalogMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (related.isEmpty)
            const Text(
              'Sin categorías habilitadas',
              style: TextStyle(color: _catalogMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...related
                    .take(3)
                    .map((category) => _InfoPill(label: category.name)),
                if (related.length > 3)
                  _InfoPill(label: '+${related.length - 3}'),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            '${brand.productCount} productos totales',
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showBrandForm(existing: brand),
              ),
              _SecondaryButton(
                label: 'Administrar categorías',
                icon: Icons.account_tree_outlined,
                onPressed: () {
                  setState(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _selectedCompanyId = brand.companyId;
                    _selectedBrandId = brand.id;
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${brand.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmBrandStatusChange(brand);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      brand.active
                          ? 'Desactivar marca'
                          : 'Activar marca',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildBrandCard(CatalogBrand brand) {",
    new_brand_card,
    "tarjeta de marca",
)

new_company_form = r'''  Future<void> _showCompanyForm({CatalogCompany? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final rucController = TextEditingController(text: existing?.ruc);
    final phoneController = TextEditingController(text: existing?.phone);
    final addressController = TextEditingController(text: existing?.address);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existing == null ? 'Nueva empresa' : 'Editar empresa',
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      key: const Key('estructura_empresa_nombre'),
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        final duplicate = _companies.any(
                          (item) =>
                              item.id != existing?.id &&
                              item.name.trim().toLowerCase() ==
                                  name.toLowerCase(),
                        );
                        return duplicate
                            ? 'Ya existe una empresa con ese nombre.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: rucController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RUC (opcional)',
                      ),
                      validator: (value) {
                        final ruc = value?.trim() ?? '';
                        if (ruc.isEmpty) return null;
                        return RegExp(r'^\d{11}$').hasMatch(ruc)
                            ? null
                            : 'El RUC debe contener 11 dígitos.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'El estado se administra desde las acciones de la '
                      'empresa para mostrar antes el impacto.',
                      style: TextStyle(
                        color: _catalogMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      rucController.dispose();
      phoneController.dispose();
      addressController.dispose();
      return;
    }

    final name = nameController.text.trim();
    final ruc = _emptyToNull(rucController.text);
    final phone = _emptyToNull(phoneController.text);
    final address = _emptyToNull(addressController.text);
    nameController.dispose();
    rucController.dispose();
    phoneController.dispose();
    addressController.dispose();

    setState(() {
      if (existing == null) {
        _companies.add(
          CatalogCompany(
            id: 'company-${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            initials: _initialsFor(name),
            ruc: ruc,
            phone: phone,
            address: address,
            brandCount: 0,
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _companies.indexWhere(
          (item) => item.id == existing.id,
        );
        _companies[index] = existing.copyWith(
          name: name,
          initials: _initialsFor(name),
          ruc: ruc,
          phone: phone,
          address: address,
          active: existing.active,
        );
      }
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }
'''
design = replace_block(
    design,
    "  Future<void> _showCompanyForm({CatalogCompany? existing}) async {",
    new_company_form,
    "formulario de empresa",
)

new_brand_form = r'''  Future<void> _showBrandForm({CatalogBrand? existing}) async {
    final availableCompanies = _companies
        .where(
          (company) =>
              company.active || company.id == existing?.companyId,
        )
        .toList();
    if (availableCompanies.isEmpty) {
      _showMessage('Primero registra una empresa activa.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    var companyId =
        existing?.companyId ??
        _selectedCompanyId ??
        availableCompanies.first.id;
    final ownerLocked = existing != null && existing.productCount > 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nueva marca' : 'Editar marca',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: companyId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Empresa propietaria *',
                          ),
                          items: availableCompanies
                              .map(
                                (company) => DropdownMenuItem(
                                  value: company.id,
                                  child: Text(company.name),
                                ),
                              )
                              .toList(),
                          validator: (value) => value == null
                              ? 'Selecciona una empresa.'
                              : null,
                          onChanged: ownerLocked
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setDialogState(() => companyId = value);
                                },
                        ),
                        if (ownerLocked) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _catalogBlueSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'La empresa propietaria no puede cambiarse '
                              'porque esta marca tiene '
                              '${existing!.productCount} productos.',
                              style: const TextStyle(
                                color: _catalogText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const Key('estructura_marca_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final duplicate = _brands.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.companyId == companyId &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'La empresa ya tiene una marca con ese nombre.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Las categorías de la marca se administran en '
                          'Categorías por marca.',
                          style: TextStyle(
                            color: _catalogMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      return;
    }

    final name = nameController.text.trim();
    nameController.dispose();

    setState(() {
      if (existing == null) {
        _brands.add(
          CatalogBrand(
            id: 'brand-${DateTime.now().microsecondsSinceEpoch}',
            companyId: companyId,
            name: name,
            initials: _initialsFor(name),
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _brands.indexWhere(
          (item) => item.id == existing.id,
        );
        _brands[index] = existing.copyWith(
          companyId: companyId,
          name: name,
          initials: _initialsFor(name),
          active: existing.active,
        );
      }
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }
'''
design = replace_block(
    design,
    "  Future<void> _showBrandForm({CatalogBrand? existing}) async {",
    new_brand_form,
    "formulario de marca",
)

new_brand_status = r'''  Future<void> _confirmBrandStatusChange(
    CatalogBrand brand,
  ) async {
    final company = _companyById(brand.companyId);
    if (!brand.active && (company == null || !company.active)) {
      _showMessage(
        'Activa primero la empresa propietaria.',
        error: true,
      );
      return;
    }

    if (brand.active) {
      final confirmed = await _confirm(
        title: 'Desactivar marca',
        message:
            'La marca dejará de estar disponible para nuevos productos. '
            'Sus ${brand.productCount} productos conservarán su clasificación '
            'y el historial.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    }

    setState(() {
      final index = _brands.indexWhere((item) => item.id == brand.id);
      _brands[index] = brand.copyWith(active: !brand.active);
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }

'''
brand_status_marker = "  Future<void> _confirmCategoryStatusChange("
if design.count(brand_status_marker) != 1:
    fail("No se encontró dónde insertar el cambio de estado de marca.")
insert_at = design.index(brand_status_marker)
design = design[:insert_at] + new_brand_status + design[insert_at:]

design = replace_once(
    design,
    "  bool _includeChildrenWhenSelecting = false;\n",
    "",
    "retirar selección opcional de descendientes",
)

new_relation_map = r'''  Map<String, Set<String>> _relationMap(
    List<BrandCategoryRelation> source,
  ) {
    final rootIds = _categories
        .where((category) => category.parentId == null)
        .map((category) => category.id)
        .toSet();
    final result = <String, Set<String>>{};
    for (final relation in source) {
      if (!rootIds.contains(relation.categoryId)) continue;
      result.putIfAbsent(relation.brandId, () => <String>{});
      result[relation.brandId]!.add(relation.categoryId);
    }
    return result;
  }
'''
design = replace_block(
    design,
    "  Map<String, Set<String>> _relationMap(",
    new_relation_map,
    "normalización de relaciones principales",
)

new_brand_categories = r'''  Widget _buildBrandCategories(double width) {
    final compact = width < 920;
    final companyPanel = _relationCompanyPanel();
    final brandPanel = _relationBrandPanel();
    final categoryPanel = _relationCategoryPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecciona de izquierda a derecha',
          style: TextStyle(
            color: _catalogText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'La relación se guarda con categorías principales. '
          'Sus subcategorías quedan disponibles automáticamente.',
          style: TextStyle(color: _catalogMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            children: [
              companyPanel,
              const SizedBox(height: 12),
              brandPanel,
              const SizedBox(height: 12),
              categoryPanel,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: companyPanel),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: brandPanel),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: categoryPanel),
            ],
          ),
        const SizedBox(height: 16),
        _relationSaveBar(),
      ],
    );
  }
'''
design = replace_block(
    design,
    "  Widget _buildBrandCategories(double width) {",
    new_brand_categories,
    "explicación de categorías por marca",
)

new_relation_category_panel = r'''  Widget _relationCategoryPanel() {
    final brand = _selectedBrand;
    if (brand == null) {
      return const _SelectionPanel(
        title: '3 · Categorías principales',
        children: [
          _EmptyState(
            title: 'Selecciona una marca',
            message: 'Luego podrás editar sus categorías.',
            compact: true,
          ),
        ],
      );
    }

    final rows = <Widget>[];
    for (final root in _categories.where((item) => item.parentId == null)) {
      _appendRelationCategoryRows(rows, root, 0, brand);
    }

    return _SelectionPanel(
      title: '3 · Categorías principales',
      header: TextFormField(
        onChanged: (value) {
          setState(() => _relationCategoryQuery = value);
        },
        initialValue: _relationCategoryQuery,
        decoration: const InputDecoration(
          hintText: 'Buscar categoría o subcategoría',
          prefixIcon: Icon(Icons.search_rounded),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      children: rows,
    );
  }
'''
design = replace_block(
    design,
    "  Widget _relationCategoryPanel() {",
    new_relation_category_panel,
    "panel de categorías principales por marca",
)

new_append_relation_rows = r'''  void _appendRelationCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
    CatalogBrand brand,
  ) {
    if (category.parentId != null) return;

    final children = _childrenOf(category.id);
    final query = _relationCategoryQuery.toLowerCase();
    final selfMatches = category.name.toLowerCase().contains(query);
    final childMatches = children.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    if (_relationCategoryQuery.isNotEmpty &&
        !selfMatches &&
        !childMatches) {
      return;
    }

    final saved = _savedRelations[brand.id] ?? const <String>{};
    final working = _workingRelations[brand.id] ?? const <String>{};
    final checked = working.contains(category.id);
    final wasSaved = saved.contains(category.id);
    final relation = _relationFor(brand.id, category.id);
    final locked = relation?.isLocked ?? false;
    final added = checked && !wasSaved;
    final removalPending = !checked && wasSaved;

    target.add(
      _RelationCategoryTile(
        category: category,
        depth: 0,
        checked: checked,
        added: added,
        removalPending: removalPending,
        locked: locked,
        productCount: relation?.activeProductCount ?? 0,
        brandName: brand.name,
        onChanged: category.active
            ? (value) => _changeRelation(
                brand: brand,
                category: category,
                selected: value,
              )
            : null,
        onViewProducts: locked
            ? () => _showMessage(
                '${relation!.activeProductCount} productos activos de '
                '${brand.name} usan ${category.name}.',
              )
            : null,
      ),
    );

    if (children.isNotEmpty) {
      target.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(42, 0, 8, 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Incluye:',
                style: TextStyle(
                  color: _catalogMuted,
                  fontSize: 11,
                ),
              ),
              ...children.map(
                (child) => _InfoPill(
                  label: child.name,
                  color: child.active
                      ? const Color(0xFFF1F3F6)
                      : _catalogRedSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
'''
design = replace_block(
    design,
    "  void _appendRelationCategoryRows(",
    new_append_relation_rows,
    "filas de relación por categoría principal",
)

new_change_relation = r'''  void _changeRelation({
    required CatalogBrand brand,
    required CatalogCategory category,
    required bool selected,
  }) {
    if (category.parentId != null) {
      _showMessage(
        'Las subcategorías se habilitan mediante su categoría principal.',
        error: true,
      );
      return;
    }

    final relation = _relationFor(brand.id, category.id);
    if (!selected && (relation?.isLocked ?? false)) {
      _showMessage(
        'No puede retirarse: ${relation!.activeProductCount} productos activos '
        'usan esta relación.',
        error: true,
      );
      return;
    }

    setState(() {
      final working = _workingRelations.putIfAbsent(
        brand.id,
        () => <String>{},
      );
      if (selected) {
        working.add(category.id);
      } else {
        working.remove(category.id);
      }
    });
  }
'''
design = replace_block(
    design,
    "  void _changeRelation({",
    new_change_relation,
    "cambio de relación principal",
)

design = replace_once(
    design,
    "'$count categorías habilitadas'",
    "'$count categorías principales habilitadas'",
    "contador de relaciones de marca",
)
design = replace_once(
    design,
    "'${working.length} categorías seleccionadas · Sin cambios'",
    "'${working.length} categorías principales · Sin cambios'",
    "resumen sin cambios de relaciones",
)

tests = replace_once(
    tests,
    "    await tester.tap(find.text('Ver').first);\n"
    "    await tester.pumpAndSettle();\n"
    "    expect(find.text('Detalle de DINAFAST'), findsOneWidget);\n",
    "    await tester.tap(find.text('Ver marcas').first);\n"
    "    await tester.pumpAndSettle();\n"
    "    expect(find.text('DINA'), findsOneWidget);\n",
    "prueba sin botón Ver ficticio",
)
tests = replace_once(
    tests,
    "    expect(find.text('Nuevo atributo'), findsOneWidget);\n",
    "    expect(find.text('Nuevo atributo'), findsOneWidget);\n"
    "    expect(find.text('Agregar atributo'), findsNothing);\n",
    "prueba de fuente única de atributos",
)

updates = {
    DESIGN_PATH: design,
    INTEGRATED_PATH: integrated,
    TEST_PATH: tests,
}

for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado para {path.relative_to(ROOT)} quedó vacío.")

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_estructura_catalogo_fase1_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nFase 1 de coherencia del módulo aplicada.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
