part of '../precios_section.dart';

extension _Step5BulkAndPriceLists on _Step5PricingPanelState {
  Future<_BulkPriceResult?> _showBulkDialog(
    int selectedCount,
    bool mixedPresentations,
  ) async {
    var rawPrice = '';
    var configuration = PriceConfigurationType.fixed;

    final result = await showDialog<_BulkPriceResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Configurar $selectedCount seleccionadas'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<PriceConfigurationType>(
                      value: configuration,
                      decoration: _inputDecoration('Configuración'),
                      items: const [
                        DropdownMenuItem(
                          value: PriceConfigurationType.fixed,
                          child: Text('Precio fijo'),
                        ),
                        DropdownMenuItem(
                          value: PriceConfigurationType.quote,
                          child: Text('Por cotizar'),
                        ),
                        DropdownMenuItem(
                          value: PriceConfigurationType.unconfigured,
                          child: Text('Dejar pendiente'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          configuration = value;
                        });
                      },
                    ),
                    if (configuration == PriceConfigurationType.fixed) ...[
                      const SizedBox(height: 16),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          rawPrice = value;
                        },
                        decoration: _inputDecoration(
                          'Precio por presentación',
                          prefixText:
                              '${_currencySymbol(_selectedList.currencyCode)} ',
                        ),
                      ),
                    ],
                    if (mixedPresentations) ...[
                      const SizedBox(height: 14),
                      _buildInlineNote(
                        'La selección contiene presentaciones diferentes. '
                        'Antes de copiar un precio fijo se solicitará '
                        'confirmación.',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Los rangos por cantidad se configuran individualmente '
                      'para respetar el pedido mínimo y el incremento de cada '
                      'presentación.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    double? price;

                    if (configuration == PriceConfigurationType.fixed) {
                      price = _parseDecimal(rawPrice);
                      if (price == null || price < 0) {
                        _showMessage(
                          'Ingresa un precio válido mayor o igual a 0.',
                        );
                        return;
                      }

                      if (price == 0 && !await _confirmFreePrice()) {
                        return;
                      }
                    }

                    if (!dialogContext.mounted) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      _BulkPriceResult(
                        configuration: configuration,
                        fixedPrice: price,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _selectPriceLists() async {
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
    _update(() {
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

  void _changeSelectedList(String listId) {
    if (listId == _selectedListId || !_lists.any((item) => item.id == listId)) {
      return;
    }

    _update(() {
      _selectedListId = listId;
      _selectedPriceKeys.clear();
      _presentationFilterId = null;
      _filter = PriceFilter.all;
      _closeEditor();
    });
  }

  void _requestSelectedListChange(String? listId) {
    if (listId == null || listId == _selectedListId) {
      return;
    }

    // DropdownButton notifica mientras su ruta emergente termina de cerrarse.
    // Cambiar el subárbol en el mismo callback puede desactivar dependencias
    // que todavía pertenecen al overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _changeSelectedList(listId);
      }
    });
  }
}
