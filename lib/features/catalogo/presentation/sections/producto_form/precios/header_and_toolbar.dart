part of '../precios_section.dart';

extension _Step5HeaderAndToolbar on _Step5PricingPanelState {
  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 14,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paso 4 · Precios',
              style: TextStyle(
                color: _ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Define cómo se calcula el precio de cada combinación de '
              'variante y presentación vendible.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3C4),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  'Familia: ${widget.familyName} · '
                  '${widget.totalVariantCount} variantes',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_activeListRows.length} combinaciones vendibles · '
                '$_pricedCount listas · $_quoteCount por cotizar · '
                '$_pendingCount pendientes',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListConfiguration() {
    final list = _selectedList;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      decoration: BoxDecoration(
        color: _canvas,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 14,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Lista: ',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key('price_list_selector'),
                        value: list.id,
                        isDense: true,
                        items: _lists
                            .map(
                              (item) => DropdownMenuItem(
                                key: ValueKey('price_list_option_${item.id}'),
                                value: item.id,
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _lists.length > 1
                            ? _requestSelectedListChange
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${_currencySymbol(list.currencyCode)} · '
                  'Importes ${list.includesIgv ? 'con' : 'sin'} IGV · '
                  'Desde ${_formatDate(list.validFrom)} · '
                  '${list.validUntil == null ? 'Sin fecha final' : 'Hasta ${_formatDate(list.validUntil!)}'}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: const Key('seleccionar_listas_precios'),
                onPressed: _selectPriceLists,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Seleccionar listas'),
                style: _outlinedStyle(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final presentationOptions = <String, String>{};

    for (final source in _uniqueSources) {
      presentationOptions.putIfAbsent(
        source.presentationId,
        () => source.presentationLabel,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterChip(label: 'Todas', filter: PriceFilter.all),
              _buildFilterChip(
                label: 'Pendientes',
                filter: PriceFilter.pending,
              ),
              _buildFilterChip(label: 'Por cotizar', filter: PriceFilter.quote),
              SizedBox(
                width: 205,
                child: DropdownButtonFormField<String>(
                  value: _presentationFilterId ?? '__all__',
                  isDense: true,
                  decoration: _inputDecoration('Presentación'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '__all__',
                      child: Text('Todas'),
                    ),
                    ...presentationOptions.entries.map(
                      (item) => DropdownMenuItem<String>(
                        value: item.key,
                        child: Text(item.value),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _update(() {
                      _presentationFilterId = value == '__all__' ? null : value;
                    });
                  },
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_selectedPriceKeys.isNotEmpty)
                FilledButton.icon(
                  onPressed: _configureSelected,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    'Configurar seleccionadas '
                    '(${_selectedPriceKeys.length})',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                  ),
                ),
              SegmentedButton<PriceScreenView>(
                segments: const [
                  ButtonSegment(
                    value: PriceScreenView.table,
                    icon: Icon(Icons.table_rows_outlined),
                    label: Text('Tabla'),
                  ),
                  ButtonSegment(
                    value: PriceScreenView.matrix,
                    icon: Icon(Icons.grid_view_outlined),
                    label: Text('Matriz'),
                  ),
                ],
                selected: {_screenView},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  _update(() {
                    _screenView = selection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required PriceFilter filter,
  }) {
    return FilterChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) {
        _update(() {
          _filter = filter;
        });
      },
      selectedColor: _primary.withOpacity(0.22),
      checkmarkColor: _ink,
      side: const BorderSide(color: _border),
      labelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
    );
  }
}
