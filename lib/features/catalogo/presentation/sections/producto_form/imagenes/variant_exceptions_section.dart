part of '../imagenes_section.dart';

extension _Step6VariantExceptionsSection on _Step6ImagesPanelState {
  Widget _buildVariantExceptions() {
    final filtered = _filteredVariants;
    return _panel(
      background: _canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Excepciones por variante',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton.icon(
                onPressed: _toggleMultiSelect,
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                icon: Icon(
                  _multiSelect ? Icons.close : Icons.library_add_check_outlined,
                ),
                label: Text(
                  _multiSelect ? 'Cancelar selección' : 'Seleccionar varias',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInheritanceNote(),
          const SizedBox(height: 14),
          TextField(
            controller: _variantSearchController,
            style: const TextStyle(fontSize: 14),
            decoration: _inputDecoration(
              'Buscar por medida o SKU',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(Step6VariantFilter.all, 'Todas'),
              _filterChip(Step6VariantFilter.withException, 'Con excepción'),
              _filterChip(Step6VariantFilter.withoutException, 'Sin excepción'),
            ],
          ),
          if (_multiSelect) ...[
            const SizedBox(height: 12),
            _buildBulkSelectionBar(filtered),
          ],
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _buildNoVariantsState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) =>
                  _buildVariantRow(filtered[index]),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _exceptionActionEnabled
                ? () => _openExceptionEditor(_exceptionTargetIds)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _selection,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _multiSelect ? Icons.content_copy_outlined : Icons.tune_outlined,
            ),
            label: Text(
              _multiSelect ? 'Aplicar la misma imagen' : 'Configurar excepción',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInheritanceNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8E5F6)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_tree_outlined, color: _selection, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Herencia automática\n'
              'Todas las variantes utilizan la galería familiar. Configura '
              'una excepción solamente cuando una variante tenga una '
              'apariencia diferente.',
              style: TextStyle(color: _ink, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(Step6VariantFilter filter, String label) {
    final selected = _variantFilter == filter;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        _update(() => _variantFilter = filter);
      },
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: _selection,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _selection : _border),
      showCheckmark: true,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildBulkSelectionBar(List<Step6VariantOption> visible) {
    final visibleIds = visible.map((item) => item.id).toSet();
    final allVisibleSelected =
        visibleIds.isNotEmpty && _selectedVariantIds.containsAll(visibleIds);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allVisibleSelected,
            onChanged: (_) {
              _update(() {
                if (allVisibleSelected) {
                  _selectedVariantIds.removeAll(visibleIds);
                } else {
                  _selectedVariantIds.addAll(visibleIds);
                }
              });
            },
          ),
          Expanded(
            child: Text(
              '${_selectedVariantIds.length} '
              '${_selectedVariantIds.length == 1 ? 'variante seleccionada' : 'variantes seleccionadas'}',
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVariantsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'No hay variantes que coincidan con la búsqueda o el filtro.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
      ),
    );
  }
}
