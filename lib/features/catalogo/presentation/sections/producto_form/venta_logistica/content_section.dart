part of '../venta_logistica_section.dart';

extension _Step4ContentSection on _Step4SalesLogisticsContentPanelState {
  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.category_outlined,
          title: '¿El producto vendido contiene varios elementos?',
          description:
              'Utiliza esta sección para juegos, kits, sets de accesorios o paquetes compuestos.',
          trailing: _buildBinaryChoice(
            negativeLabel: 'No aplica',
            positiveLabel: 'Sí, definir contenido',
            currentValue: _hasContent,
            onChanged: _setContentUsage,
          ),
        ),
        const SizedBox(height: 14),
        if (_hasContent == null)
          _undecidedOptionalState(
            icon: Icons.handyman_outlined,
            title: 'Define si esta sección aplica',
            description:
                'Cada componente puede escribirse manualmente y, de forma opcional, relacionarse con una variante del catálogo.',
          )
        else if (_hasContent == false)
          _notApplicableState(
            icon: Icons.check_circle_outline,
            title: 'Contenido del producto · No aplica',
            description:
                'La sección está completada. El producto no representa un juego o kit.',
            onChange: () => _setContentUsage(true),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.variants.length > 1) ...[
                _buildContentVariantToolbar(),
                const SizedBox(height: 14),
              ],
              _responsivePanels(
                left: _buildContentTable(),
                right: _buildContentEditor(),
                leftFlex: 65,
                rightFlex: 35,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildContentVariantToolbar() {
    return _panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selector = Row(
            children: [
              const Text(
                'Contenido de la variante:',
                style: TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedContentVariantId,
                  isExpanded: true,
                  decoration: _inputDecoration(dense: true),
                  items: widget.variants.map((variant) {
                    return DropdownMenuItem(
                      value: variant.id,
                      child: Text(variant.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    _update(() {
                      _selectedContentVariantId = value;
                      _startNewContentItem(rebuild: false);
                    });
                  },
                ),
              ),
            ],
          );

          final copyButton = OutlinedButton.icon(
            onPressed: _copyContentToOtherVariants,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Copiar contenido a otras variantes'),
            style: _outlinedButtonStyle(),
          );

          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [selector, const SizedBox(height: 10), copyButton],
            );
          }

          return Row(
            children: [
              Expanded(child: selector),
              const SizedBox(width: 18),
              copyButton,
            ],
          );
        },
      ),
    );
  }

  List<MapEntry<int, ProductContentItemDraft>> get _visibleContentEntries {
    final variantId = _selectedContentVariantId ?? widget.variants.first.id;
    final entries = <MapEntry<int, ProductContentItemDraft>>[];

    for (var index = 0; index < _contentItems.length; index++) {
      final item = _contentItems[index];
      if (item.ownerVariantId == variantId) {
        entries.add(MapEntry(index, item));
      }
    }

    return entries;
  }

  Widget _buildContentTable() {
    final entries = _visibleContentEntries;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Contenido del producto',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                _contentCounterLabel(entries.map((e) => e.value).toList()),
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            _emptyState(
              icon: Icons.category_outlined,
              title: 'Aún no hay componentes',
              description:
                  'Agrega el primer elemento incluido en esta variante.',
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 420),
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Scrollbar(
                controller: _contentTableScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _contentTableScrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(_soft),
                      columns: const [
                        DataColumn(label: Text('Elemento incluido')),
                        DataColumn(label: Text('Cantidad')),
                        DataColumn(label: Text('Unidad')),
                        DataColumn(label: Text('Producto relacionado')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: entries.map((entry) {
                        final item = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  item.componentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(_step4PlainNumber(item.quantity))),
                            DataCell(Text(item.unit)),
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Text(
                                  _catalogVariantLabel(
                                        item.relatedCatalogVariantId,
                                      ) ??
                                      'Sin relación',
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        _loadContentItem(entry.key),
                                    child: const Text('Editar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _deleteContentItem(entry.key),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          _neutralNote(
            'El precio del juego se configura en el paso 5; no se asigna a cada componente.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }
}
