import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/producto_variante.dart';
import '../bloc/producto_form_bloc.dart';
import '../bloc/producto_form_event.dart';
import '../bloc/producto_form_state.dart';

class ProductoUnicoStepController {
  bool Function()? _validator;

  bool validateAndSave() => _validator?.call() ?? false;

  void attach(bool Function() validator) {
    _validator = validator;
  }

  void detach() {
    _validator = null;
  }
}

final productoUnicoStepController = ProductoUnicoStepController();

enum _SingleAttributeKind { text, number, selection }

class _SingleAttributeTemplate {
  const _SingleAttributeTemplate({
    required this.name,
    required this.kind,
    this.units = const [],
    this.defaultUnit,
    this.options = const [],
  });

  final String name;
  final _SingleAttributeKind kind;
  final List<String> units;
  final String? defaultUnit;
  final List<String> options;
}

class _SingleAttributeField {
  _SingleAttributeField({
    required this.id,
    required this.name,
    required this.kind,
    String value = '',
    this.units = const [],
    String? selectedUnit,
    this.options = const [],
    this.selectedOption,
    this.isSuggested = false,
  }) : valueController = TextEditingController(text: value),
       selectedUnit = selectedUnit ?? (units.isEmpty ? null : units.first);

  final String id;
  String name;
  _SingleAttributeKind kind;
  final TextEditingController valueController;
  List<String> units;
  String? selectedUnit;
  List<String> options;
  String? selectedOption;
  final bool isSuggested;

  String get cleanValue {
    if (kind == _SingleAttributeKind.selection) {
      return selectedOption?.trim() ?? '';
    }
    return valueController.text.trim();
  }

  void dispose() {
    valueController.dispose();
  }
}

class _SingleAttributeEditorResult {
  const _SingleAttributeEditorResult({
    required this.name,
    required this.kind,
    this.options = const [],
  });

  final String name;
  final _SingleAttributeKind kind;
  final List<String> options;
}

class ProductoUnicoStep extends StatefulWidget {
  const ProductoUnicoStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  State<ProductoUnicoStep> createState() => _ProductoUnicoStepState();
}

class _ProductoUnicoStepState extends State<ProductoUnicoStep> {
  static const _singlePrimary = Color(0xFFFFC500);
  static const _singleInk = Color(0xFF20242B);
  static const _singleMuted = Color(0xFF667085);
  static const _singleBorder = Color(0xFFD5DDE8);
  static const _singleCanvas = Color(0xFFF8FAFC);

  static const _singleDefaultUnits = [
    'mm',
    'cm',
    'm',
    'in',
    '″',
    'g',
    'kg',
    'oz',
    'lb',
    'ml',
    'L',
    'gal',
    'V',
    'Ah',
    'W',
    'un.',
  ];

  final _singleProductFormKey = GlobalKey<FormState>();
  final _singleSkuController = TextEditingController();
  final _singleNameController = TextEditingController();
  final _singleDescriptionController = TextEditingController();
  final List<_SingleAttributeField> _singleAttributes = [];
  final Set<String> _singleReservedSkus = {};

  String? _singleOriginalSku;
  late String _singleGeneratedSku;
  bool _singleAvailableOnPublish = true;
  bool _singleDraftSaved = false;
  int _singleAttributeSequence = 100;

  String get _singleFamilyLabel {
    final family = widget.state.nombre.trim();
    return family.isEmpty ? 'Martillo de goma' : family;
  }

  String get _singleCategoryLabel {
    final subcategory = widget.state.subcategoria?.trim() ?? '';
    if (subcategory.isNotEmpty) return subcategory;
    final category = widget.state.categoria?.trim() ?? '';
    return category.isEmpty ? 'Martillos' : category;
  }

  List<_SingleAttributeTemplate> get _singleSuggestedTemplates {
    final source = '$_singleCategoryLabel $_singleFamilyLabel'.toLowerCase();
    if (source.contains('martill')) {
      return const [
        _SingleAttributeTemplate(
          name: 'Peso',
          kind: _SingleAttributeKind.number,
          units: ['oz', 'g', 'kg', 'lb'],
          defaultUnit: 'oz',
        ),
        _SingleAttributeTemplate(
          name: 'Material del mango',
          kind: _SingleAttributeKind.text,
        ),
        _SingleAttributeTemplate(
          name: 'Color',
          kind: _SingleAttributeKind.selection,
          options: ['Negro', 'Rojo', 'Amarillo', 'Azul', 'Gris', 'Otro'],
        ),
      ];
    }
    if (source.contains('bater')) {
      return const [
        _SingleAttributeTemplate(
          name: 'Voltaje',
          kind: _SingleAttributeKind.number,
          units: ['V'],
          defaultUnit: 'V',
        ),
        _SingleAttributeTemplate(
          name: 'Capacidad',
          kind: _SingleAttributeKind.number,
          units: ['Ah'],
          defaultUnit: 'Ah',
        ),
        _SingleAttributeTemplate(
          name: 'Sistema compatible',
          kind: _SingleAttributeKind.text,
        ),
      ];
    }
    if (source.contains('broca')) {
      return const [
        _SingleAttributeTemplate(
          name: 'Diámetro',
          kind: _SingleAttributeKind.number,
          units: ['mm', 'in', '″'],
          defaultUnit: 'mm',
        ),
        _SingleAttributeTemplate(
          name: 'Largo',
          kind: _SingleAttributeKind.number,
          units: ['mm', 'cm', 'in', '″'],
          defaultUnit: 'mm',
        ),
        _SingleAttributeTemplate(
          name: 'Material',
          kind: _SingleAttributeKind.text,
        ),
      ];
    }
    if (source.contains('perno')) {
      return const [
        _SingleAttributeTemplate(
          name: 'Diámetro',
          kind: _SingleAttributeKind.number,
          units: ['mm', 'in', '″'],
          defaultUnit: 'mm',
        ),
        _SingleAttributeTemplate(
          name: 'Largo',
          kind: _SingleAttributeKind.number,
          units: ['mm', 'cm', 'in', '″'],
          defaultUnit: 'mm',
        ),
        _SingleAttributeTemplate(
          name: 'Rosca',
          kind: _SingleAttributeKind.text,
        ),
        _SingleAttributeTemplate(
          name: 'Acabado',
          kind: _SingleAttributeKind.text,
        ),
      ];
    }
    if (source.contains('pintur')) {
      return const [
        _SingleAttributeTemplate(
          name: 'Color',
          kind: _SingleAttributeKind.selection,
          options: ['Blanco', 'Negro', 'Gris', 'Rojo', 'Azul', 'Otro'],
        ),
        _SingleAttributeTemplate(
          name: 'Volumen',
          kind: _SingleAttributeKind.number,
          units: ['ml', 'L', 'gal'],
          defaultUnit: 'L',
        ),
        _SingleAttributeTemplate(
          name: 'Acabado',
          kind: _SingleAttributeKind.selection,
          options: ['Mate', 'Satinado', 'Semibrillo', 'Brillante'],
        ),
      ];
    }
    return const [
      _SingleAttributeTemplate(
        name: 'Material',
        kind: _SingleAttributeKind.text,
      ),
      _SingleAttributeTemplate(
        name: 'Color',
        kind: _SingleAttributeKind.selection,
        options: ['Negro', 'Blanco', 'Rojo', 'Azul', 'Gris', 'Otro'],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeSingleProduct();
    productoUnicoStepController.attach(_validateSingleProductBeforeContinue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVariant();
    });
  }

  @override
  void dispose() {
    productoUnicoStepController.detach();
    _singleSkuController.dispose();
    _singleNameController.dispose();
    _singleDescriptionController.dispose();
    for (final attribute in _singleAttributes) {
      attribute.dispose();
    }
    super.dispose();
  }

  void _initializeSingleProduct() {
    ProductoVariante? existing;
    for (final variante in widget.state.variantes) {
      if (variante.id == 'single-product') {
        existing = variante;
        break;
      }
    }
    existing ??= widget.state.variantes.length == 1
        ? widget.state.variantes.first
        : null;

    for (final variante in widget.state.variantes) {
      if (variante.id != existing?.id && variante.sku.trim().isNotEmpty) {
        _singleReservedSkus.add(variante.sku.trim().toUpperCase());
      }
    }

    final savedSku = existing?.sku.trim() ?? '';
    final autogenerated = savedSku.startsWith('AUTO-SINGLE-');
    _singleGeneratedSku = autogenerated || savedSku.isEmpty
        ? (savedSku.isEmpty
              ? 'AUTO-SINGLE-${DateTime.now().microsecondsSinceEpoch}'
              : savedSku)
        : 'AUTO-SINGLE-${DateTime.now().microsecondsSinceEpoch}';
    _singleOriginalSku = savedSku.isEmpty ? null : savedSku.toUpperCase();
    _singleSkuController.text = autogenerated ? '' : savedSku;
    _singleNameController.text = existing?.nombreCorto ?? '';
    _singleDescriptionController.text = widget.state.descripcion;
    _singleAvailableOnPublish = existing?.activa ?? true;
    _initializeSingleAttributes(existing);
  }

  void _initializeSingleAttributes(ProductoVariante? existing) {
    final saved = {
      for (final attribute in existing?.atributos ?? const [])
        _normalizeSingleAttributeName(attribute.nombre): attribute,
    };
    final templateNames = <String>{};

    for (final template in _singleSuggestedTemplates) {
      final normalized = _normalizeSingleAttributeName(template.name);
      templateNames.add(normalized);
      final value = saved[normalized];
      var options = List<String>.of(template.options);
      String? selectedOption;
      if (template.kind == _SingleAttributeKind.selection &&
          value != null &&
          value.texto.trim().isNotEmpty) {
        if (!options.contains(value.texto)) options.add(value.texto);
        selectedOption = value.texto;
      }
      _singleAttributes.add(
        _SingleAttributeField(
          id: 'suggested-$normalized',
          name: template.name,
          kind: template.kind,
          value: template.kind == _SingleAttributeKind.selection
              ? ''
              : value?.valor ?? '',
          units: template.units,
          selectedUnit:
              value?.unidad ??
              template.defaultUnit ??
              (template.units.isEmpty ? null : template.units.first),
          options: options,
          selectedOption: selectedOption,
          isSuggested: true,
        ),
      );
    }

    for (final attribute in existing?.atributos ?? const []) {
      final normalized = _normalizeSingleAttributeName(attribute.nombre);
      if (templateNames.contains(normalized)) continue;
      final numeric = attribute.unidad.trim().isNotEmpty;
      _singleAttributes.add(
        _SingleAttributeField(
          id: 'custom-${_singleAttributeSequence++}',
          name: attribute.nombre,
          kind: numeric
              ? _SingleAttributeKind.number
              : _SingleAttributeKind.text,
          value: attribute.valor,
          units: numeric
              ? <String>{
                  ..._singleDefaultUnits,
                  if (attribute.unidad.trim().isNotEmpty) attribute.unidad,
                }.toList()
              : const [],
          selectedUnit: numeric ? attribute.unidad : null,
        ),
      );
    }
  }

  String _normalizeSingleAttributeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  bool _singleAttributeNameExists(String name, {String? exceptId}) {
    final normalized = _normalizeSingleAttributeName(name);
    return _singleAttributes.any(
      (attribute) =>
          attribute.id != exceptId &&
          _normalizeSingleAttributeName(attribute.name) == normalized,
    );
  }

  String? _validateSingleSku(String? rawValue) {
    final sku = rawValue?.trim().toUpperCase() ?? '';
    if (sku.isEmpty) return null;
    final original = _singleOriginalSku?.trim().toUpperCase();
    final duplicated = _singleReservedSkus.contains(sku) && sku != original;
    return duplicated ? 'Este SKU ya está registrado.' : null;
  }

  bool _isValidSingleNumericValue(String rawValue) {
    final value = rawValue.trim().replaceAll(',', '.');
    return RegExp(
      r'^(?:\d+(?:\.\d+)?|\d+\s*/\s*\d+|\d+\s+\d+\s*/\s*\d+)$',
    ).hasMatch(value);
  }

  String? _validateSingleNumericAttribute(
    _SingleAttributeField attribute,
    String? rawValue,
  ) {
    final value = rawValue?.trim() ?? '';
    final unit = attribute.selectedUnit?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!_isValidSingleNumericValue(value)) return 'Usa un número válido.';
    if (unit.isEmpty) return 'Selecciona una unidad.';
    return null;
  }

  bool _hasSingleDuplicateAttributes() {
    final names = <String>{};
    for (final attribute in _singleAttributes) {
      if (!names.add(_normalizeSingleAttributeName(attribute.name))) {
        return true;
      }
    }
    return false;
  }

  List<String> _parseSingleOptions(String value) {
    final unique = <String>{};
    final result = <String>[];
    for (final option in value.split(',')) {
      final clean = option.trim();
      if (clean.isNotEmpty && unique.add(clean.toLowerCase())) {
        result.add(clean);
      }
    }
    return result;
  }

  Future<void> _openSingleAttributeEditor({
    _SingleAttributeField? attribute,
  }) async {
    final editing = attribute != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: attribute?.name ?? '');
    final optionsController = TextEditingController(
      text: attribute?.options.join(', ') ?? '',
    );
    var selectedKind = attribute?.kind ?? _SingleAttributeKind.text;

    final result = await showDialog<_SingleAttributeEditorResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            editing ? 'Editar atributo' : 'Añadir atributo',
            style: const TextStyle(
              color: _singleInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 430,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSingleTextField(
                    label: 'Nombre del atributo *',
                    controller: nameController,
                    hint: 'Ej. Dureza',
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'Ingresa un nombre.';
                      if (_singleAttributeNameExists(
                        name,
                        exceptId: attribute?.id,
                      )) {
                        return 'Ya existe un atributo con este nombre.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tipo de valor',
                    style: TextStyle(
                      color: _singleMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<_SingleAttributeKind>(
                    key: ValueKey(selectedKind),
                    initialValue: selectedKind,
                    decoration: _singleInputDecoration(),
                    items: const [
                      DropdownMenuItem(
                        value: _SingleAttributeKind.text,
                        child: Text('Texto'),
                      ),
                      DropdownMenuItem(
                        value: _SingleAttributeKind.number,
                        child: Text('Número + unidad'),
                      ),
                      DropdownMenuItem(
                        value: _SingleAttributeKind.selection,
                        child: Text('Lista de opciones'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedKind = value);
                    },
                  ),
                  if (selectedKind == _SingleAttributeKind.selection) ...[
                    const SizedBox(height: 16),
                    _buildSingleTextField(
                      label: 'Opciones *',
                      controller: optionsController,
                      hint: 'Mate, Satinado, Brillante',
                      helper: 'Separa cada opción con una coma.',
                      validator: (value) =>
                          _parseSingleOptions(value ?? '').length < 2
                          ? 'Agrega al menos dos opciones distintas.'
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(
                  dialogContext,
                  _SingleAttributeEditorResult(
                    name: nameController.text.trim(),
                    kind: selectedKind,
                    options: selectedKind == _SingleAttributeKind.selection
                        ? _parseSingleOptions(optionsController.text)
                        : const [],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _singlePrimary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                editing ? 'Guardar cambios' : 'Añadir',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      optionsController.dispose();
    });
    if (result == null || !mounted) return;

    setState(() {
      if (attribute == null) {
        _singleAttributes.add(
          _SingleAttributeField(
            id: 'custom-${_singleAttributeSequence++}',
            name: result.name,
            kind: result.kind,
            units: result.kind == _SingleAttributeKind.number
                ? List.of(_singleDefaultUnits)
                : const [],
            options: result.options,
          ),
        );
      } else {
        attribute.name = result.name;
        attribute.kind = result.kind;
        if (result.kind == _SingleAttributeKind.number) {
          attribute.units = List.of(_singleDefaultUnits);
          attribute.selectedUnit =
              attribute.units.contains(attribute.selectedUnit)
              ? attribute.selectedUnit
              : null;
          attribute.options = const [];
          attribute.selectedOption = null;
        } else if (result.kind == _SingleAttributeKind.selection) {
          attribute.units = const [];
          attribute.selectedUnit = null;
          attribute.options = result.options;
          attribute.selectedOption =
              result.options.contains(attribute.selectedOption)
              ? attribute.selectedOption
              : null;
        } else {
          attribute.units = const [];
          attribute.selectedUnit = null;
          attribute.options = const [];
          attribute.selectedOption = null;
        }
      }
      _singleDraftSaved = false;
    });
    _syncVariant();
  }

  Future<void> _removeSingleAttribute(_SingleAttributeField attribute) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar atributo'),
        content: Text('Se quitará “${attribute.name}” de este artículo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _singleAttributes.remove(attribute);
      _singleDraftSaved = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => attribute.dispose());
    _syncVariant();
  }

  void _markSingleDraftChanged() {
    if (_singleDraftSaved) setState(() => _singleDraftSaved = false);
    _syncVariant();
  }

  String get _effectiveSku {
    final sku = _singleSkuController.text.trim().toUpperCase();
    return sku.isEmpty ? _singleGeneratedSku : sku;
  }

  void _syncVariant() {
    if (!mounted) return;
    final attributes = _singleAttributes
        .where((attribute) => attribute.cleanValue.isNotEmpty)
        .map(
          (attribute) => AtributoProductoVariante(
            nombre: attribute.name.trim(),
            valor: attribute.cleanValue,
            unidad: attribute.kind == _SingleAttributeKind.number
                ? attribute.selectedUnit?.trim() ?? ''
                : '',
          ),
        )
        .toList();
    final variante = ProductoVariante(
      id: 'single-product',
      sku: _effectiveSku,
      nombreCorto: _singleNameController.text.trim(),
      atributos: attributes,
      activa: _singleAvailableOnPublish,
    );
    context.read<ProductoFormBloc>()
      ..add(ProductoFormVariantesReemplazadas([variante]))
      ..add(
        ProductoFormFamiliaCambiada(
          descripcion: _singleDescriptionController.text,
        ),
      );
  }

  void _saveSingleProductDraft() {
    final skuError = _validateSingleSku(_singleSkuController.text);
    if (skuError != null) {
      _showSingleProductMessage(skuError);
      return;
    }
    if (_hasSingleDuplicateAttributes()) {
      _showSingleProductMessage(
        'Corrige los atributos duplicados antes de guardar.',
      );
      return;
    }
    setState(() => _singleDraftSaved = true);
    _syncVariant();
    _showSingleProductMessage('Borrador guardado.');
  }

  bool _validateSingleProductBeforeContinue() {
    if (_hasSingleDuplicateAttributes()) {
      _showSingleProductMessage(
        'No puede haber atributos con el mismo nombre.',
      );
      return false;
    }
    if (!(_singleProductFormKey.currentState?.validate() ?? false)) {
      _showSingleProductMessage(
        'Revisa los campos marcados antes de continuar.',
      );
      return false;
    }
    _syncVariant();
    return true;
  }

  void _showSingleProductMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 18,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Producto único',
                    style: TextStyle(
                      color: _singleInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Completa los datos del único artículo vendible. '
                    'El sistema creará una variante automáticamente.',
                    style: TextStyle(color: _singleMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            _buildSingleFamilyChip(),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1020;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSingleProductCard(),
                  const SizedBox(height: 18),
                  _buildSingleInformationPanel(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildSingleProductCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildSingleInformationPanel()),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _buildSingleFamilyChip() => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3C4),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      'Familia: $_singleFamilyLabel',
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _singleInk,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildSingleProductCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _singleBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _singleProductFormKey,
        onChanged: _markSingleDraftChanged,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Producto vendible',
                    style: TextStyle(
                      color: _singleInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    '1 variante automática',
                    style: TextStyle(
                      color: _singleMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSingleSectionTitle(
              icon: Icons.badge_outlined,
              title: 'Identificación',
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final skuField = _buildSingleTextField(
                  fieldKey: const Key('producto_unico_sku'),
                  label: 'Código / SKU (opcional)',
                  controller: _singleSkuController,
                  hint: 'UY-MG16',
                  helper: 'Déjalo vacío si el proveedor no utiliza código.',
                  textCapitalization: TextCapitalization.characters,
                  validator: _validateSingleSku,
                );
                final nameField = _buildSingleTextField(
                  fieldKey: const Key('producto_unico_nombre'),
                  label: 'Nombre comercial corto *',
                  controller: _singleNameController,
                  hint: 'Martillo de goma 16 oz',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre comercial.'
                      : null,
                );
                if (compact) {
                  return Column(
                    children: [skuField, const SizedBox(height: 16), nameField],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: skuField),
                    const SizedBox(width: 18),
                    Expanded(child: nameField),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            const Divider(height: 1, color: _singleBorder),
            const SizedBox(height: 22),
            _buildSingleSectionTitle(
              icon: Icons.notes_outlined,
              title: 'Descripción',
            ),
            const SizedBox(height: 14),
            _buildSingleTextField(
              fieldKey: const Key('producto_unico_descripcion'),
              label: 'Descripción corta',
              controller: _singleDescriptionController,
              hint: 'Martillo de goma con mango antideslizante.',
              maxLines: 3,
              maxLength: 240,
            ),
            const SizedBox(height: 26),
            const Divider(height: 1, color: _singleBorder),
            const SizedBox(height: 22),
            _buildSingleAttributesSection(),
            const SizedBox(height: 26),
            const Divider(height: 1, color: _singleBorder),
            const SizedBox(height: 22),
            _buildSingleAvailabilitySection(),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                key: const Key('guardar_borrador_unico'),
                onPressed: _saveSingleProductDraft,
                icon: Icon(
                  _singleDraftSaved
                      ? Icons.check_circle_outline
                      : Icons.save_outlined,
                  size: 18,
                ),
                label: Text(
                  _singleDraftSaved ? 'Borrador guardado' : 'Guardar borrador',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _singleInk,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 14,
                  ),
                  side: BorderSide(
                    color: _singleDraftSaved
                        ? const Color(0xFF2F855A)
                        : const Color(0xFF98A2B3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildSingleAttributesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildSingleSectionTitle(
        icon: Icons.tune,
        title: 'Atributos técnicos sugeridos para $_singleCategoryLabel',
      ),
      const SizedBox(height: 5),
      const Text(
        'Puedes completar, editar, eliminar o añadir atributos.',
        style: TextStyle(color: _singleMuted, fontSize: 12),
      ),
      const SizedBox(height: 15),
      if (_singleAttributes.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _singleCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _singleBorder),
          ),
          child: const Text(
            'No hay atributos técnicos. Puedes añadir uno.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _singleMuted, fontSize: 12),
          ),
        )
      else
        ..._singleAttributes.map(_buildSingleAttributeCard),
      const SizedBox(height: 4),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('anadir_atributo_unico'),
          onPressed: _openSingleAttributeEditor,
          icon: const Icon(Icons.add, size: 19),
          label: const Text('Añadir atributo'),
          style: TextButton.styleFrom(
            foregroundColor: _singleInk,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    ],
  );

  Widget _buildSingleAttributeCard(_SingleAttributeField attribute) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _singleCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _singleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    attribute.name,
                    style: const TextStyle(
                      color: _singleInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _openSingleAttributeEditor(attribute: attribute),
                  tooltip: 'Editar atributo',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: _singleMuted,
                  ),
                ),
                IconButton(
                  onPressed: () => _removeSingleAttribute(attribute),
                  tooltip: 'Eliminar atributo',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close, size: 18, color: Colors.red.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (attribute.kind == _SingleAttributeKind.number)
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final valueField = TextFormField(
                    controller: attribute.valueController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _validateSingleNumericAttribute(attribute, value),
                    decoration: _singleInputDecoration(hint: 'Valor'),
                  );
                  final unitField = DropdownButtonFormField<String>(
                    key: ValueKey('${attribute.id}-${attribute.selectedUnit}'),
                    initialValue: attribute.selectedUnit,
                    isExpanded: true,
                    decoration: _singleInputDecoration(hint: 'Unidad'),
                    items: attribute.units
                        .map(
                          (unit) =>
                              DropdownMenuItem(value: unit, child: Text(unit)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        attribute.selectedUnit = value;
                        _singleDraftSaved = false;
                      });
                      _syncVariant();
                    },
                  );
                  if (compact) {
                    return Column(
                      children: [
                        valueField,
                        const SizedBox(height: 10),
                        unitField,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: valueField),
                      const SizedBox(width: 10),
                      Expanded(child: unitField),
                    ],
                  );
                },
              )
            else if (attribute.kind == _SingleAttributeKind.selection)
              DropdownButtonFormField<String>(
                key: ValueKey('${attribute.id}-${attribute.selectedOption}'),
                initialValue: attribute.selectedOption,
                isExpanded: true,
                hint: const Text('Selecciona una opción'),
                decoration: _singleInputDecoration(),
                items: attribute.options
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    attribute.selectedOption = value;
                    _singleDraftSaved = false;
                  });
                  _syncVariant();
                },
              )
            else
              TextFormField(
                controller: attribute.valueController,
                decoration: _singleInputDecoration(hint: 'Escribe el valor'),
              ),
          ],
        ),
      );

  Widget _buildSingleAvailabilitySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _buildSingleSectionTitle(
        icon: Icons.visibility_outlined,
        title: 'Disponibilidad',
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: _singleCanvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _singleBorder),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disponible al publicar',
                    style: TextStyle(
                      color: _singleInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Esta variante se mostrará cuando el producto sea '
                    'activado en el paso 7.',
                    style: TextStyle(
                      color: _singleMuted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Switch.adaptive(
              value: _singleAvailableOnPublish,
              activeThumbColor: _singleInk,
              activeTrackColor: _singlePrimary,
              onChanged: (value) {
                setState(() {
                  _singleAvailableOnPublish = value;
                  _singleDraftSaved = false;
                });
                _syncVariant();
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildSingleInformationPanel() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: _singleCanvas,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _singleBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Se define en este paso',
            style: TextStyle(
              color: _singleInk,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          _buildSingleInformationRow(
            Icons.badge_outlined,
            'Identificación del artículo.',
          ),
          _buildSingleInformationRow(
            Icons.notes_outlined,
            'Descripción comercial.',
          ),
          _buildSingleInformationRow(Icons.tune, 'Atributos técnicos.'),
          _buildSingleInformationRow(
            Icons.visibility_outlined,
            'Disponibilidad inicial.',
          ),
          const SizedBox(height: 13),
          const Divider(color: _singleBorder),
          const SizedBox(height: 13),
          const Text(
            'Se configura después',
            style: TextStyle(
              color: _singleMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _buildSingleLaterRow(
            Icons.inventory_2_outlined,
            'Venta y empaques',
            'Paso 4',
          ),
          _buildSingleLaterRow(Icons.sell_outlined, 'Precios', 'Paso 5'),
          _buildSingleLaterRow(Icons.image_outlined, 'Imágenes', 'Paso 6'),
          _buildSingleLaterRow(
            Icons.task_alt,
            'Revisión y activación',
            'Paso 7',
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 21, color: Color(0xFF9A7200)),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    '“Unidad”, “caja” y “ciento” son presentaciones de '
                    'venta, no variantes. Se configurarán en el paso 4.',
                    style: TextStyle(
                      color: _singleMuted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSingleSectionTitle({
    required IconData icon,
    required String title,
  }) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _singlePrimary.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: _singleInk),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _singleInk,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );

  Widget _buildSingleInformationRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: _singleInk),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _singleInk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSingleLaterRow(IconData icon, String label, String step) =>
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _singleBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _singleMuted),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _singleInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              step,
              style: const TextStyle(
                color: _singleMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _buildSingleTextField({
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    required String hint,
    String? helper,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _singleMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      TextFormField(
        key: fieldKey,
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        decoration: _singleInputDecoration(hint: hint, helper: helper),
      ),
    ],
  );

  InputDecoration _singleInputDecoration({String? hint, String? helper}) =>
      InputDecoration(
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _singleBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _singleBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: _singlePrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
      );
}
