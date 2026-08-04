part of '../venta_logistica_section.dart';

extension _Step4ContentVariantActions on _Step4SalesLogisticsContentPanelState {
  Future<void> _pickCatalogVariant() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        var query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = widget.catalogVariants.where((item) {
              return item.label.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Buscar en el catálogo'),
              content: SizedBox(
                width: 520,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (value) {
                        setDialogState(() {
                          query = value.trim();
                        });
                      },
                      decoration: _inputDecoration(
                        label: 'Producto o variante',
                        hint: 'Ej. Broca HSS 3 mm',
                        prefixIcon: Icons.search,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      leading: const Icon(Icons.link_off),
                      title: const Text('Sin producto relacionado'),
                      onTap: () => Navigator.pop(context, ''),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: options.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron coincidencias.',
                                style: TextStyle(color: _muted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.inventory_2_outlined,
                                  ),
                                  title: Text(option.label),
                                  onTap: () =>
                                      Navigator.pop(context, option.id),
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
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _update(() {
      _relatedCatalogVariantId = result.isEmpty ? null : result;
    });
  }

  Future<void> _copyContentToOtherVariants() async {
    final sourceId = _selectedContentVariantId ?? widget.variants.first.id;
    final sourceItems = _contentItems
        .where((item) => item.ownerVariantId == sourceId)
        .toList();

    if (sourceItems.isEmpty) {
      _showMessage(
        'Agrega componentes antes de copiar el contenido.',
        error: true,
      );
      return;
    }

    final candidates = widget.variants
        .where((item) => item.id != sourceId)
        .toList();

    if (candidates.isEmpty) {
      _showMessage('No existen otras variantes a las cuales copiar.');
      return;
    }

    final selected = <String>{};
    var replaceExisting = false;

    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Copiar contenido'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona las variantes de destino.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: candidates.map((variant) {
                          final checked = selected.contains(variant.id);
                          return CheckboxListTile(
                            value: checked,
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
                        }).toList(),
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: replaceExisting,
                      title: const Text('Reemplazar el contenido existente'),
                      subtitle: const Text(
                        'Si no se activa, los componentes se agregarán a la lista actual.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setDialogState(() {
                          replaceExisting = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _ink,
                  ),
                  child: const Text('Copiar contenido'),
                ),
              ],
            );
          },
        );
      },
    );

    if (accepted != true || !mounted) {
      return;
    }

    _update(() {
      if (replaceExisting) {
        _contentItems.removeWhere(
          (item) => selected.contains(item.ownerVariantId),
        );
      }

      for (final targetId in selected) {
        for (final source in sourceItems) {
          _contentItems.add(
            ProductContentItemDraft(
              id: _newId('content'),
              ownerVariantId: targetId,
              componentName: source.componentName,
              quantity: source.quantity,
              unit: source.unit,
              relatedCatalogVariantId: source.relatedCatalogVariantId,
            ),
          );
        }
      }
    });

    _emitChanged();
    _showMessage('Contenido copiado a ${selected.length} variantes.');
  }

  // ==========================================================================
  // ALCANCE DE VARIANTES
  // ==========================================================================
}
