part of '../precios_section.dart';

extension _Step5PriceTableAndMatrix on _Step5PricingPanelState {
  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1050;
        final editor = _editorPrice == null ? null : _buildEditorPanel();

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _screenView == PriceScreenView.table
                  ? _buildPriceTable()
                  : _buildPriceMatrix(),
              if (editor != null) ...[const SizedBox(height: 16), editor],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _screenView == PriceScreenView.table
                  ? _buildPriceTable()
                  : _buildPriceMatrix(),
            ),
            if (editor != null) ...[
              const SizedBox(width: 16),
              SizedBox(width: 410, child: editor),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPriceTable() {
    final rows = _filteredRows;

    if (_activeListRows.isEmpty) {
      return _buildNoCombinationsState();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: rows.isEmpty
          ? _buildEmptyFilteredState()
          : LayoutBuilder(
              builder: (context, constraints) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowHeight: 44,
                        dataRowMinHeight: 62,
                        dataRowMaxHeight: 72,
                        horizontalMargin: 12,
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF0F3F7),
                        ),
                        columns: const [
                          DataColumn(label: Text('')),
                          DataColumn(label: Text('Variante')),
                          DataColumn(label: Text('Presentación')),
                          DataColumn(label: Text('Configuración')),
                          DataColumn(label: Text('Precio o detalle')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows: rows.map(_buildPriceDataRow).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  DataRow _buildPriceDataRow(ProductPriceDraft price) {
    final source = _findSource(price.variantId, price.presentationId)!;

    final selected = _selectedPriceKeys.contains(price.key);

    return DataRow(
      selected: selected,
      color: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return _primary.withOpacity(0.13);
        }
        return Colors.white;
      }),
      cells: [
        DataCell(
          Checkbox(
            value: selected,
            activeColor: _ink,
            onChanged: (value) {
              _togglePriceSelection(price, value ?? false);
            },
          ),
        ),
        DataCell(
          SizedBox(
            width: 135,
            child: Text(
              source.variantLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 115,
            child: Text(
              source.presentationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_buildConfigurationBadge(price.configuration)),
        DataCell(
          SizedBox(
            width: 190,
            child: Text(
              _priceDetail(price, source),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    price.configuration == PriceConfigurationType.unconfigured
                    ? _muted
                    : _ink,
              ),
            ),
          ),
        ),
        DataCell(_buildReadyBadge(price)),
        DataCell(
          TextButton(
            onPressed: () {
              _openEditor(price);
            },
            child: Text(
              price.configuration == PriceConfigurationType.unconfigured
                  ? 'Configurar'
                  : price.configuration == PriceConfigurationType.quantity
                  ? 'Ver rangos'
                  : 'Editar',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceMatrix() {
    final variants = <String, String>{};
    final presentations = <String, String>{};

    for (final source in _uniqueSources) {
      variants.putIfAbsent(source.variantId, () => source.variantLabel);

      if (_presentationFilterId == null ||
          source.presentationId == _presentationFilterId) {
        presentations.putIfAbsent(
          source.presentationId,
          () => source.presentationLabel,
        );
      }
    }

    if (variants.isEmpty || presentations.isEmpty) {
      return _buildNoCombinationsState();
    }

    final tableWidth = 190.0 + presentations.length * 190.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(190),
              for (var index = 0; index < presentations.length; index++)
                index + 1: const FixedColumnWidth(190),
            },
            border: TableBorder.all(
              color: _border,
              width: 1,
              borderRadius: BorderRadius.circular(10),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF0F3F7)),
                children: [
                  _buildMatrixHeaderCell('Variante \\ Presentación'),
                  ...presentations.values.map(_buildMatrixHeaderCell),
                ],
              ),
              ...variants.entries.map((variant) {
                return TableRow(
                  children: [
                    _buildMatrixVariantCell(variant.value),
                    ...presentations.entries.map(
                      (presentation) => _buildMatrixPriceCell(
                        variantId: variant.key,
                        presentationId: presentation.key,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
