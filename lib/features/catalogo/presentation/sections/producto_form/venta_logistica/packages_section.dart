part of '../venta_logistica_section.dart';

extension _Step4PackagesSection on _Step4SalesLogisticsContentPanelState {
  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionIntro(
          icon: Icons.inventory_2_outlined,
          title:
              '¿Este producto utiliza empaques de transporte o abastecimiento?',
          description:
              'Los empaques logísticos no tienen precio, salvo que también se creen como presentación de venta.',
          trailing: _buildBinaryChoice(
            negativeLabel: 'No aplica',
            positiveLabel: 'Sí, agregar empaque',
            currentValue: _usesPackages,
            onChanged: _setPackageUsage,
          ),
        ),
        const SizedBox(height: 14),
        if (_usesPackages == null)
          _undecidedOptionalState(
            icon: Icons.local_shipping_outlined,
            title: 'Define si esta sección aplica',
            description:
                'Por ejemplo: caja máster, pallet, carrete o empaque del proveedor.',
          )
        else if (_usesPackages == false)
          _notApplicableState(
            icon: Icons.check_circle_outline,
            title: 'Empaques logísticos · No aplica',
            description:
                'La sección está completada y no se mostrarán formularios vacíos.',
            onChange: () => _setPackageUsage(true),
          )
        else
          _responsivePanels(
            left: _buildPackageList(),
            right: _buildPackageEditor(),
            leftFlex: 43,
            rightFlex: 57,
          ),
      ],
    );
  }

  Widget _buildPackageList() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Empaques registrados',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusPill(
                '${_packages.length}',
                color: _ink,
                background: const Color(0xFFFFF4C7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_packages.isEmpty)
            _emptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Aún no hay empaques',
              description:
                  'Agrega cómo llega, se almacena o se transporta el producto.',
            )
          else
            ...List.generate(_packages.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPackageCard(index),
              );
            }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _startNewPackage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo empaque'),
              style: _outlinedButtonStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(int index) {
    final item = _packages[index];
    final selected = _editingPackageIndex == index;
    final containedLabel = _packageContainedLabel(item);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _loadPackage(index),
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
                _statusPill(
                  'Solo logístico',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _loadPackage(index);
                    } else if (value == 'delete') {
                      _deletePackage(index);
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
              'Contiene ${_step4PlainNumber(item.contains)} × $containedLabel',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 9),
            Text(
              'Equivalencia total: '
              '${_step4PlainNumber(item.totalBaseUnits)} ${item.baseUnit}',
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _statusPill(
                  'Aplica a ${item.assignedVariantIds.length} de ${widget.variants.length}',
                  color: _muted,
                  background: const Color(0xFFEEF1F5),
                ),
                if (item.linkedSalesPresentationId != null)
                  _statusPill(
                    'Presentación vinculada',
                    color: _success,
                    background: const Color(0xFFE6F6ED),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
