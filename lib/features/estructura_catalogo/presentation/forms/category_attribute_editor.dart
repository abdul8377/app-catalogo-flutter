part of '../pages/gestionar_atributos_categoria.dart';

class _AttributeEditor extends StatefulWidget {
  const _AttributeEditor({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.attribute,
    required this.readOnly,
    required this.units,
    required this.reservedNames,
    required this.reservedKeys,
    required this.onCancel,
    required this.onSave,
    this.onDelete,
    this.onOpenOwnerCategory,
    this.onShowAffectedProducts,
  });

  final String categoryId;
  final String categoryName;
  final CategoryAttributeDefinition? attribute;
  final bool readOnly;
  final List<AttributeUnit> units;
  final Set<String> reservedNames;
  final Set<String> reservedKeys;
  final VoidCallback onCancel;
  final ValueChanged<CategoryAttributeDefinition> onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenOwnerCategory;
  final VoidCallback? onShowAffectedProducts;

  @override
  State<_AttributeEditor> createState() => _AttributeEditorState();
}

class _AttributeEditorState extends State<_AttributeEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  late final TextEditingController _helpController;
  late final TextEditingController _textLengthController;
  late final TextEditingController _exampleController;
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;
  late final TextEditingController _decimalsController;
  late final TextEditingController _maximumSelectionsController;
  late final TextEditingController _trueLabelController;
  late final TextEditingController _falseLabelController;

  late CategoryAttributeDataType _type;
  late AttributeCaptureLevel _captureLevel;
  late bool _requiredToActivate;
  late bool _visibleInTechnicalSheet;
  late bool _filterable;
  late bool _canBeVariantAxis;
  late bool _activeForNewProducts;
  late bool _active;
  late String? _magnitude;
  late List<String> _allowedUnits;
  late String? _defaultUnit;
  late List<CategoryAttributeOption> _options;
  bool _keyEditedManually = false;

  CategoryAttributeDefinition? get _source => widget.attribute;
  bool get _structureLocked => _source?.structureLocked ?? false;

  @override
  void initState() {
    super.initState();
    final source = _source;
    _nameController = TextEditingController(text: source?.name);
    _keyController = TextEditingController(text: source?.keyName);
    _helpController = TextEditingController(text: source?.helpText);
    _textLengthController = TextEditingController(
      text: source?.textMaxLength?.toString(),
    );
    _exampleController = TextEditingController(text: source?.example);
    _minimumController = TextEditingController(
      text: source?.minimum?.toString(),
    );
    _maximumController = TextEditingController(
      text: source?.maximum?.toString(),
    );
    _decimalsController = TextEditingController(
      text: (source?.decimals ?? 0).toString(),
    );
    _maximumSelectionsController = TextEditingController(
      text: source?.maximumSelections?.toString(),
    );
    _trueLabelController = TextEditingController(text: source?.trueLabel);
    _falseLabelController = TextEditingController(text: source?.falseLabel);

    _type = source?.dataType ?? CategoryAttributeDataType.shortText;
    _captureLevel =
        source?.captureLevel ?? AttributeCaptureLevel.decideWhenRegistering;
    _requiredToActivate = source?.requiredToActivate ?? false;
    _visibleInTechnicalSheet = source?.visibleInTechnicalSheet ?? true;
    _filterable = source?.filterable ?? true;
    _canBeVariantAxis = source?.canBeVariantAxis ?? false;
    _activeForNewProducts = source?.activeForNewProducts ?? true;
    _active = source?.active ?? true;
    _magnitude = source?.magnitude;
    _allowedUnits = [...?source?.allowedUnitCodes];
    _defaultUnit = source?.defaultUnitCode;
    _options = [...?source?.options];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _helpController.dispose();
    _textLengthController.dispose();
    _exampleController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    _decimalsController.dispose();
    _maximumSelectionsController.dispose();
    _trueLabelController.dispose();
    _falseLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.readOnly;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _source == null
                            ? 'Nuevo atributo'
                            : readOnly
                            ? 'Ver atributo heredado'
                            : 'Editar atributo',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        readOnly
                            ? 'Propietaria: ${_source?.ownerCategoryName}'
                            : 'Categoría: ${widget.categoryName}',
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar editor',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  if (readOnly)
                    _Notice(
                      text:
                          'Este atributo se hereda automáticamente. Para modificar '
                          'su estructura, abre ${_source?.ownerCategoryName}.',
                      actionLabel: 'Editar en categoría propietaria',
                      onAction: widget.onOpenOwnerCategory,
                    ),
                  if (_structureLocked && !readOnly)
                    _Notice(
                      text:
                          'Usado por ${_source?.usedByProductCount} productos. '
                          'El tipo, la clave y las unidades quedan protegidos.',
                      actionLabel: 'Ver productos afectados',
                      onAction: widget.onShowAffectedProducts,
                    ),
                  if (!readOnly && (_source?.affectedCategoryCount ?? 0) > 0)
                    _Notice(
                      text:
                          'Los cambios de comportamiento se reflejarán en '
                          '${_source!.affectedCategoryCount} categorías '
                          'descendientes y en sus formularios de registro.',
                    ),
                  const _SectionTitle('Información básica'),
                  TextFormField(
                    controller: _nameController,
                    enabled: !readOnly,
                    onChanged: (value) {
                      if (!_keyEditedManually && !_structureLocked) {
                        _keyController.text = _toKey(value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nombre del atributo *',
                      hintText: 'Ej. Diámetro',
                    ),
                    validator: (value) {
                      final normalized = _canonicalAttributeIdentity(
                        value ?? '',
                      );
                      if (normalized.isEmpty) {
                        return 'El nombre es obligatorio.';
                      }
                      if (widget.reservedNames.contains(normalized)) {
                        return 'Ya existe en esta cadena de categorías.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _helpController,
                    enabled: !readOnly,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Texto de ayuda',
                      hintText: 'Indica el diámetro nominal de la broca.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CategoryAttributeDataType>(
                    isExpanded: true,
                    value: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de dato *',
                    ),
                    items: CategoryAttributeDataType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              _dataTypeLabel(type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: readOnly || _structureLocked
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _type = value;
                              if (!_supportsAxis(value)) {
                                _canBeVariantAxis = false;
                              }
                            });
                          },
                  ),
                  const _SectionTitle('Comportamiento'),
                  DropdownButtonFormField<AttributeCaptureLevel>(
                    isExpanded: true,
                    value: _captureLevel,
                    decoration: const InputDecoration(
                      labelText: 'Nivel de captura recomendado',
                    ),
                    items: AttributeCaptureLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(
                              _captureLevelLabel(level),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: readOnly
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _captureLevel = value);
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  _EditorSwitch(
                    title: 'Obligatorio para activar el producto',
                    value: _requiredToActivate,
                    readOnly: readOnly,
                    onChanged: (value) {
                      setState(() => _requiredToActivate = value);
                    },
                  ),
                  _EditorSwitch(
                    title: 'Mostrar en la ficha técnica',
                    value: _visibleInTechnicalSheet,
                    readOnly: readOnly,
                    onChanged: (value) {
                      setState(() => _visibleInTechnicalSheet = value);
                    },
                  ),

                  _EditorSwitch(
                    title: 'Puede utilizarse como eje de variante',
                    subtitle: _supportsAxis(_type)
                        ? 'La decisión final se toma al registrar el producto.'
                        : 'Disponible solo para Número, Número con unidad y '
                              'Lista de una opción.',
                    value: _canBeVariantAxis,
                    readOnly: readOnly || !_supportsAxis(_type),
                    onChanged: (value) {
                      if (!value &&
                          (_source?.usedAsAxisByProductCount ?? 0) > 0) {
                        _showAxisProtection();
                        return;
                      }
                      setState(() => _canBeVariantAxis = value);
                    },
                  ),

                  if (!readOnly && _source != null)
                    _EditorSwitch(
                      title: 'Atributo activo',
                      value: _active,
                      readOnly: false,
                      onChanged: (value) {
                        if (!value &&
                            (_source?.usedAsAxisByProductCount ?? 0) > 0) {
                          _showAxisProtection();
                          return;
                        }
                        setState(() => _active = value);
                      },
                    ),
                  _buildTypeConfiguration(readOnly),
                  if (!readOnly && _source != null) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(
                        _structureLocked
                            ? 'No se puede eliminar: atributo utilizado'
                            : 'Eliminar atributo',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(readOnly ? 'Cerrar' : 'Cancelar'),
                ),
                if (!readOnly) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(140, 44),
                    ),
                    onPressed: _submit,
                    child: Text(
                      _source == null ? 'Crear atributo' : 'Guardar cambios',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeConfiguration(bool readOnly) {
    switch (_type) {
      case CategoryAttributeDataType.shortText:
        return const SizedBox.shrink();

      case CategoryAttributeDataType.number:
        return _numberConfiguration(
          readOnly: readOnly,
          title: 'Configuración del número',
        );
      case CategoryAttributeDataType.numberWithUnit:
        final magnitudes =
            widget.units.map((unit) => unit.magnitude).toSet().toList()..sort();
        final compatibleUnits = widget.units
            .where((unit) => unit.magnitude == _magnitude)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Configuración de número con unidad'),
            DropdownButtonFormField<String>(
              value: _magnitude,
              decoration: const InputDecoration(labelText: 'Magnitud *'),
              items: magnitudes
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: readOnly || _structureLocked
                  ? null
                  : (value) {
                      setState(() {
                        _magnitude = value;
                        _allowedUnits.clear();
                        _defaultUnit = null;
                      });
                    },
              validator: (value) {
                if (_type == CategoryAttributeDataType.numberWithUnit &&
                    value == null) {
                  return 'Selecciona una magnitud.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Unidades permitidas *',
              style: TextStyle(color: _text, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: compatibleUnits.map((unit) {
                final selected = _allowedUnits.contains(unit.code);
                return FilterChip(
                  label: Text(unit.label),
                  selected: selected,
                  onSelected: readOnly || _structureLocked
                      ? null
                      : (value) {
                          setState(() {
                            if (value) {
                              _allowedUnits.add(unit.code);
                              _defaultUnit ??= unit.code;
                            } else {
                              _allowedUnits.remove(unit.code);
                              if (_defaultUnit == unit.code) {
                                _defaultUnit = _allowedUnits.isEmpty
                                    ? null
                                    : _allowedUnits.first;
                              }
                            }
                          });
                        },
                );
              }).toList(),
            ),
            if (_magnitude != null && _allowedUnits.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Selecciona al menos una unidad compatible.',
                  style: TextStyle(color: _red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _allowedUnits.contains(_defaultUnit) ? _defaultUnit : null,
              decoration: const InputDecoration(
                labelText: 'Unidad predeterminada *',
              ),
              items: widget.units
                  .where((unit) => _allowedUnits.contains(unit.code))
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit.code,
                      child: Text(unit.label),
                    ),
                  )
                  .toList(),
              onChanged: readOnly || _structureLocked
                  ? null
                  : (value) => setState(() => _defaultUnit = value),
              validator: (value) {
                if (_type == CategoryAttributeDataType.numberWithUnit &&
                    value == null) {
                  return 'Selecciona la unidad predeterminada.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _numberConfiguration(
              readOnly: readOnly,
              title: 'Rango permitido',
              includeSectionTitle: false,
            ),
            const SizedBox(height: 10),
            const _Notice(
              text:
                  'Los valores se guardan también normalizados en la unidad base '
                  'para ordenar y filtrar correctamente.',
            ),
          ],
        );
      case CategoryAttributeDataType.singleList:
      case CategoryAttributeDataType.multipleList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Opciones permitidas'),
            if (_type == CategoryAttributeDataType.multipleList) ...[
              TextFormField(
                controller: _maximumSelectionsController,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad máxima seleccionable',
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 12),
            ],
            _OptionEditor(
              options: _options,
              readOnly: readOnly,
              onChanged: (options) => setState(() => _options = options),
            ),
          ],
        );
      case CategoryAttributeDataType.yesNo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('Etiquetas opcionales'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _trueLabelController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta para Sí',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _falseLabelController,
                    enabled: !readOnly,
                    decoration: const InputDecoration(
                      labelText: 'Etiqueta para No',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _numberConfiguration({
    required bool readOnly,
    required String title,
    bool includeSectionTitle = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeSectionTitle) _SectionTitle(title),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _minimumController,
                enabled: !readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Mínimo'),
                validator: _numberValidator,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _maximumController,
                enabled: !readOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Máximo'),
                validator: _numberValidator,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _decimalsController,
                enabled: !readOnly,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Decimales'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0 || parsed > 6) {
                    return 'Entre 0 y 6.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAxisProtection() async {
    final source = _source;
    if (source == null) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eje utilizado por productos'),
        content: Text(
          '${source.usedAsAxisByProductCount} productos utilizan '
          '“${source.name}” como eje. Revísalos antes de desactivar esta '
          'capacidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onShowAffectedProducts?.call();
            },
            child: const Text('Ver productos afectados'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final minimum = _parseDouble(_minimumController.text);
    final maximum = _parseDouble(_maximumController.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      _showError('El mínimo no puede ser mayor que el máximo.');
      return;
    }
    if (_type == CategoryAttributeDataType.numberWithUnit &&
        (_magnitude == null || _allowedUnits.isEmpty || _defaultUnit == null)) {
      _showError(
        'Selecciona magnitud, unidades permitidas y unidad predeterminada.',
      );
      return;
    }
    if ((_type == CategoryAttributeDataType.singleList ||
            _type == CategoryAttributeDataType.multipleList) &&
        _options.where((option) => option.active).isEmpty) {
      _showError('La lista debe tener al menos una opción activa.');
      return;
    }
    final normalizedLabels = <String>{};
    final normalizedCodes = <String>{};
    for (final option in _options) {
      if (!normalizedLabels.add(option.label.trim().toLowerCase()) ||
          !normalizedCodes.add(option.code.trim().toLowerCase())) {
        _showError('No se permiten opciones ni códigos duplicados.');
        return;
      }
    }

    final keyName = _keyController.text.trim().isEmpty
        ? _toKey(_nameController.text)
        : _toKey(_keyController.text);
    if (keyName.isEmpty || widget.reservedKeys.contains(keyName)) {
      _showError('Ya existe un atributo con ese identificador interno.');
      return;
    }

    final source = _source;
    final attribute = CategoryAttributeDefinition(
      id: source?.id ?? 'attribute-${DateTime.now().microsecondsSinceEpoch}',
      ownerCategoryId: source?.ownerCategoryId ?? widget.categoryId,
      ownerCategoryName: source?.ownerCategoryName ?? widget.categoryName,
      name: _nameController.text.trim(),
      keyName: keyName,
      helpText: _emptyToNull(_helpController.text),
      dataType: _type,
      captureLevel: _captureLevel,
      requiredToActivate: _requiredToActivate,
      visibleInTechnicalSheet: _visibleInTechnicalSheet,
      filterable: _filterable,
      canBeVariantAxis: _supportsAxis(_type) ? _canBeVariantAxis : false,
      activeForNewProducts: _activeForNewProducts,
      order: source?.order ?? 0,
      active: _active,
      inherited: false,
      textMaxLength: _type == CategoryAttributeDataType.shortText
          ? int.tryParse(_textLengthController.text.trim())
          : null,
      example: _type == CategoryAttributeDataType.shortText
          ? _emptyToNull(_exampleController.text)
          : null,
      minimum:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? minimum
          : null,
      maximum:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? maximum
          : null,
      decimals:
          _type == CategoryAttributeDataType.number ||
              _type == CategoryAttributeDataType.numberWithUnit
          ? int.tryParse(_decimalsController.text.trim()) ?? 0
          : 0,
      magnitude: _type == CategoryAttributeDataType.numberWithUnit
          ? _magnitude
          : null,
      allowedUnitCodes: _type == CategoryAttributeDataType.numberWithUnit
          ? _allowedUnits
          : const [],
      defaultUnitCode: _type == CategoryAttributeDataType.numberWithUnit
          ? _defaultUnit
          : null,
      options:
          _type == CategoryAttributeDataType.singleList ||
              _type == CategoryAttributeDataType.multipleList
          ? _options
          : const [],
      maximumSelections: _type == CategoryAttributeDataType.multipleList
          ? int.tryParse(_maximumSelectionsController.text.trim())
          : null,
      trueLabel: _type == CategoryAttributeDataType.yesNo
          ? _emptyToNull(_trueLabelController.text)
          : null,
      falseLabel: _type == CategoryAttributeDataType.yesNo
          ? _emptyToNull(_falseLabelController.text)
          : null,
      usedByProductCount: source?.usedByProductCount ?? 0,
      affectedCategoryCount: source?.affectedCategoryCount ?? 0,
      usedAsAxisByProductCount: source?.usedAsAxisByProductCount ?? 0,
      syncState: AttributeSyncState.pending,
    );
    widget.onSave(attribute);
  }

  String? _positiveIntegerValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Debe ser mayor que cero.';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (_parseDouble(value) == null) return 'Número inválido.';
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _red));
  }
}

class _OptionEditor extends StatefulWidget {
  const _OptionEditor({
    required this.options,
    required this.readOnly,
    required this.onChanged,
  });

  final List<CategoryAttributeOption> options;
  final bool readOnly;
  final ValueChanged<List<CategoryAttributeOption>> onChanged;

  @override
  State<_OptionEditor> createState() => _OptionEditorState();
}

class _OptionEditorState extends State<_OptionEditor> {
  final _labelController = TextEditingController();
  final _codeController = TextEditingController();
  String? _editingId;

  CategoryAttributeOption? get _editingOption {
    final id = _editingId;
    if (id == null) return null;
    for (final option in widget.options) {
      if (option.id == id) return option;
    }
    return null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Opción',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Código',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Estado',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: 44),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...widget.options.map(_buildOptionRow),
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Opción',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _codeController,
                  enabled: (_editingOption?.usedByProductCount ?? 0) == 0,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    isDense: true,
                    helperText: (_editingOption?.usedByProductCount ?? 0) > 0
                        ? 'Protegido por uso'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: _editingId == null
                    ? 'Agregar opción'
                    : 'Guardar opción',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: _saveOption,
                icon: Icon(
                  _editingId == null ? Icons.add_rounded : Icons.check_rounded,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildOptionRow(CategoryAttributeOption option) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              option.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              option.code,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              option.active ? 'Activa' : 'Inactiva',
              style: TextStyle(
                color: option.active ? _green : _muted,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: widget.readOnly
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Acciones de ${option.label}',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editingId = option.id;
                        _labelController.text = option.label;
                        _codeController.text = option.code;
                        setState(() {});
                      } else if (value == 'status') {
                        _updateOption(option.copyWith(active: !option.active));
                      } else if (value == 'remove') {
                        if (option.usedByProductCount > 0) {
                          _updateOption(option.copyWith(active: false));
                        } else {
                          widget.onChanged(
                            widget.options
                                .where((item) => item.id != option.id)
                                .toList(),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                        value: 'status',
                        child: Text(option.active ? 'Desactivar' : 'Activar'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          option.usedByProductCount > 0
                              ? 'Desactivar'
                              : 'Eliminar',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _saveOption() {
    final label = _labelController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? _toKey(label)
        : _toKey(_codeController.text);
    if (label.isEmpty || code.isEmpty) return;
    final duplicate = widget.options.any(
      (option) =>
          option.id != _editingId &&
          (option.label.toLowerCase() == label.toLowerCase() ||
              option.code.toLowerCase() == code.toLowerCase()),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La opción o su código ya existe.'),
          backgroundColor: _red,
        ),
      );
      return;
    }

    final updated = [...widget.options];
    if (_editingId == null) {
      updated.add(
        CategoryAttributeOption(
          id: 'option-${DateTime.now().microsecondsSinceEpoch}',
          label: label,
          code: code,
          active: true,
        ),
      );
    } else {
      final index = updated.indexWhere((option) => option.id == _editingId);
      final current = updated[index];
      updated[index] = current.copyWith(
        label: label,
        code: current.usedByProductCount > 0 ? current.code : code,
      );
    }
    _editingId = null;
    _labelController.clear();
    _codeController.clear();
    widget.onChanged(updated);
    setState(() {});
  }

  void _updateOption(CategoryAttributeOption option) {
    final updated = [...widget.options];
    final index = updated.indexWhere((item) => item.id == option.id);
    updated[index] = option;
    widget.onChanged(updated);
  }
}
