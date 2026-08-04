part of '../catalog_structure_panel.dart';

extension _CatalogCategorySummary on _CatalogStructurePanelState {
  Widget _buildCategorySummary(CatalogCategory category) {
    final parent = _categoryById(category.parentId);
    final children = _childrenOf(category.id);
    final relatedBrandIds = _savedRelations.entries
        .where((entry) {
          final rootId = category.parentId ?? category.id;
          return entry.value.contains(rootId);
        })
        .map((entry) => entry.key)
        .toSet();
    final effective = _effectiveAttributesFor(category.id);
    final ownCount = effective.where((item) => !item.inherited).length;
    final inheritedCount = effective.where((item) => item.inherited).length;
    final attributeCallback = widget.onManageCategoryAttributes;

    return Padding(
      key: const ValueKey('summary'),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabelValue(
            label: 'Ruta',
            value: parent == null
                ? category.name
                : '${parent.name} > ${category.name}',
          ),
          const SizedBox(height: 14),
          _LabelValue(
            label: 'Tipo',
            value: parent == null ? 'Categoría principal' : 'Subcategoría',
          ),
          if (category.description != null &&
              category.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _LabelValue(label: 'Descripción', value: category.description!),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Subcategorías',
                  style: TextStyle(color: _catalogMuted, fontSize: 12),
                ),
              ),
              if (category.parentId == null)
                _SecondaryButton(
                  label: 'Añadir subcategoría',
                  icon: Icons.add_rounded,
                  onPressed: category.active
                      ? () => _showCategoryForm(
                          parentId: category.id,
                          createSubcategory: true,
                        )
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (category.parentId != null)
            Text(
              'Pertenece a ${parent?.name ?? 'una categoría superior'}.',
              style: const TextStyle(color: _catalogMuted),
            )
          else if (children.isEmpty)
            const Text('Sin subcategorías')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children
                  .map(
                    (child) => ActionChip(
                      label: Text(child.name),
                      onPressed: () {
                        _update(() {
                          _selectedCategoryId = child.id;
                          _categorySection = CategoryDetailSection.summary;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  value: '${category.directProductCount}',
                  label: 'productos directos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${category.includingDescendantProductCount}',
                  label: 'incluyendo subcategorías',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBox(
                  value: '${relatedBrandIds.length}',
                  label: 'marcas habilitadas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: '$ownCount atributos propios'),
              _InfoPill(
                label: '$inheritedCount heredados',
                color: _catalogBlueSoft,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showCategoryForm(existing: category),
              ),
              _SecondaryButton(
                label: 'Gestionar atributos',
                icon: Icons.tune_rounded,
                onPressed: attributeCallback == null
                    ? null
                    : () => attributeCallback(category.id),
              ),
              _SecondaryButton(
                label: 'Ver asignaciones',
                icon: Icons.link_rounded,
                onPressed: () {
                  final root = parent ?? category;
                  _update(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _relationCategoryQuery = root.name;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            category.parentId == null
                ? 'Al desactivar esta categoría, sus subcategorías dejarán de '
                      'estar disponibles para nuevos productos, pero conservarán '
                      'su estado y sus datos históricos.'
                : 'La disponibilidad también depende de que la categoría '
                      'superior permanezca activa.',
            style: const TextStyle(
              color: _catalogMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributePreviewCard(EffectiveCategoryAttribute item) {
    final attribute = item.definition;
    final details = <String>[
      _attributeTypeLabel(attribute.type),
      if (attribute.units.isNotEmpty) attribute.units.join(', '),
      if (attribute.required) 'Obligatorio',
      if (attribute.filterable) 'Filtrable',
      if (attribute.variantAxis) 'Posible eje',
      if (attribute.multiple) 'Selección múltiple',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.inherited ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: _catalogBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            attribute.variantAxis
                ? Icons.grid_view_rounded
                : Icons.data_object_rounded,
            color: attribute.active ? _catalogText : _catalogMuted,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      attribute.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _InfoPill(
                      label: item.inherited
                          ? 'Heredado de ${item.originCategory.name}'
                          : 'Propio de ${item.originCategory.name}',
                      color: item.inherited
                          ? _catalogBlueSoft
                          : const Color(0xFFF1F3F6),
                    ),
                    if (!attribute.active)
                      const _InfoPill(
                        label: 'Inactivo',
                        color: _catalogRedSoft,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.join(' · '),
                  style: const TextStyle(
                    color: _catalogMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if (attribute.options.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: attribute.options
                        .take(6)
                        .map((value) => _InfoPill(label: value))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
