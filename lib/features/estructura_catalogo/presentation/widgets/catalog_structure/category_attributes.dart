part of '../catalog_structure_panel.dart';

extension _CatalogCategoryAttributes on _CatalogStructurePanelState {
  Widget _buildAttributeManager(CatalogCategory category) {
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final callback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('attributes'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _catalogBlueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Esta es una vista previa. La creación, edición, orden y '
              'configuración avanzada se realizan únicamente en la '
              'subpantalla Gestionar atributos.',
              style: TextStyle(color: _catalogText, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoPill(label: '$ownCount propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
              _PrimaryButton(
                label: 'Abrir gestión de atributos',
                icon: Icons.tune_rounded,
                onPressed: callback == null
                    ? null
                    : () => callback(category.id),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (effective.isEmpty)
            const _EmptyState(
              title: 'Sin atributos definidos',
              message:
                  'Abre Gestionar atributos para definir los datos técnicos.',
              compact: true,
            )
          else
            ...effective.map(_buildAttributePreviewCard),
        ],
      ),
    );
  }
}
