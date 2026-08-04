import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/producto_variante.dart';
import '../../domain/services/codigo_interno_generator.dart';
import '../bloc/producto_form/producto_form_bloc.dart';
import '../bloc/producto_form/producto_form_event.dart';
import '../bloc/producto_form/producto_form_state.dart';

enum _MatrixGeneralAction { generateNames, applyAttribute }

class _MatrixMeasureDraft {
  const _MatrixMeasureDraft({
    required this.id,
    required this.value,
    required this.unit,
  });

  final String id;
  final String value;
  final String unit;

  String get label {
    final cleanValue = value.trim();
    final cleanUnit = unit.trim();
    if (cleanUnit.isEmpty) return cleanValue;
    const attachedUnits = {'″', '"', '°', '%'};
    final separator = attachedUnits.contains(cleanUnit) ? '' : ' ';
    return '$cleanValue$separator$cleanUnit';
  }
}

class _MatrixCombinationDraft {
  const _MatrixCombinationDraft({
    required this.id,
    required this.key,
    required this.rowValue,
    required this.columnValue,
    required this.included,
    required this.sku,
    required this.supplierCode,
    required this.generatedName,
    required this.initialActive,
    required this.attributes,
    this.wasEdited = false,
  });

  final String id;
  final String key;
  final String rowValue;
  final String columnValue;
  final bool included;
  final String sku;
  final String supplierCode;
  final String generatedName;
  final bool initialActive;
  final Map<String, String> attributes;
  final bool wasEdited;

  static String buildKey(String rowValue, String columnValue) {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '${normalize(rowValue)}::${normalize(columnValue)}';
  }

  _MatrixCombinationDraft copyWith({
    String? id,
    bool? included,
    String? sku,
    String? supplierCode,
    String? generatedName,
    bool? initialActive,
    Map<String, String>? attributes,
    bool? wasEdited,
  }) => _MatrixCombinationDraft(
    id: id ?? this.id,
    key: key,
    rowValue: rowValue,
    columnValue: columnValue,
    included: included ?? this.included,
    sku: sku ?? this.sku,
    supplierCode: supplierCode ?? this.supplierCode,
    generatedName: generatedName ?? this.generatedName,
    initialActive: initialActive ?? this.initialActive,
    attributes: attributes ?? this.attributes,
    wasEdited: wasEdited ?? this.wasEdited,
  );
}

class _MatrixAttributeFields {
  _MatrixAttributeFields({
    String name = '',
    String value = '',
    this.managed = false,
  }) : nameController = TextEditingController(text: name),
       valueController = TextEditingController(text: value);

  final TextEditingController nameController;
  final TextEditingController valueController;
  final bool managed;

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

class ProductoMatrizStep extends StatefulWidget {
  const ProductoMatrizStep({required this.state, super.key});

  final ProductoFormState state;

  @override
  State<ProductoMatrizStep> createState() => _ProductoMatrizStepState();
}

class _ProductoMatrizStepState extends State<ProductoMatrizStep> {
  static const _matrixPrimary = Color(0xFFFFC500);
  static const _matrixInk = Color(0xFF20242B);
  static const _matrixMuted = Color(0xFF667085);
  static const _matrixBorder = Color(0xFFD5DDE8);
  static const _matrixIncluded = Color(0xFFE7F7EF);
  static const _matrixExcluded = Color(0xFFF0F2F5);

  List<String> get _matrixAxisOptions => widget.state.atributosPermitidosComoEje
      .map((attribute) => attribute.nombre)
      .toSet()
      .toList();

  final _matrixVariantFormKey = GlobalKey<FormState>();
  final _matrixSkuController = TextEditingController();
  final _matrixSupplierCodeController = TextEditingController();
  final _matrixNameController = TextEditingController();
  final List<_MatrixAttributeFields> _matrixAttributeFields = [];

  String _matrixDraftColumnAxis = '';
  String _matrixDraftRowAxis = '';
  String _matrixAppliedColumnAxis = '';
  String _matrixAppliedRowAxis = '';

  final List<_MatrixMeasureDraft> _matrixDraftColumns = [];
  final List<_MatrixMeasureDraft> _matrixDraftRows = [];

  List<_MatrixMeasureDraft> _matrixAppliedColumns = [];
  List<_MatrixMeasureDraft> _matrixAppliedRows = [];
  Map<String, _MatrixCombinationDraft> _matrixCombinations = {};
  String? _matrixFocusedKey;
  final Set<String> _matrixSelectedKeys = {};

  bool _matrixAxesDirty = false;
  bool _matrixMultiSelect = false;
  bool _matrixEditorDirty = false;
  bool _matrixEditorInitialActive = true;
  int _matrixMeasureSequence = 100;

  String get _matrixFamilyLabel {
    final family = widget.state.nombre.trim();
    return family.isEmpty ? 'Familia sin nombre' : family;
  }

  _MatrixCombinationDraft? get _matrixFocusedCombination {
    final key = _matrixFocusedKey;
    return key == null ? null : _matrixCombinations[key];
  }

  Iterable<_MatrixCombinationDraft> get _matrixIncludedCombinations =>
      _matrixCombinations.values.where((item) => item.included);

  int get _matrixIncludedCount => _matrixIncludedCombinations.length;

  int get _matrixExcludedCount =>
      _matrixCombinations.length - _matrixIncludedCount;

  int get _matrixReadyCount => _matrixIncludedCombinations
      .where(
        (item) =>
            item.sku.trim().isNotEmpty && item.generatedName.trim().isNotEmpty,
      )
      .length;

  int get _matrixDuplicateSkuCount {
    final frequencies = <String, int>{};
    for (final combination in _matrixIncludedCombinations) {
      final sku = combination.sku.trim().toUpperCase();
      if (sku.isEmpty) continue;
      frequencies[sku] = (frequencies[sku] ?? 0) + 1;
    }
    return frequencies.values.fold<int>(
      0,
      (total, count) => total + (count > 1 ? count - 1 : 0),
    );
  }

  bool get _matrixCanContinue =>
      !_matrixAxesDirty &&
      _matrixIncludedCount > 0 &&
      _matrixReadyCount == _matrixIncludedCount &&
      _matrixDuplicateSkuCount == 0;

  @override
  void initState() {
    super.initState();
    _initializeMatrix();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncVariants();
    });
  }

  @override
  void dispose() {
    _matrixSkuController.dispose();
    _matrixSupplierCodeController.dispose();
    _matrixNameController.dispose();
    for (final fields in _matrixAttributeFields) {
      fields.dispose();
    }
    super.dispose();
  }

  void _initializeMatrix() {
    final axisOptions = _matrixAxisOptions;
    if (axisOptions.isNotEmpty) {
      _matrixDraftColumnAxis = axisOptions.first;
      _matrixAppliedColumnAxis = axisOptions.first;
    }
    if (axisOptions.length > 1) {
      _matrixDraftRowAxis = axisOptions[1];
      _matrixAppliedRowAxis = axisOptions[1];
    }

    final savedVariants = widget.state.variantes;
    if (savedVariants.isEmpty ||
        _matrixAppliedColumnAxis.isEmpty ||
        _matrixAppliedRowAxis.isEmpty) {
      _matrixAppliedColumns = const [];
      _matrixAppliedRows = const [];
      _matrixCombinations = const {};
      _matrixFocusedKey = null;
      return;
    }

    _matrixDraftColumns
      ..clear()
      ..addAll(
        _measuresFromVariants(
          savedVariants,
          _matrixAppliedColumnAxis,
          'column',
        ),
      );
    _matrixDraftRows
      ..clear()
      ..addAll(
        _measuresFromVariants(savedVariants, _matrixAppliedRowAxis, 'row'),
      );
    _matrixAppliedColumns = List.of(_matrixDraftColumns);
    _matrixAppliedRows = List.of(_matrixDraftRows);

    final combinations = <String, _MatrixCombinationDraft>{};
    for (final variant in savedVariants) {
      final row = _attributeLabel(variant, _matrixAppliedRowAxis);
      final column = _attributeLabel(variant, _matrixAppliedColumnAxis);
      if (row == null || column == null) continue;
      final key = _MatrixCombinationDraft.buildKey(row, column);
      combinations[key] = _MatrixCombinationDraft(
        id: variant.id,
        key: key,
        rowValue: row,
        columnValue: column,
        included: true,
        sku: variant.sku,
        supplierCode: variant.codigoProveedor,
        generatedName: variant.nombreCorto,
        initialActive: variant.activa,
        attributes: {
          for (final attribute in variant.atributos)
            if (attribute.nombre != _matrixAppliedColumnAxis &&
                attribute.nombre != _matrixAppliedRowAxis)
              attribute.nombre: attribute.texto,
        },
        wasEdited: true,
      );
    }
    _matrixCombinations = combinations;
    _matrixFocusedKey = combinations.keys.firstOrNull;
    final focused = _matrixFocusedCombination;
    if (focused != null) _loadMatrixEditor(focused);
  }

  List<_MatrixMeasureDraft> _measuresFromVariants(
    List<ProductoVariante> variants,
    String name,
    String prefix,
  ) {
    final result = <_MatrixMeasureDraft>[];
    final seen = <String>{};
    for (final variant in variants) {
      for (final attribute in variant.atributos) {
        if (attribute.nombre != name || !seen.add(attribute.texto)) continue;
        result.add(
          _MatrixMeasureDraft(
            id: '$prefix-${result.length + 1}',
            value: attribute.valor,
            unit: attribute.unidad,
          ),
        );
      }
    }
    return result;
  }

  String? _attributeLabel(ProductoVariante variante, String name) {
    for (final attribute in variante.atributos) {
      if (attribute.nombre != name) continue;
      return _MatrixMeasureDraft(
        id: '',
        value: attribute.valor,
        unit: attribute.unidad,
      ).label;
    }
    return null;
  }

  _MatrixCombinationDraft _createDefaultMatrixCombination({
    required String rowLabel,
    required String columnLabel,
    required Iterable<String> codigosExistentes,
    bool included = false,
  }) {
    final key = _MatrixCombinationDraft.buildKey(rowLabel, columnLabel);
    return _MatrixCombinationDraft(
      id: const Uuid().v4(),
      key: key,
      rowValue: rowLabel,
      columnValue: columnLabel,
      included: included,
      sku: CodigoInternoGenerator.siguienteVariante(
        codigoFamilia: widget.state.codigo,
        codigosExistentes: codigosExistentes,
      ),
      supplierCode: '',
      generatedName: '$_matrixFamilyLabel $columnLabel × $rowLabel',
      initialActive: true,
      attributes: const {},
    );
  }

  void _loadMatrixEditor(_MatrixCombinationDraft combination) {
    _matrixVariantFormKey.currentState?.reset();
    _matrixSkuController.text = combination.sku;
    _matrixSupplierCodeController.text = combination.supplierCode;
    _matrixNameController.text = combination.generatedName;
    _matrixEditorInitialActive = combination.initialActive;

    final managedNames = widget.state.atributosDeVariante
        .where(
          (attribute) =>
              attribute.nombre != _matrixAppliedColumnAxis &&
              attribute.nombre != _matrixAppliedRowAxis,
        )
        .map((attribute) => attribute.nombre)
        .toList();
    final oldFields = List<_MatrixAttributeFields>.of(_matrixAttributeFields);
    _matrixAttributeFields
      ..clear()
      ..addAll(
        managedNames.map(
          (name) => _MatrixAttributeFields(
            name: name,
            value: combination.attributes[name] ?? '',
            managed: true,
          ),
        ),
      )
      ..addAll(
        combination.attributes.entries
            .where((entry) => !managedNames.contains(entry.key))
            .map(
              (entry) =>
                  _MatrixAttributeFields(name: entry.key, value: entry.value),
            ),
      );
    if (oldFields.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final fields in oldFields) {
          fields.dispose();
        }
      });
    }
    _matrixEditorDirty = false;
  }

  void _markMatrixEditorDirty() {
    if (_matrixEditorDirty) return;
    setState(() => _matrixEditorDirty = true);
    _notifyPending();
  }

  void _notifyPending() {
    context.read<ProductoFormBloc>().add(
      ProductoFormEdicionVarianteCambiada(
        _matrixAxesDirty || _matrixEditorDirty,
      ),
    );
  }

  void _cancelMatrixEditorChanges() {
    final combination = _matrixFocusedCombination;
    if (combination == null) return;
    setState(() => _loadMatrixEditor(combination));
    _notifyPending();
  }

  Future<bool> _confirmDiscardMatrixEditorChanges() async {
    if (!_matrixEditorDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Cambios sin guardar'),
        content: const Text(
          'Hay cambios en el detalle de la variante seleccionada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Descartar cambios',
              style: TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (discard == true) {
      final focused = _matrixFocusedCombination;
      if (focused != null) _loadMatrixEditor(focused);
      _notifyPending();
    }
    return discard == true;
  }

  Future<void> _selectMatrixCombination(
    _MatrixCombinationDraft combination,
  ) async {
    if (_matrixMultiSelect) {
      setState(() {
        if (!_matrixSelectedKeys.add(combination.key)) {
          _matrixSelectedKeys.remove(combination.key);
        }
        _matrixFocusedKey = combination.key;
      });
      return;
    }
    if (_matrixFocusedKey == combination.key) return;
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;
    _loadMatrixEditor(combination);
    setState(() => _matrixFocusedKey = combination.key);
  }

  bool _isMatrixCellSelected(String key) => _matrixMultiSelect
      ? _matrixSelectedKeys.contains(key)
      : _matrixFocusedKey == key;

  Future<void> _toggleMatrixMultiSelect() async {
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;
    if (!_matrixMultiSelect) {
      setState(() {
        _matrixMultiSelect = true;
        _matrixSelectedKeys
          ..clear()
          ..addAll(
            _matrixFocusedKey == null
                ? const <String>[]
                : <String>[_matrixFocusedKey!],
          );
      });
      return;
    }

    final nextFocusedKey = _matrixSelectedKeys.isNotEmpty
        ? _matrixSelectedKeys.last
        : _matrixFocusedKey;
    final nextFocused = nextFocusedKey == null
        ? null
        : _matrixCombinations[nextFocusedKey];
    if (nextFocused != null) _loadMatrixEditor(nextFocused);
    setState(() {
      _matrixMultiSelect = false;
      _matrixFocusedKey = nextFocusedKey;
      _matrixSelectedKeys.clear();
    });
  }

  Future<void> _showMatrixMeasureDialog({
    required bool isColumn,
    _MatrixMeasureDraft? measure,
  }) async {
    final formKey = GlobalKey<FormState>();
    final valueController = TextEditingController(text: measure?.value ?? '');
    final unitController = TextEditingController(text: measure?.unit ?? '″');
    final measures = isColumn ? _matrixDraftColumns : _matrixDraftRows;

    final result = await showDialog<_MatrixMeasureDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(measure == null ? 'Añadir medida' : 'Editar medida'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: valueController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      hintText: '3/8',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa el valor.';
                      }
                      final candidate = _MatrixMeasureDraft(
                        id: measure?.id ?? 'new',
                        value: value,
                        unit: unitController.text,
                      ).label.toLowerCase();
                      final duplicated = measures.any(
                        (item) =>
                            item.id != measure?.id &&
                            item.label.toLowerCase() == candidate,
                      );
                      return duplicated ? 'La medida ya existe.' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      hintText: '″',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerida.'
                        : null,
                  ),
                ),
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
                _MatrixMeasureDraft(
                  id:
                      measure?.id ??
                      '${isColumn ? 'column' : 'row'}-'
                          '${_matrixMeasureSequence++}',
                  value: valueController.text.trim(),
                  unit: unitController.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _matrixPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      valueController.dispose();
      unitController.dispose();
    });
    if (result == null || !mounted) return;
    setState(() {
      if (measure == null) {
        measures.add(result);
      } else {
        final index = measures.indexWhere((item) => item.id == measure.id);
        if (index >= 0) measures[index] = result;
      }
      _matrixAxesDirty = true;
    });
    _notifyPending();
  }

  Future<void> _deleteMatrixMeasure({
    required bool isColumn,
    required _MatrixMeasureDraft measure,
  }) async {
    final measures = isColumn ? _matrixDraftColumns : _matrixDraftRows;
    if (measures.length == 1) {
      _showMatrixMessage('Cada eje debe conservar al menos una medida.');
      return;
    }
    final affectsEditedVariants = _matrixCombinations.values.any(
      (combination) =>
          combination.wasEdited &&
          (isColumn
              ? combination.columnValue == measure.label
              : combination.rowValue == measure.label),
    );
    if (affectsEditedVariants) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Eliminar medida'),
          content: Text(
            'La medida ${measure.label} contiene variantes editadas. '
            'Al actualizar la matriz, esas variantes se eliminarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Eliminar medida',
                style: TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      measures.removeWhere((item) => item.id == measure.id);
      _matrixAxesDirty = true;
    });
    _notifyPending();
  }

  void _changeMatrixAxis({required bool isColumn, required String value}) {
    final otherAxis = isColumn ? _matrixDraftRowAxis : _matrixDraftColumnAxis;
    if (value == otherAxis) {
      _showMatrixMessage(
        'El eje horizontal y el vertical deben ser diferentes.',
      );
      return;
    }
    setState(() {
      if (isColumn) {
        _matrixDraftColumnAxis = value;
      } else {
        _matrixDraftRowAxis = value;
      }
      _matrixAxesDirty = true;
    });
    _notifyPending();
  }

  Future<void> _updateVariantMatrix() async {
    if (!_matrixAxesDirty) return;
    if (_matrixDraftColumns.isEmpty || _matrixDraftRows.isEmpty) {
      _showMatrixMessage('Agrega al menos una medida en cada eje.');
      return;
    }
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;

    final axesUnchanged =
        _matrixAppliedColumnAxis == _matrixDraftColumnAxis &&
        _matrixAppliedRowAxis == _matrixDraftRowAxis;
    final nextCombinations = <String, _MatrixCombinationDraft>{};
    for (final row in _matrixDraftRows) {
      for (final column in _matrixDraftColumns) {
        final key = _MatrixCombinationDraft.buildKey(row.label, column.label);
        final existing = axesUnchanged ? _matrixCombinations[key] : null;
        nextCombinations[key] =
            existing ??
            _createDefaultMatrixCombination(
              rowLabel: row.label,
              columnLabel: column.label,
              codigosExistentes: [
                ..._matrixCombinations.values.map((item) => item.sku),
                ...nextCombinations.values.map((item) => item.sku),
              ],
            );
      }
    }

    var nextFocusedKey = _matrixFocusedKey;
    if (nextFocusedKey == null ||
        !nextCombinations.containsKey(nextFocusedKey)) {
      final included = nextCombinations.values
          .where((item) => item.included)
          .toList();
      nextFocusedKey = included.isNotEmpty
          ? included.first.key
          : nextCombinations.keys.firstOrNull;
    }
    final nextFocused = nextFocusedKey == null
        ? null
        : nextCombinations[nextFocusedKey];
    if (nextFocused != null) _loadMatrixEditor(nextFocused);
    setState(() {
      _matrixAppliedColumnAxis = _matrixDraftColumnAxis;
      _matrixAppliedRowAxis = _matrixDraftRowAxis;
      _matrixAppliedColumns = List.of(_matrixDraftColumns);
      _matrixAppliedRows = List.of(_matrixDraftRows);
      _matrixCombinations = nextCombinations;
      _matrixFocusedKey = nextFocusedKey;
      _matrixSelectedKeys.removeWhere(
        (key) => !nextCombinations.containsKey(key),
      );
      _matrixAxesDirty = false;
    });
    _notifyPending();
    _syncVariants();
    _showMatrixMessage(
      'Matriz actualizada. Se conservaron las combinaciones sin cambios.',
    );
  }

  Set<String> _matrixCurrentTargets({bool allWhenNoSelection = false}) {
    if (_matrixMultiSelect && _matrixSelectedKeys.isNotEmpty) {
      return Set.of(_matrixSelectedKeys);
    }
    if (!allWhenNoSelection && _matrixFocusedKey != null) {
      return {_matrixFocusedKey!};
    }
    return _matrixCombinations.values
        .where((item) => item.included)
        .map((item) => item.key)
        .toSet();
  }

  Future<void> _includeAllMatrixCombinations() async {
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;
    setState(() {
      _matrixCombinations = {
        for (final entry in _matrixCombinations.entries)
          entry.key: entry.value.copyWith(included: true),
      };
    });
    final focused = _matrixFocusedCombination;
    if (!_matrixMultiSelect && focused != null) _loadMatrixEditor(focused);
    _syncVariants();
  }

  void _setSelectedMatrixCombinationsIncluded(bool included) {
    final targets = _matrixCurrentTargets();
    if (targets.isEmpty) {
      _showMatrixMessage('Selecciona al menos una combinación.');
      return;
    }
    setState(() {
      _matrixCombinations = {
        for (final entry in _matrixCombinations.entries)
          entry.key: targets.contains(entry.key)
              ? entry.value.copyWith(included: included)
              : entry.value,
      };
    });
    final focused = _matrixFocusedCombination;
    if (!_matrixMultiSelect && focused != null) _loadMatrixEditor(focused);
    _syncVariants();
  }

  Future<void> _toggleFocusedCombinationExistence() async {
    final focused = _matrixFocusedCombination;
    if (focused == null) return;
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;
    final updated = focused.copyWith(included: !focused.included);
    _loadMatrixEditor(updated);
    setState(() => _matrixCombinations[focused.key] = updated);
    _syncVariants();
  }

  Future<void> _handleMatrixGeneralAction(_MatrixGeneralAction action) async {
    if (!await _confirmDiscardMatrixEditorChanges() || !mounted) return;
    switch (action) {
      case _MatrixGeneralAction.generateNames:
        _generateMatrixNames();
      case _MatrixGeneralAction.applyAttribute:
        await _showApplyMatrixAttributeDialog();
    }
  }

  void _generateMatrixNames() {
    final targets = _matrixCurrentTargets(allWhenNoSelection: true);
    setState(() {
      _matrixCombinations = {
        for (final entry in _matrixCombinations.entries)
          entry.key: targets.contains(entry.key) && entry.value.included
              ? entry.value.copyWith(
                  generatedName:
                      '$_matrixFamilyLabel '
                      '${entry.value.columnValue} × '
                      '${entry.value.rowValue}',
                  wasEdited: true,
                )
              : entry.value,
      };
    });
    final focused = _matrixFocusedCombination;
    if (!_matrixMultiSelect && focused != null) _loadMatrixEditor(focused);
    _syncVariants();
    _showMatrixMessage('Nombres generados correctamente.');
  }

  Future<void> _showApplyMatrixAttributeDialog() async {
    final targets = _matrixCurrentTargets();
    if (targets.isEmpty) {
      _showMatrixMessage('Selecciona al menos una combinación.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    final result = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Aplicar atributo'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Atributo',
                      hintText: 'Material',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerido.'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      hintText: 'Acero inoxidable 304',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerido.'
                        : null,
                  ),
                ),
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
                MapEntry(
                  nameController.text.trim(),
                  valueController.text.trim(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _matrixPrimary,
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Aplicar',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      valueController.dispose();
    });
    if (result == null || !mounted) return;
    setState(() {
      _matrixCombinations = {
        for (final entry in _matrixCombinations.entries)
          entry.key: targets.contains(entry.key) && entry.value.included
              ? entry.value.copyWith(
                  attributes: {
                    ...entry.value.attributes,
                    result.key: result.value,
                  },
                  wasEdited: true,
                )
              : entry.value,
      };
    });
    final focused = _matrixFocusedCombination;
    if (!_matrixMultiSelect && focused != null) _loadMatrixEditor(focused);
    _syncVariants();
    _showMatrixMessage(
      'Atributo aplicado a ${targets.length} combinación(es).',
    );
  }

  String? _validateMatrixSku(String? value) {
    final sku = value?.trim().toUpperCase() ?? '';
    if (sku.isEmpty) return 'No se pudo generar el código interno.';
    final duplicated = _matrixIncludedCombinations.any(
      (item) =>
          item.key != _matrixFocusedKey && item.sku.trim().toUpperCase() == sku,
    );
    return duplicated ? 'El código interno está duplicado.' : null;
  }

  void _addMatrixAttributeField() {
    setState(() {
      _matrixAttributeFields.add(_MatrixAttributeFields());
      _matrixEditorDirty = true;
    });
    _notifyPending();
  }

  void _removeMatrixAttributeField(int index) {
    final fields = _matrixAttributeFields.removeAt(index);
    setState(() => _matrixEditorDirty = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => fields.dispose());
    _notifyPending();
  }

  void _saveMatrixVariantDetails() {
    final focused = _matrixFocusedCombination;
    if (focused == null || !focused.included) return;
    if (!(_matrixVariantFormKey.currentState?.validate() ?? false)) return;

    final attributes = <String, String>{};
    for (final fields in _matrixAttributeFields) {
      final name = fields.nameController.text.trim();
      final value = fields.valueController.text.trim();
      if (name.isEmpty && value.isEmpty) continue;
      if (name.isEmpty || value.isEmpty) {
        _showMatrixMessage(
          'Completa o elimina los atributos adicionales incompletos.',
        );
        return;
      }
      if (attributes.containsKey(name)) {
        _showMatrixMessage('El atributo “$name” está repetido.');
        return;
      }
      attributes[name] = value;
    }

    final updated = focused.copyWith(
      sku: _matrixSkuController.text.trim().toUpperCase(),
      supplierCode: _matrixSupplierCodeController.text.trim().toUpperCase(),
      generatedName: _matrixNameController.text.trim(),
      initialActive: _matrixEditorInitialActive,
      attributes: attributes,
      wasEdited: true,
    );
    setState(() {
      _matrixCombinations[focused.key] = updated;
      _matrixEditorDirty = false;
    });
    _loadMatrixEditor(updated);
    _notifyPending();
    _syncVariants();
    _showMatrixMessage('Cambios de la variante guardados.');
  }

  void _syncVariants() {
    if (!mounted) return;
    final variants = _matrixIncludedCombinations
        .map(_combinationToVariant)
        .toList();
    context.read<ProductoFormBloc>()
      ..add(ProductoFormVariantesReemplazadas(variants))
      ..add(
        ProductoFormMatrizResumenCambiado(
          total: _matrixCombinations.length,
          excluidas: _matrixExcludedCount,
        ),
      );
  }

  ProductoVariante _combinationToVariant(_MatrixCombinationDraft combination) {
    final column = _matrixAppliedColumns.firstWhere(
      (item) => item.label == combination.columnValue,
    );
    final row = _matrixAppliedRows.firstWhere(
      (item) => item.label == combination.rowValue,
    );
    return ProductoVariante(
      id: combination.id,
      sku: combination.sku.trim().toUpperCase(),
      codigoProveedor: combination.supplierCode.trim().toUpperCase(),
      nombreCorto: combination.generatedName.trim(),
      atributos: [
        AtributoProductoVariante(
          nombre: _matrixAppliedColumnAxis,
          valor: column.value,
          unidad: column.unit,
        ),
        AtributoProductoVariante(
          nombre: _matrixAppliedRowAxis,
          valor: row.value,
          unidad: row.unit,
        ),
        ...combination.attributes.entries.map(
          (attribute) =>
              AtributoProductoVariante.fromText(attribute.key, attribute.value),
        ),
      ],
      activa: combination.initialActive,
    );
  }

  void _showMatrixMessage(String message) {
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
                    'Matriz de variantes',
                    style: TextStyle(
                      color: _matrixInk,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Combina dos atributos para generar artículos exactos. '
                    'Cada combinación incluida creará una variante.',
                    style: TextStyle(color: _matrixMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            _buildMatrixFamilyChip(),
          ],
        ),
        const SizedBox(height: 20),
        _buildMatrixAxesCard(),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1040;
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMatrixCard(),
                  const SizedBox(height: 18),
                  _buildMatrixEditorPanel(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildMatrixCard()),
                const SizedBox(width: 20),
                Expanded(flex: 3, child: _buildMatrixEditorPanel()),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _buildMatrixFamilyChip() => Container(
    constraints: const BoxConstraints(maxWidth: 420),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3C4),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      'Familia: $_matrixFamilyLabel',
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _matrixInk,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _buildMatrixAxesCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xFFF8FAFC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: _matrixBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(19),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final updateButton = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                key: const Key('actualizar_matriz'),
                onPressed: _matrixAxesDirty ? _updateVariantMatrix : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar matriz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _matrixInk,
                  disabledForegroundColor: const Color(0xFF98A2B3),
                  minimumSize: const Size(170, 46),
                  side: BorderSide(
                    color: _matrixAxesDirty
                        ? const Color(0xFF98A2B3)
                        : const Color(0xFFD0D5DD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              if (_matrixAxesDirty) ...[
                const SizedBox(height: 6),
                const Text(
                  'Cambios sin aplicar',
                  style: TextStyle(
                    color: Color(0xFFB54708),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMatrixAxisEditor(isColumn: true),
                const SizedBox(height: 18),
                _buildMatrixAxisEditor(isColumn: false),
                const SizedBox(height: 18),
                updateButton,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMatrixAxisEditor(isColumn: true)),
              const SizedBox(width: 24),
              Expanded(child: _buildMatrixAxisEditor(isColumn: false)),
              const SizedBox(width: 24),
              updateButton,
            ],
          );
        },
      ),
    ),
  );

  Widget _buildMatrixAxisEditor({required bool isColumn}) {
    final axis = isColumn ? _matrixDraftColumnAxis : _matrixDraftRowAxis;
    final measures = isColumn ? _matrixDraftColumns : _matrixDraftRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isColumn ? 'Columnas ·' : 'Filas ·',
              style: const TextStyle(
                color: _matrixMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: axis,
                  isDense: true,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: const TextStyle(
                    color: _matrixInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  items: _matrixAxisOptions
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value != axis) {
                      _changeMatrixAxis(isColumn: isColumn, value: value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final measure in measures)
              InputChip(
                label: Text(measure.label),
                backgroundColor: Colors.white,
                deleteIcon: const Icon(Icons.close, size: 16),
                deleteButtonTooltipMessage: 'Eliminar ${measure.label}',
                side: const BorderSide(color: _matrixBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _showMatrixMeasureDialog(
                  isColumn: isColumn,
                  measure: measure,
                ),
                onDeleted: () =>
                    _deleteMatrixMeasure(isColumn: isColumn, measure: measure),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 17),
              label: const Text('Añadir medida'),
              backgroundColor: const Color(0xFFFFF8DD),
              side: const BorderSide(color: _matrixPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => _showMatrixMeasureDialog(isColumn: isColumn),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatrixCard() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: _matrixBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Combinaciones generadas',
                    style: TextStyle(
                      color: _matrixInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_matrixCombinations.length} combinaciones · '
                    '$_matrixIncludedCount variantes a crear · '
                    '$_matrixExcludedCount no existen',
                    style: const TextStyle(color: _matrixMuted, fontSize: 12),
                  ),
                ],
              ),
              _buildMatrixGeneralToolbar(),
            ],
          ),
          if (_matrixMultiSelect && _matrixSelectedKeys.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildMatrixSelectionBar(),
          ],
          const SizedBox(height: 16),
          _buildVariantMatrixTable(),
          const SizedBox(height: 16),
          _buildMatrixValidationSummary(),
        ],
      ),
    ),
  );

  Widget _buildMatrixGeneralToolbar() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: _includeAllMatrixCombinations,
        icon: const Icon(Icons.done_all, size: 18),
        label: const Text('Incluir todas'),
        style: _matrixToolbarButtonStyle(),
      ),
      OutlinedButton.icon(
        key: const Key('seleccionar_varias_matriz'),
        onPressed: _toggleMatrixMultiSelect,
        icon: Icon(
          _matrixMultiSelect ? Icons.close : Icons.library_add_check_outlined,
          size: 18,
        ),
        label: Text(
          _matrixMultiSelect ? 'Cerrar selección' : 'Seleccionar varias',
        ),
        style: _matrixToolbarButtonStyle(selected: _matrixMultiSelect),
      ),
      PopupMenuButton<_MatrixGeneralAction>(
        onSelected: _handleMatrixGeneralAction,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _MatrixGeneralAction.generateNames,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.auto_fix_high_outlined),
              title: Text('Generar nombres automáticamente'),
            ),
          ),
          PopupMenuItem(
            value: _MatrixGeneralAction.applyAttribute,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.tune),
              title: Text('Aplicar atributo a las seleccionadas'),
            ),
          ),
        ],
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFB9C2CF)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Más acciones',
                style: TextStyle(
                  color: _matrixInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      ),
    ],
  );

  ButtonStyle _matrixToolbarButtonStyle({bool selected = false}) =>
      OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: selected ? const Color(0xFFFFF3C4) : Colors.white,
        foregroundColor: _matrixInk,
        minimumSize: const Size(0, 42),
        side: BorderSide(
          color: selected ? _matrixPrimary : const Color(0xFFB9C2CF),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _buildMatrixSelectionBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8DD),
      border: Border.all(color: const Color(0xFFFFDF70)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${_matrixSelectedKeys.length} seleccionadas',
            style: const TextStyle(
              color: _matrixInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _setSelectedMatrixCombinationsIncluded(true),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Incluir'),
        ),
        TextButton.icon(
          onPressed: () => _setSelectedMatrixCombinationsIncluded(false),
          icon: const Icon(Icons.block, size: 18),
          label: const Text('Marcar como no existe'),
        ),
        TextButton.icon(
          onPressed: _showApplyMatrixAttributeDialog,
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Aplicar atributo'),
        ),
      ],
    ),
  );

  Widget _buildVariantMatrixTable() {
    const rowHeaderWidth = 160.0;
    const combinationWidth = 154.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final calculatedWidth =
            rowHeaderWidth + (_matrixAppliedColumns.length * combinationWidth);
        final tableWidth = calculatedWidth < constraints.maxWidth
            ? constraints.maxWidth
            : calculatedWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  columnWidths: {
                    0: const FixedColumnWidth(rowHeaderWidth),
                    for (
                      var index = 0;
                      index < _matrixAppliedColumns.length;
                      index++
                    )
                      index + 1: const FixedColumnWidth(combinationWidth),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: _matrixBorder),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF0F3F7)),
                      children: [
                        _buildMatrixHeaderCell(
                          '$_matrixAppliedRowAxis ↓ / '
                          '$_matrixAppliedColumnAxis →',
                          leftAligned: true,
                        ),
                        for (final column in _matrixAppliedColumns)
                          _buildMatrixHeaderCell(column.label),
                      ],
                    ),
                    for (final row in _matrixAppliedRows)
                      TableRow(
                        children: [
                          _buildMatrixRowHeader(row.label),
                          for (final column in _matrixAppliedColumns)
                            _buildMatrixCombinationCell(
                              _matrixCombinations[_MatrixCombinationDraft.buildKey(
                                row.label,
                                column.label,
                              )]!,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatrixHeaderCell(String text, {bool leftAligned = false}) =>
      Container(
        constraints: const BoxConstraints(minHeight: 46),
        alignment: leftAligned ? Alignment.centerLeft : Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _matrixMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _buildMatrixRowHeader(String text) => Container(
    constraints: const BoxConstraints(minHeight: 60),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white,
    child: Text(
      text,
      style: const TextStyle(
        color: _matrixInk,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _buildMatrixCombinationCell(_MatrixCombinationDraft combination) {
    final selected = _isMatrixCellSelected(combination.key);
    final included = combination.included;
    final background = included ? _matrixIncluded : _matrixExcluded;
    final foreground = included
        ? const Color(0xFF087443)
        : const Color(0xFF667085);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${combination.columnValue} por ${combination.rowValue}, '
          '${included ? 'incluida' : 'no existe'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: () => _selectMatrixCombination(combination),
            borderRadius: BorderRadius.circular(9),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected ? _matrixPrimary : Colors.transparent,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    included ? Icons.check_circle_outline : Icons.block,
                    size: 16,
                    color: foreground,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      included ? 'Incluida' : 'No existe',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.adjust,
                      size: 14,
                      color: Color(0xFF9A7100),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixValidationSummary() {
    final ready = _matrixCanContinue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFF0FDF4) : const Color(0xFFFFFAEB),
        border: Border.all(
          color: ready ? const Color(0xFFABEFC6) : const Color(0xFFFEC84B),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.verified_outlined : Icons.info_outline,
            size: 19,
            color: ready ? const Color(0xFF067647) : const Color(0xFFB54708),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _matrixAxesDirty
                  ? 'Actualiza la matriz para validar las variantes.'
                  : '$_matrixReadyCount variantes listas · '
                        '$_matrixDuplicateSkuCount códigos internos duplicados',
              style: TextStyle(
                color: ready
                    ? const Color(0xFF067647)
                    : const Color(0xFF7A2E0E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixEditorPanel() {
    if (_matrixMultiSelect) return _buildMatrixMultiSelectionPanel();
    final combination = _matrixFocusedCombination;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: _matrixBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: combination == null
            ? const Text(
                'Selecciona una combinación para editarla.',
                style: TextStyle(color: _matrixMuted),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Detalle de variante',
                    style: TextStyle(
                      color: _matrixInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Combinación',
                    style: TextStyle(
                      color: _matrixMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${combination.columnValue} × '
                    '${combination.rowValue}',
                    style: const TextStyle(
                      color: _matrixInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _buildMatrixExistenceControl(combination),
                  const SizedBox(height: 17),
                  if (!combination.included)
                    _buildExcludedMatrixNotice()
                  else
                    _buildMatrixVariantForm(),
                ],
              ),
      ),
    );
  }

  Widget _buildMatrixExistenceControl(_MatrixCombinationDraft combination) {
    final included = combination.included;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: included ? _matrixIncluded : _matrixExcluded,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_outline : Icons.block,
            size: 18,
            color: included ? const Color(0xFF087443) : const Color(0xFF667085),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              included ? 'Combinación incluida' : 'No existe',
              style: TextStyle(
                color: included
                    ? const Color(0xFF087443)
                    : const Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            key: const Key('alternar_combinacion_matriz'),
            onPressed: _toggleFocusedCombinationExistence,
            child: Text(
              included ? 'Excluir' : 'Incluir',
              style: const TextStyle(
                color: _matrixInk,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExcludedMatrixNotice() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _matrixBorder),
      borderRadius: BorderRadius.circular(11),
    ),
    child: const Column(
      children: [
        Icon(Icons.remove_circle_outline, color: _matrixMuted, size: 30),
        SizedBox(height: 9),
        Text(
          'Esta combinación no generará una variante.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _matrixInk, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Puedes incluirla nuevamente sin perder los datos guardados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _matrixMuted, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _buildMatrixVariantForm() => Form(
    key: _matrixVariantFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMatrixTextField(
          fieldKey: const Key('matriz_codigo_interno'),
          label: 'Código interno',
          controller: _matrixSkuController,
          hint: 'VAR-XXXXXXXXXX',
          validator: _validateMatrixSku,
          readOnly: true,
        ),
        const SizedBox(height: 14),
        _buildMatrixTextField(
          fieldKey: const Key('matriz_codigo_proveedor'),
          label: 'Código del proveedor (opcional)',
          controller: _matrixSupplierCodeController,
          hint: 'PER-384',
        ),
        const SizedBox(height: 14),
        _buildMatrixTextField(
          fieldKey: const Key('matriz_nombre'),
          label: 'Nombre generado',
          controller: _matrixNameController,
          hint: 'Perno hexagonal UNC 304 3/8″ × 4″',
          maxLines: 2,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Ingresa el nombre de la variante.'
              : null,
        ),
        const SizedBox(height: 14),
        const Text(
          'Estado inicial',
          style: TextStyle(
            color: _matrixMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<bool>(
          key: ValueKey(
            'matrix-active-$_matrixFocusedKey-$_matrixEditorInitialActive',
          ),
          initialValue: _matrixEditorInitialActive,
          decoration: _matrixInputDecoration(),
          items: const [
            DropdownMenuItem(value: true, child: Text('Activa')),
            DropdownMenuItem(value: false, child: Text('Inactiva')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _matrixEditorInitialActive = value;
              _matrixEditorDirty = true;
            });
            _notifyPending();
          },
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Atributos técnicos de la variante',
                style: TextStyle(
                  color: _matrixInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addMatrixAttributeField,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Añadir'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_matrixAttributeFields.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _matrixBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Sin atributos adicionales. '
              'Los atributos compartidos permanecen en la familia.',
              style: TextStyle(color: _matrixMuted, fontSize: 11, height: 1.35),
            ),
          )
        else
          for (
            var index = 0;
            index < _matrixAttributeFields.length;
            index++
          ) ...[
            _buildMatrixAttributeRow(index),
            if (index != _matrixAttributeFields.length - 1)
              const SizedBox(height: 9),
          ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _matrixEditorDirty
                    ? _cancelMatrixEditorChanges
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _matrixInk,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Color(0xFFB9C2CF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                key: const Key('guardar_variante_matriz'),
                onPressed: _saveMatrixVariantDetails,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _matrixPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildMatrixTextField({
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _matrixMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        key: fieldKey,
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onChanged: readOnly ? null : (_) => _markMatrixEditorDirty(),
        decoration: _matrixInputDecoration(hint: hint),
      ),
    ],
  );

  InputDecoration _matrixInputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _matrixBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _matrixBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _matrixPrimary, width: 2),
    ),
  );

  Widget _buildMatrixAttributeRow(int index) {
    final fields = _matrixAttributeFields[index];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: fields.nameController,
            readOnly: fields.managed,
            onChanged: fields.managed ? null : (_) => _markMatrixEditorDirty(),
            decoration: _matrixInputDecoration(hint: 'Material'),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: TextField(
            controller: fields.valueController,
            onChanged: (_) => _markMatrixEditorDirty(),
            decoration: _matrixInputDecoration(hint: 'Acero inoxidable 304'),
          ),
        ),
        const SizedBox(width: 3),
        IconButton(
          onPressed: () => _removeMatrixAttributeField(index),
          tooltip: 'Eliminar atributo',
          color: const Color(0xFFB42318),
          icon: const Icon(Icons.close, size: 19),
        ),
      ],
    );
  }

  Widget _buildMatrixMultiSelectionPanel() => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: const Color(0xFFF8FAFC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: _matrixBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Icon(
            Icons.library_add_check_outlined,
            size: 34,
            color: _matrixMuted,
          ),
          const SizedBox(height: 10),
          Text(
            '${_matrixSelectedKeys.length} combinaciones seleccionadas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _matrixInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Usa la barra contextual sobre la matriz para incluir, '
            'excluir o aplicar atributos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _matrixMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _toggleMatrixMultiSelect,
            style: _matrixToolbarButtonStyle(),
            child: const Text('Finalizar selección'),
          ),
        ],
      ),
    ),
  );
}
