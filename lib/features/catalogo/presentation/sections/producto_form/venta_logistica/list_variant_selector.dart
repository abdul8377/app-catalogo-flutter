part of '../venta_logistica_section.dart';

extension _Step4ListVariantSelector on _Step4SalesLogisticsContentPanelState {
  Future<Set<String>?> _selectVariants(Set<String> initialSelection) {
    if (widget.variantLayout == Step4VariantLayout.single) {
      return Future.value({..._allVariantIds});
    }

    if (widget.variantLayout == Step4VariantLayout.matrix &&
        widget.variants.every(
          (item) => item.rowValue != null && item.columnValue != null,
        )) {
      return _showMatrixVariantSelector(initialSelection);
    }

    return _showListVariantSelector(initialSelection);
  }

  Future<Set<String>?> _showListVariantSelector(Set<String> initialSelection) {
    final selected = {...initialSelection};

    return showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Variantes seleccionadas'),
              content: SizedBox(
                width: 560,
                height: 470,
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: selected.isEmpty
                          ? false
                          : selected.length == widget.variants.length
                          ? true
                          : null,
                      tristate:
                          selected.isNotEmpty &&
                          selected.length != widget.variants.length,
                      title: Text(
                        'Seleccionar todas (${widget.variants.length})',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value ?? false) {
                            selected
                              ..clear()
                              ..addAll(_allVariantIds);
                          } else {
                            selected.clear();
                          }
                        });
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: widget.variants.length,
                        itemBuilder: (context, index) {
                          final variant = widget.variants[index];
                          return CheckboxListTile(
                            value: selected.contains(variant.id),
                            title: Text(variant.label),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (value) {
                              setDialogState(() {
                                if (value ?? false) {
                                  selected.add(variant.id);
                                } else {
                                  selected.remove(variant.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, {...selected}),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _ink,
                  ),
                  child: Text('Aplicar selección (${selected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
