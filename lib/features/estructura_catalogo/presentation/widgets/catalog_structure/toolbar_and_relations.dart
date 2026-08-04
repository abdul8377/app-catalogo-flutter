part of '../catalog_structure_panel.dart';

extension _CatalogToolbarAndRelations on _CatalogStructurePanelState {
  Widget _buildToolbar({
    required String searchHint,
    required String createLabel,
    required VoidCallback onCreate,
    required bool showStatusFilters,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    final actions = <Widget>[
      if (secondaryLabel != null && onSecondary != null)
        _SecondaryButton(label: secondaryLabel, onPressed: onSecondary),
      _PrimaryButton(
        label: createLabel,
        icon: Icons.add_rounded,
        onPressed: onCreate,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('estructura_busqueda'),
          onChanged: (value) => _update(() => _query = value),
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showStatusFilters)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(CatalogRecordFilter.all, 'Todas'),
                  _filterChip(CatalogRecordFilter.active, 'Activas'),
                  _filterChip(CatalogRecordFilter.inactive, 'Inactivas'),
                ],
              ),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ],
    );
  }

  Widget _filterChip(CatalogRecordFilter filter, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      selectedColor: _catalogYellowSoft,
      side: BorderSide(
        color: _filter == filter ? _catalogYellow : _catalogBorder,
      ),
      onSelected: (_) => _update(() => _filter = filter),
    );
  }

  bool _matchesStatus(bool active) {
    return switch (_filter) {
      CatalogRecordFilter.all => true,
      CatalogRecordFilter.active => active,
      CatalogRecordFilter.inactive => !active,
    };
  }

  List<CatalogCategory> _childrenOf(String parentId) {
    return _categories
        .where((category) => category.parentId == parentId)
        .toList();
  }

  List<CatalogCategory> _descendantsOf(String categoryId) {
    final result = <CatalogCategory>[];
    for (final child in _childrenOf(categoryId)) {
      result.add(child);
      result.addAll(_descendantsOf(child.id));
    }
    return result;
  }

  List<CatalogCategory> _ancestorChain(String categoryId) {
    final result = <CatalogCategory>[];
    var current = _categoryById(categoryId);
    final visited = <String>{};
    while (current != null && visited.add(current.id)) {
      result.add(current);
      current = _categoryById(current.parentId);
    }
    return result;
  }

  List<EffectiveCategoryAttribute> _effectiveAttributesFor(String categoryId) {
    final chain = _ancestorChain(categoryId);
    final result = <EffectiveCategoryAttribute>[];
    for (final origin in chain.reversed) {
      final definitions = _attributes
          .where((attribute) => attribute.categoryId == origin.id)
          .toList();
      for (final definition in definitions) {
        result.add(
          EffectiveCategoryAttribute(
            definition: definition,
            originCategory: origin,
            inherited: origin.id != categoryId,
          ),
        );
      }
    }
    return result;
  }

  CatalogCompany? _companyById(String? id) {
    return _firstWhereOrNull(_companies, (item) => item.id == id);
  }

  CatalogCategory? _categoryById(String? id) {
    return _firstWhereOrNull(_categories, (item) => item.id == id);
  }

  BrandCategoryRelation? _relationFor(String brandId, String categoryId) {
    return _firstWhereOrNull(
      _relations,
      (item) => item.brandId == brandId && item.categoryId == categoryId,
    );
  }

  void _changeRelation({
    required CatalogBrand brand,
    required CatalogCategory category,
    required bool selected,
  }) {
    if (category.parentId != null) {
      _showMessage(
        'Las subcategorías se habilitan mediante su categoría principal.',
        error: true,
      );
      return;
    }

    final relation = _relationFor(brand.id, category.id);
    if (!selected && (relation?.isLocked ?? false)) {
      _showMessage(
        'No puede retirarse: ${relation!.activeProductCount} productos activos '
        'usan esta relación.',
        error: true,
      );
      return;
    }

    _update(() {
      final working = _workingRelations.putIfAbsent(brand.id, () => <String>{});
      if (selected) {
        working.add(category.id);
      } else {
        working.remove(category.id);
      }
    });
  }

  void _saveRelations() {
    final brand = _selectedBrand;
    if (brand == null) return;
    final working = _workingRelations[brand.id] ?? const <String>{};
    final oldByCategory = {
      for (final relation in _relations.where(
        (item) => item.brandId == brand.id,
      ))
        relation.categoryId: relation,
    };
    final next = _relations
        .where((relation) => relation.brandId != brand.id)
        .toList();
    for (final categoryId in working) {
      next.add(
        oldByCategory[categoryId] ??
            BrandCategoryRelation(
              brandId: brand.id,
              categoryId: categoryId,
              activeProductCount: 0,
            ),
      );
    }

    _update(() {
      _relations = next;
      _savedRelations[brand.id] = Set<String>.from(working);
    });
    widget.onRelationsChanged?.call(List.unmodifiable(_relations));
    _showMessage('Categorías de ${brand.name} actualizadas.');
  }
}
