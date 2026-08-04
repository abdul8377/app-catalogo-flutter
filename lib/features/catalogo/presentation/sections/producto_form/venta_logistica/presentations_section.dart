part of '../venta_logistica_section.dart';

extension _Step4PresentationsSection on _Step4SalesLogisticsContentPanelState {
  Widget _responsivePanels({
    required Widget left,
    required Widget right,
    double leftFlex = 58,
    double rightFlex = 42,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 18), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex.round(), child: left),
            const SizedBox(width: 18),
            Expanded(flex: rightFlex.round(), child: right),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // INTERFAZ · PRESENTACIONES
  // ==========================================================================

  Widget _buildPresentationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.shopping_bag_outlined,
          title: '¿Cómo puede pedir este producto el cliente?',
          description:
              'Registra las opciones vendibles, por ejemplo: unidad, docena, ciento, caja x500, kilogramo, metro o rollo.',
          trailing: _statusPill(
            'Obligatoria',
            color: _ink,
            background: const Color(0xFFFFF4C7),
          ),
        ),
        const SizedBox(height: 14),
        _responsivePanels(
          left: _buildPresentationList(),
          right: _buildPresentationEditor(),
        ),
      ],
    );
  }

  Widget _buildPresentationList() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presentaciones configuradas',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                '${_presentations.length}',
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_presentations.isEmpty)
            _emptyState(
              icon: Icons.sell_outlined,
              title: 'Aún no hay presentaciones',
              description:
                  'Crea la primera forma en que el cliente podrá pedir este producto.',
            )
          else
            ...List.generate(_presentations.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPresentationCard(index),
              );
            }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _startNewPresentation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva presentación'),
              style: _outlinedButtonStyle(),
            ),
          ),
          const SizedBox(height: 16),
          _neutralNote(
            'Los precios de cada combinación variante + presentación se configuran en el paso 5.',
            icon: Icons.info_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildPresentationCard(int index) {
    final item = _presentations[index];
    final selected = _editingPresentationIndex == index;
    final allDefault =
        item.defaultVariantIds.isNotEmpty &&
        item.defaultVariantIds.length == item.assignedVariantIds.length;
    final partialDefault = item.defaultVariantIds.isNotEmpty && !allDefault;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _loadPresentation(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : _canvas,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _loadPresentation(index);
                    } else if (value == 'delete') {
                      _deletePresentation(index);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '${_step4PlainNumber(item.equivalentTo)} ${item.baseUnit}'
              ' · Pedido mínimo: ${_step4PlainNumber(item.minimumOrder)}'
              ' · Incremento: ${_step4PlainNumber(item.purchaseIncrement)}',
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 11),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                if (allDefault)
                  _statusPill(
                    'Predeterminada',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
                if (partialDefault)
                  _statusPill(
                    'Predeterminada en ${item.defaultVariantIds.length}',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
                _statusPill(
                  'Asignada a ${item.assignedVariantIds.length} de ${widget.variants.length} variantes',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                _statusPill(
                  item.allowsDecimals ? 'Cantidad decimal' : 'Cantidad entera',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
