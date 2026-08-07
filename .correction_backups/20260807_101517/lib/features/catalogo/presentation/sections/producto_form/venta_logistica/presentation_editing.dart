part of '../venta_logistica_section.dart';

extension _Step4PresentationEditing on _Step4SalesLogisticsContentPanelState {
  String _newId(String prefix) {
    _idSequence += 1;
    return '$prefix-$_idSequence';
  }

  void _emitChanged() {
    widget.onChanged?.call(_draft);
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================================
  // LÓGICA · PRESENTACIONES
  // ==========================================================================

  void _startNewPresentation({bool rebuild = true}) {
    _editingPresentationIndex = null;
    _presentationNameController.clear();
    _presentationEquivalentController.text = '1';
    _presentationMinimumController.text = '1';
    _presentationIncrementController.text = '1';
    _presentationBaseUnit = widget.baseUnits.contains('PZA')
        ? 'PZA'
        : widget.baseUnits.first;
    _presentationAllowsDecimals = false;
    _presentationIsDefault = _presentations.isEmpty;
    _presentationForAllVariants = true;
    _presentationVariantIds = {..._allVariantIds};
    _presentationVariantRules = {};

    if (rebuild && mounted) {
      _update(() {});
    }
  }

  void _loadPresentation(int index, {bool rebuild = true}) {
    final presentation = _presentations[index];
    _editingPresentationIndex = index;
    _presentationNameController.text = presentation.name;
    _presentationEquivalentController.text = _step4PlainNumber(
      presentation.equivalentTo,
    );
    _presentationMinimumController.text = _step4PlainNumber(
      presentation.minimumOrder,
    );
    _presentationIncrementController.text = _step4PlainNumber(
      presentation.purchaseIncrement,
    );
    _presentationBaseUnit = presentation.baseUnit;
    _presentationAllowsDecimals = presentation.allowsDecimals;
    _presentationIsDefault = presentation.defaultVariantIds.isNotEmpty;
    _presentationVariantIds = {...presentation.assignedVariantIds};
    _presentationVariantRules = {...presentation.variantRules};
    _presentationForAllVariants =
        _presentationVariantIds.length == _allVariantIds.length &&
        _presentationVariantIds.containsAll(_allVariantIds);

    if (rebuild && mounted) {
      _update(() {});
    }
  }

  void _cancelPresentationChanges() {
    final index = _editingPresentationIndex;
    if (index == null) {
      _startNewPresentation();
      return;
    }

    _loadPresentation(index);
  }

  Future<void> _editPresentationVariantRules() async {
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
          text: _step4PlainNumber(
            rule?.purchaseIncrement ?? inheritedIncrement,
          ),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  hint: 'Equivale a',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: fields[1],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  hint: 'Pedido mínimo',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: fields[2],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDecoration(
                                  hint: 'Incremento',
                                ),
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
                if (equivalent == null ||
                    minimum == null ||
                    increment == null) {
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
    _update(() => _presentationVariantRules = result);
  }
}
