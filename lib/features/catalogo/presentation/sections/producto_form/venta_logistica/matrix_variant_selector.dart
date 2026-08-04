part of '../venta_logistica_section.dart';

extension _Step4MatrixVariantSelector on _Step4SalesLogisticsContentPanelState {
  Future<Set<String>?> _showMatrixVariantSelector(
    Set<String> initialSelection,
  ) async {
    final selected = {...initialSelection};
    final matrixScrollController = ScrollController();
    final rows = widget.variants.map((item) => item.rowValue!).toSet().toList();
    final columns = widget.variants
        .map((item) => item.columnValue!)
        .toSet()
        .toList();

    Step4VariantOption? cell(String row, String column) {
      for (final variant in widget.variants) {
        if (variant.rowValue == row && variant.columnValue == column) {
          return variant;
        }
      }
      return null;
    }

    bool rowSelected(String row) {
      final ids = widget.variants
          .where((item) => item.rowValue == row)
          .map((item) => item.id)
          .toSet();
      return ids.isNotEmpty && selected.containsAll(ids);
    }

    bool columnSelected(String column) {
      final ids = widget.variants
          .where((item) => item.columnValue == column)
          .map((item) => item.id)
          .toSet();
      return ids.isNotEmpty && selected.containsAll(ids);
    }

    void toggleRow(String row, bool value) {
      final ids = widget.variants
          .where((item) => item.rowValue == row)
          .map((item) => item.id);
      if (value) {
        selected.addAll(ids);
      } else {
        selected.removeAll(ids);
      }
    }

    void toggleColumn(String column, bool value) {
      final ids = widget.variants
          .where((item) => item.columnValue == column)
          .map((item) => item.id);
      if (value) {
        selected.addAll(ids);
      } else {
        selected.removeAll(ids);
      }
    }

    try {
      return await showDialog<Set<String>>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Seleccionar en la matriz'),
                content: SizedBox(
                  width: 880,
                  height: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: selected.isEmpty
                                ? false
                                : selected.length == widget.variants.length
                                ? true
                                : null,
                            tristate:
                                selected.isNotEmpty &&
                                selected.length != widget.variants.length,
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
                          Expanded(
                            child: Text(
                              'Toda la matriz · ${selected.length} de ${widget.variants.length} seleccionadas',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Scrollbar(
                          controller: matrixScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: matrixScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: Table(
                                defaultColumnWidth: const FixedColumnWidth(138),
                                border: TableBorder.all(color: _border),
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: _soft,
                                    ),
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Text(
                                          'Fila ↓ / Columna →',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      ...columns.map((column) {
                                        return InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              toggleColumn(
                                                column,
                                                !columnSelected(column),
                                              );
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: columnSelected(column),
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      toggleColumn(
                                                        column,
                                                        value ?? false,
                                                      );
                                                    });
                                                  },
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    column,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  ...rows.map((row) {
                                    return TableRow(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              toggleRow(row, !rowSelected(row));
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: rowSelected(row),
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      toggleRow(
                                                        row,
                                                        value ?? false,
                                                      );
                                                    });
                                                  },
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    row,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ...columns.map((column) {
                                          final variant = cell(row, column);
                                          if (variant == null) {
                                            return const SizedBox(
                                              height: 58,
                                              child: Center(
                                                child: Text(
                                                  'No existe',
                                                  style: TextStyle(
                                                    color: _muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final checked = selected.contains(
                                            variant.id,
                                          );
                                          return InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                checked
                                                    ? selected.remove(
                                                        variant.id,
                                                      )
                                                    : selected.add(variant.id);
                                              });
                                            },
                                            child: SizedBox(
                                              height: 58,
                                              child: Center(
                                                child: Checkbox(
                                                  value: checked,
                                                  onChanged: (value) {
                                                    setDialogState(() {
                                                      if (value ?? false) {
                                                        selected.add(
                                                          variant.id,
                                                        );
                                                      } else {
                                                        selected.remove(
                                                          variant.id,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
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
    } finally {
      matrixScrollController.dispose();
    }
  }

  // ==========================================================================
  // NAVEGACIÓN
  // ==========================================================================
}
