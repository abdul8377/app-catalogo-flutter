from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()
PATHS = {
    'sales_draft': ROOT / 'lib/features/catalogo/presentation/widgets/paso4_venta_logistica_contenido.dart',
    'sales_adapter': ROOT / 'lib/features/catalogo/presentation/widgets/producto_venta_logistica_step.dart',
    'prices_adapter': ROOT / 'lib/features/catalogo/presentation/widgets/producto_precios_step.dart',
    'prices': ROOT / 'lib/features/catalogo/presentation/widgets/paso5_precios_corregido.dart',
    'review_adapter': ROOT / 'lib/features/catalogo/presentation/widgets/producto_revision_step.dart',
    'review': ROOT / 'lib/features/catalogo/presentation/widgets/paso7_revisar_activar_corregido.dart',
    'legacy_test': ROOT / 'test/producto_form_page_test.dart',
}
TEST_PATH = ROOT / 'test/reglas_comerciales_producto_test.dart'


def fail(message: str) -> None:
    raise SystemExit(f'\nERROR: {message}\nNo se escribió ningún archivo.')


def read(path: Path) -> str:
    if not path.exists():
        fail(f'No se encontró {path}')
    return path.read_text(encoding='utf-8')


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        fail(f'No se pudo aplicar “{label}”. Se esperaba 1 coincidencia y se encontraron {count}.')
    return content.replace(old, new, 1)


def regex_once(content: str, pattern: str, replacement: str, label: str, flags: int = re.DOTALL) -> str:
    try:
        updated, count = re.subn(pattern, replacement, content, count=1, flags=flags)
    except re.error as error:
        fail(f'El patrón de “{label}” es inválido: {error}')
    if count != 1:
        fail(f'No se pudo aplicar “{label}”. Se esperaba 1 bloque compatible y se encontraron {count}.')
    return updated


def _matching_brace(content: str, opening_index: int) -> int:
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    index = opening_index
    while index < len(content):
        char = content[index]
        nxt = content[index + 1] if index + 1 < len(content) else ''
        if line_comment:
            if char == '\n': line_comment = False
            index += 1
            continue
        if block_comment:
            if char == '*' and nxt == '/':
                block_comment = False
                index += 2
                continue
            index += 1
            continue
        if quote is not None:
            if escaped: escaped = False
            elif char == '\\': escaped = True
            elif char == quote: quote = None
            index += 1
            continue
        if char == '/' and nxt == '/':
            line_comment = True
            index += 2
            continue
        if char == '/' and nxt == '*':
            block_comment = True
            index += 2
            continue
        if char in {'\'', '"'}:
            quote = char
            index += 1
            continue
        if char == '{': depth += 1
        elif char == '}':
            depth -= 1
            if depth == 0: return index
        index += 1
    return -1


def replace_dart_block(content: str, marker: str, replacement: str, label: str) -> str:
    start = content.find(marker)
    if start < 0: fail(f'No se encontró el inicio de “{label}”.')
    brace = content.find('{', start + len(marker))
    if brace < 0: fail(f'No se encontró la llave de “{label}”.')
    end = _matching_brace(content, brace)
    if end < 0: fail(f'No se pudo determinar el final de “{label}”.')
    return content[:start] + replacement + content[end + 1:]


contents = {name: read(path) for name, path in PATHS.items()}
if 'No hay variantes vendibles' not in contents['sales_adapter']:
    fail('Primero aplica la fase 4A de coherencia del flujo.')
if TEST_PATH.exists():
    fail('La fase 4B ya parece estar aplicada.')

# ---------------------------------------------------------------------------
# Reglas comerciales por variante en una misma presentación.
# ---------------------------------------------------------------------------
sales = contents['sales_draft']
rule_class = r'''@immutable
class SalesPresentationVariantRule {
  const SalesPresentationVariantRule({
    required this.variantId,
    required this.equivalentTo,
    required this.minimumOrder,
    required this.purchaseIncrement,
  });

  final String variantId;
  final double equivalentTo;
  final double minimumOrder;
  final double purchaseIncrement;
}

'''
sales = replace_once(
    sales,
    '@immutable\nclass SalesPresentationDraft {',
    rule_class + '@immutable\nclass SalesPresentationDraft {',
    'modelo de regla comercial por variante',
)
sales = replace_once(
    sales,
    '    required this.defaultVariantIds,\n    this.linkedLogisticsPackageId,',
    '    required this.defaultVariantIds,\n    this.variantRules = const {},\n    this.linkedLogisticsPackageId,',
    'reglas en constructor de presentación',
)
sales = replace_once(
    sales,
    '  final Set<String> defaultVariantIds;\n\n  /// Se informa cuando nació desde un empaque logístico.',
    "  final Set<String> defaultVariantIds;\n\n  /// Excepciones de equivalencia, mínimo e incremento por variante.\n  final Map<String, SalesPresentationVariantRule> variantRules;\n\n  SalesPresentationVariantRule ruleFor(String variantId) =>\n      variantRules[variantId] ??\n      SalesPresentationVariantRule(\n        variantId: variantId,\n        equivalentTo: equivalentTo,\n        minimumOrder: minimumOrder,\n        purchaseIncrement: purchaseIncrement,\n      );\n\n  /// Se informa cuando nació desde un empaque logístico.",
    'campo y resolución de reglas',
)
sales = replace_once(
    sales,
    '    Set<String>? defaultVariantIds,\n    String? linkedLogisticsPackageId,',
    '    Set<String>? defaultVariantIds,\n    Map<String, SalesPresentationVariantRule>? variantRules,\n    String? linkedLogisticsPackageId,',
    'copyWith de reglas',
)
sales = replace_once(
    sales,
    '      defaultVariantIds: defaultVariantIds ?? this.defaultVariantIds,\n      linkedLogisticsPackageId:',
    '      defaultVariantIds: defaultVariantIds ?? this.defaultVariantIds,\n      variantRules: variantRules ?? this.variantRules,\n      linkedLogisticsPackageId:',
    'conservar reglas en copyWith',
)
sales = replace_once(
    sales,
    '  Set<String> _presentationVariantIds = <String>{};\n',
    '  Set<String> _presentationVariantIds = <String>{};\n  Map<String, SalesPresentationVariantRule> _presentationVariantRules = {};\n',
    'estado de reglas del editor',
)
sales = replace_once(
    sales,
    '    _presentationVariantIds = {..._allVariantIds};\n\n    if (rebuild && mounted)',
    '    _presentationVariantIds = {..._allVariantIds};\n    _presentationVariantRules = {};\n\n    if (rebuild && mounted)',
    'reiniciar reglas al crear presentación',
)
sales = replace_once(
    sales,
    '    _presentationVariantIds = {...presentation.assignedVariantIds};\n    _presentationForAllVariants =',
    '    _presentationVariantIds = {...presentation.assignedVariantIds};\n    _presentationVariantRules = {...presentation.variantRules};\n    _presentationForAllVariants =',
    'cargar reglas de presentación',
)
sales = regex_once(
    sales,
    r'''(final saved = SalesPresentationDraft\(
.*?
[ \t]*defaultVariantIds:[ \t]*[^,\n]+,
)([ \t]*linkedLogisticsPackageId:)''',
    r'''\1      variantRules: {
        for (final entry in _presentationVariantRules.entries)
          if (assignedIds.contains(entry.key)) entry.key: entry.value,
      },
\2''',
    'guardar reglas por variante',
)
# Botón en el editor inmediatamente después del alcance.
sales = replace_once(
    sales,
    "            _buildScopeEditor(\n              title: 'Disponible para',",
    "            _buildScopeEditor(\n              title: 'Disponible para',",
    'validar editor de alcance',
)
anchor = "            const SizedBox(height: 20),\n            LayoutBuilder(\n              builder: (context, constraints) {\n                final cancelButton"
overrides_button = r'''            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('reglas_presentacion_por_variante'),
              onPressed: _presentationVariantIds.isEmpty
                  ? null
                  : _editPresentationVariantRules,
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                'Excepciones por variante '
                '(${_presentationVariantRules.length})',
              ),
              style: _outlinedButtonStyle(),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cancelButton'''
sales = replace_once(sales, anchor, overrides_button, 'botón de reglas por variante')
method_anchor = '  void _savePresentation() {'
override_method = r'''  Future<void> _editPresentationVariantRules() async {
    final inheritedEquivalent =
        _parsePositive(_presentationEquivalentController.text) ?? 1;
    final inheritedMinimum =
        _parsePositive(_presentationMinimumController.text) ?? 1;
    final inheritedIncrement =
        _parsePositive(_presentationIncrementController.text) ?? 1;
    final variants = widget.variants
        .where((variant) => _presentationVariantIds.contains(variant.id))
        .toList();
    final controllers = <String, List<TextEditingController>>{};
    for (final variant in variants) {
      final rule = _presentationVariantRules[variant.id];
      controllers[variant.id] = [
        TextEditingController(
          text: _step4PlainNumber(rule?.equivalentTo ?? inheritedEquivalent),
        ),
        TextEditingController(
          text: _step4PlainNumber(rule?.minimumOrder ?? inheritedMinimum),
        ),
        TextEditingController(
          text: _step4PlainNumber(rule?.purchaseIncrement ?? inheritedIncrement),
        ),
      ];
    }

    final result = await showDialog<Map<String, SalesPresentationVariantRule>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reglas comerciales por variante'),
        content: SizedBox(
          width: 760,
          height: 460,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Solo cambia las filas que difieren de los valores generales. '
                'Esto evita duplicar presentaciones por cada medida.',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: variants.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final variant = variants[index];
                    final fields = controllers[variant.id]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.label,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: fields[0],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration(hint: 'Equivale a'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: fields[1],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration(hint: 'Pedido mínimo'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: fields[2],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration(hint: 'Incremento'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final rules = <String, SalesPresentationVariantRule>{};
              for (final variant in variants) {
                final fields = controllers[variant.id]!;
                final equivalent = _parsePositive(fields[0].text);
                final minimum = _parsePositive(fields[1].text);
                final increment = _parsePositive(fields[2].text);
                if (equivalent == null || minimum == null || increment == null) {
                  _showMessage(
                    'Todos los valores deben ser mayores que cero.',
                    error: true,
                  );
                  return;
                }
                final differs =
                    equivalent != inheritedEquivalent ||
                    minimum != inheritedMinimum ||
                    increment != inheritedIncrement;
                if (differs) {
                  rules[variant.id] = SalesPresentationVariantRule(
                    variantId: variant.id,
                    equivalentTo: equivalent,
                    minimumOrder: minimum,
                    purchaseIncrement: increment,
                  );
                }
              }
              Navigator.pop(dialogContext, rules);
            },
            child: const Text('Aplicar excepciones'),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final fields in controllers.values) {
        for (final controller in fields) {
          controller.dispose();
        }
      }
    });
    if (result == null || !mounted) return;
    setState(() => _presentationVariantRules = result);
  }

'''
sales = replace_once(sales, method_anchor, override_method + method_anchor, 'editor de reglas por variante')
# Serialización.
sales = replace_once(
    sales,
    "        'default_variant_ids': item.defaultVariantIds.toList(),\n        'linked_logistics_package_id':",
    "        'default_variant_ids': item.defaultVariantIds.toList(),\n        'variant_rules': item.variantRules.values.map((rule) {\n          return {\n            'variant_id': rule.variantId,\n            'equivalent_to': rule.equivalentTo,\n            'minimum_order': rule.minimumOrder,\n            'purchase_increment': rule.purchaseIncrement,\n          };\n        }).toList(),\n        'linked_logistics_package_id':",
    'serializar reglas por variante',
)
sales = replace_once(
    sales,
    "          defaultVariantIds: stringSet(item['default_variant_ids']),\n          linkedLogisticsPackageId:",
    "          defaultVariantIds: stringSet(item['default_variant_ids']),\n          variantRules: {\n            for (final rawRule\n                in (item['variant_rules'] as List? ?? const []).whereType<Map>())\n              if (rawRule['variant_id'] != null)\n                rawRule['variant_id'].toString():\n                    SalesPresentationVariantRule(\n                      variantId: rawRule['variant_id'].toString(),\n                      equivalentTo:\n                          (rawRule['equivalent_to'] as num?)?.toDouble() ?? 1,\n                      minimumOrder:\n                          (rawRule['minimum_order'] as num?)?.toDouble() ?? 1,\n                      purchaseIncrement:\n                          (rawRule['purchase_increment'] as num?)?.toDouble() ?? 1,\n                    ),\n          },\n          linkedLogisticsPackageId:",
    'restaurar reglas por variante',
)
contents['sales_draft'] = sales

# Precio exacto usa la regla resuelta de la variante.
prices_adapter = contents['prices_adapter']
prices_adapter = replace_once(
    prices_adapter,
    "        return SellablePriceCombination(\n          variantId: variant.id,",
    "        final rule = presentation.ruleFor(variant.id);\n        return SellablePriceCombination(\n          variantId: variant.id,",
    'resolver regla comercial por variante',
)
prices_adapter = replace_once(
    prices_adapter,
    '          equivalentToBaseUnit: presentation.equivalentTo,\n          minimumOrder: presentation.minimumOrder,\n          purchaseIncrement: presentation.purchaseIncrement,',
    '          equivalentToBaseUnit: rule.equivalentTo,\n          minimumOrder: rule.minimumOrder,\n          purchaseIncrement: rule.purchaseIncrement,',
    'pasar excepciones al precio',
)
contents['prices_adapter'] = prices_adapter

# ---------------------------------------------------------------------------
# Listas de precios: selección de listas administradas, no edición por producto.
# ---------------------------------------------------------------------------
prices = contents['prices']
prices = replace_once(
    prices,
    "              currencyCode: 'USD',",
    "              currencyCode: 'PEN',",
    'moneda predeterminada coherente',
)
# Catálogo central disponible dentro del módulo hasta conectarlo a administración.
prices = replace_once(
    prices,
    '  late List<PriceListDraft> _lists;\n  late List<ProductPriceDraft> _prices;',
    r'''  late List<PriceListDraft> _lists;
  late List<ProductPriceDraft> _prices;

  List<PriceListDraft> get _catalogPriceLists => [
    PriceListDraft(
      id: 'regular',
      name: 'Regular',
      currencyCode: 'PEN',
      includesIgv: true,
      validFrom: DateTime(2020),
    ),
    PriceListDraft(
      id: 'mayorista',
      name: 'Mayorista',
      currencyCode: 'PEN',
      includesIgv: true,
      validFrom: DateTime(2020),
    ),
    PriceListDraft(
      id: 'exportacion',
      name: 'Exportación',
      currencyCode: 'USD',
      includesIgv: false,
      validFrom: DateTime(2020),
    ),
  ];''',
    'catálogo de listas administradas',
)
# Sustituye botones editar/nueva por seleccionar listas.
prices = replace_once(
    prices,
    """              OutlinedButton(
                onPressed: _editSelectedList,
                style: _outlinedStyle(),
                child: const Text('Editar lista'),
              ),
              OutlinedButton.icon(
                onPressed: _createPriceList,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva lista'),
                style: _outlinedStyle(),
              ),""",
    """              OutlinedButton.icon(
                key: const Key('seleccionar_listas_precios'),
                onPressed: _selectPriceLists,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Seleccionar listas'),
                style: _outlinedStyle(),
              ),""",
    'eliminar edición de listas dentro del producto',
)
select_method_anchor = '  Future<void> _editSelectedList() async {'
select_method = r'''  Future<void> _selectPriceLists() async {
    final available = <String, PriceListDraft>{
      for (final list in _catalogPriceLists) list.id: list,
      for (final list in _lists) list.id: list,
    }.values.toList();
    final selected = _lists.map((list) => list.id).toSet();
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Listas aplicables al producto'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'La moneda y el tratamiento de IGV provienen de la lista. '
                  'No se redefinen dentro del producto.',
                  style: TextStyle(color: _muted),
                ),
                const SizedBox(height: 12),
                ...available.map(
                  (list) => CheckboxListTile(
                    value: selected.contains(list.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(list.name),
                    subtitle: Text(
                      '${list.currencyCode} · '
                      '${list.includesIgv ? 'Con IGV' : 'Sin IGV'}',
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        if (value ?? false) {
                          selected.add(list.id);
                        } else {
                          selected.remove(list.id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, {...selected}),
              child: const Text('Aplicar listas'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lists = available.where((list) => result.contains(list.id)).toList();
      if (!_lists.any((list) => list.id == _selectedListId)) {
        _selectedListId = _lists.first.id;
      }
      _syncGeneratedRows();
      _selectedPriceKeys.clear();
      _closeEditor();
    });
    _notifyChanged();
  }

'''
prices = replace_once(prices, select_method_anchor, select_method + select_method_anchor, 'selector de listas de precios')
for marker, label in [
    ('  Future<void> _editSelectedList()', 'edición local de lista'),
    ('  Future<void> _createPriceList()', 'creación local de lista'),
    ('  Future<PriceListDraft?> _showPriceListDialog(', 'modal local de lista'),
    ('  Widget _buildDialogDateField(', 'campo de fecha del modal local'),
]:
    prices = replace_dart_block(prices, marker, '', label)
# El avance considera pendientes de todas las listas seleccionadas.
prices = replace_once(
    prices,
    "  int get _pendingCount =>\n      _activeListRows.where((item) => !item.isReady).length;",
    "  int get _pendingCount =>\n      _activeListRows.where((item) => !item.isReady).length;\n\n  int get _totalPendingCount =>\n      _prices.where((item) => !item.isReady).length;",
    'conteo total de pendientes',
)
prices = replace_once(
    prices,
    '    if (_pendingCount > 0) {',
    '    if (_totalPendingCount > 0) {',
    'validar pendientes de todas las listas',
)
prices = replace_once(
    prices,
    "title: Text('Continuar con $_pendingCount pendientes'),",
    "title: Text('Continuar con $_totalPendingCount pendientes'),",
    'mensaje total de pendientes',
)
contents['prices'] = prices

# ---------------------------------------------------------------------------
# Revisión: agrega detalle y total de todas las listas seleccionadas.
# ---------------------------------------------------------------------------
review_model = contents['review']
review_model = replace_once(
    review_model,
    '    required this.pendingCount,\n  })',
    '    required this.pendingCount,\n    this.listSummaries = const [],\n  })',
    'resúmenes de listas en revisión',
)
review_model = replace_once(
    review_model,
    '  final int pendingCount;\n\n  int get readyCount',
    '  final int pendingCount;\n  final List<String> listSummaries;\n\n  int get readyCount',
    'campo de resúmenes de listas',
)
review_model = review_model.replace(
    "'${data.duplicateSkuCount == 1 ? 'SKU duplicado debe' : 'SKU duplicados deben'} '",
    "'${data.duplicateSkuCount == 1 ? 'código interno duplicado debe' : 'códigos internos duplicados deben'} '",
)
review_model = replace_once(
    review_model,
    "          'Lista ${price.listName} · ${price.currencyCode} · '\n              '${price.includesIgv ? 'incluye IGV' : 'sin IGV'}',\n          '${price.numericPriceCount} con precio · '",
    "          ...price.listSummaries,\n          '${price.numericPriceCount} con precio · '",
    'mostrar listas en tarjeta de revisión',
)
contents['review'] = review_model

review_adapter = contents['review_adapter']
# Sustituye cálculo de lista principal por todos los precios.
review_adapter = regex_once(
    review_adapter,
    r"    final primaryList = pricing\?\.lists\.firstOrNull;\n    final listPrices = primaryList == null\n        \? const <ProductPriceDraft>\[\]\n        : pricing!\.prices\n              \.where\(\(price\) => price\.listId == primaryList\.id\)\n              \.toList\(\);",
    "    final configuredLists = pricing?.lists ?? const <PriceListDraft>[];\n    final listPrices = pricing?.prices ?? const <ProductPriceDraft>[];",
    'usar todas las listas en revisión',
)
review_adapter = regex_once(
    review_adapter,
    r"      pricing: Step7PricingReview\(.*?\n      \),\n      images:",
    r'''      pricing: Step7PricingReview(
        listName: configuredLists.isEmpty
            ? 'Sin listas'
            : '${configuredLists.length} listas',
        currencyCode: configuredLists.map((list) => list.currencyCode).toSet().length == 1
            ? configuredLists.first.currencyCode
            : 'Múltiple',
        includesIgv:
            configuredLists.isNotEmpty && configuredLists.every((list) => list.includesIgv),
        totalCombinationCount: pricing?.prices.length ??
            state.presentaciones.length * activeVariants.length,
        numericPriceCount: pricing == null
            ? state.precios.length
            : listPrices.where((price) => price.hasNumericPrice).length,
        quoteCount: listPrices
            .where((price) => price.configuration == PriceConfigurationType.quote)
            .length,
        pendingCount: pricing == null
            ? (state.precios.isEmpty ? state.presentaciones.length : 0)
            : listPrices.where((price) => !price.isReady).length,
        listSummaries: configuredLists.map((list) {
          final pricesForList = listPrices
              .where((price) => price.listId == list.id)
              .toList();
          final pending = pricesForList.where((price) => !price.isReady).length;
          return '${list.name} · ${list.currencyCode} · '
              '${list.includesIgv ? 'Con IGV' : 'Sin IGV'} · '
              '${pricesForList.length - pending}/${pricesForList.length} combinaciones listas';
        }).toList(),
      ),
      images:''',
    'resumen agregado de precios',
)
review_adapter = replace_once(
    review_adapter,
    '          state.nombre.trim().isNotEmpty,',
    '          state.nombre.trim().isNotEmpty &&\n          state.atributosFamiliaCompletos,',
    'incluir atributos comunes en revisión',
)
contents['review_adapter'] = review_adapter

# ---------------------------------------------------------------------------
# Ajusta las pruebas existentes al catálogo de listas seleccionables.
# ---------------------------------------------------------------------------
legacy_test = contents['legacy_test']
legacy_test = replace_once(
    legacy_test,
    "      expect(find.text('US\\$ 21.50 por Docena'), findsOneWidget);",
    "      expect(find.text('S/ 21.50 por Docena'), findsOneWidget);",
    'moneda predeterminada en la prueba integral',
)
contents['legacy_test'] = legacy_test

# ---------------------------------------------------------------------------
# Pruebas de reglas comerciales y listas.
# ---------------------------------------------------------------------------
test_content = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/presentation/widgets/paso4_venta_logistica_contenido.dart';
import 'package:app_catalogo/features/catalogo/presentation/widgets/paso5_precios_corregido.dart';

void main() {
  test('una presentación resuelve excepciones por variante', () {
    const presentation = SalesPresentationDraft(
      id: 'empaque',
      name: 'Empaque',
      baseUnit: 'PZA',
      equivalentTo: 10,
      minimumOrder: 1,
      purchaseIncrement: 1,
      allowsDecimals: false,
      assignedVariantIds: {'v1', 'v2'},
      defaultVariantIds: {'v1', 'v2'},
      variantRules: {
        'v2': SalesPresentationVariantRule(
          variantId: 'v2',
          equivalentTo: 5,
          minimumOrder: 2,
          purchaseIncrement: 2,
        ),
      },
    );

    expect(presentation.ruleFor('v1').equivalentTo, 10);
    expect(presentation.ruleFor('v2').equivalentTo, 5);
    expect(presentation.ruleFor('v2').minimumOrder, 2);
  });

  test('las reglas comerciales se serializan y restauran', () {
    const draft = Step4SalesDraft(
      presentations: [
        SalesPresentationDraft(
          id: 'caja',
          name: 'Caja',
          baseUnit: 'PZA',
          equivalentTo: 20,
          minimumOrder: 1,
          purchaseIncrement: 1,
          allowsDecimals: false,
          assignedVariantIds: {'v1'},
          defaultVariantIds: {'v1'},
          variantRules: {
            'v1': SalesPresentationVariantRule(
              variantId: 'v1',
              equivalentTo: 12,
              minimumOrder: 1,
              purchaseIncrement: 1,
            ),
          },
        ),
      ],
      usesLogisticsPackages: false,
      logisticsPackages: [],
      hasProductContent: false,
      contentItems: [],
    );

    final restored = step4SalesDraftFromMap(step4SalesDraftToMap(draft));
    expect(restored?.presentations.single.ruleFor('v1').equivalentTo, 12);
  });

  test('activar requiere que todas las listas seleccionadas estén completas', () {
    final draft = PricingStep5Draft(
      lists: [
        PriceListDraft(
          id: 'regular',
          name: 'Regular',
          currencyCode: 'PEN',
          includesIgv: true,
          validFrom: DateTime(2026),
        ),
        PriceListDraft(
          id: 'mayorista',
          name: 'Mayorista',
          currencyCode: 'PEN',
          includesIgv: true,
          validFrom: DateTime(2026),
        ),
      ],
      prices: const [
        ProductPriceDraft(
          listId: 'regular',
          variantId: 'v1',
          presentationId: 'unidad',
          configuration: PriceConfigurationType.fixed,
          fixedPrice: 10,
        ),
        ProductPriceDraft(
          listId: 'mayorista',
          variantId: 'v1',
          presentationId: 'unidad',
          configuration: PriceConfigurationType.unconfigured,
        ),
      ],
      sellableCombinations: const [
        SellablePriceCombination(
          variantId: 'v1',
          variantLabel: 'Producto',
          presentationId: 'unidad',
          presentationLabel: 'Unidad',
          baseUnit: 'PZA',
          equivalentToBaseUnit: 1,
        ),
      ],
    );

    expect(draft.canActivate('regular'), isTrue);
    expect(draft.canActivate('mayorista'), isFalse);
  });
}
'''

updates = {PATHS[name]: content for name, content in contents.items()}
updates[TEST_PATH] = test_content
for path, markers in {
    PATHS['sales_draft']: ['SalesPresentationVariantRule', 'variant_rules', 'Excepciones por variante'],
    PATHS['prices']: ['Seleccionar listas', '_totalPendingCount', "currencyCode: 'PEN'"],
    PATHS['review_adapter']: ['listSummaries', 'configuredLists'],
    PATHS['legacy_test']: ["S/ 21.50 por Docena"],
}.items():
    for marker in markers:
        if marker not in updates[path]:
            fail(f'La validación final no encontró “{marker}” en {path}.')

timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
backup_dir = ROOT / f'.backup_fase4b_reglas_comerciales_{timestamp}'
backup_dir.mkdir(parents=True, exist_ok=False)
for path in updates:
    if not path.exists():
        continue
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
for path, content in updates.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8', newline='\n')
    print(f'Modificado: {path.relative_to(ROOT)}')

print(f'\nRespaldo: {backup_dir}')
print('\nFase 4B aplicada con guardado flexible de reglas por variante.')
print('Ejecuta:')
print('  dart format lib test')
print('  flutter test test/reglas_comerciales_producto_test.dart')
print('  flutter test test/producto_form_page_test.dart')
print('  flutter analyze')
