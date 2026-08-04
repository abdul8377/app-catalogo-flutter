part of '../catalog_structure_panel.dart';

extension _CatalogBrandCategoriesTab on _CatalogStructurePanelState {
  Widget _buildBrandCategories(double width) {
    final compact = width < 920;
    final companyPanel = _relationCompanyPanel();
    final brandPanel = _relationBrandPanel();
    final categoryPanel = _relationCategoryPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecciona de izquierda a derecha',
          style: TextStyle(
            color: _catalogText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'La relación se guarda con categorías principales. '
          'Sus subcategorías quedan disponibles automáticamente.',
          style: TextStyle(color: _catalogMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (compact)
          Column(
            children: [
              companyPanel,
              const SizedBox(height: 12),
              brandPanel,
              const SizedBox(height: 12),
              categoryPanel,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: companyPanel),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: brandPanel),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: categoryPanel),
            ],
          ),
        const SizedBox(height: 16),
        _relationSaveBar(),
      ],
    );
  }

  Widget _relationCompanyPanel() {
    return _SelectionPanel(
      title: '1 · Empresa',
      children: _companies.map((company) {
        final selected = company.id == _selectedCompanyId;
        return _SelectionTile(
          selected: selected,
          enabled: company.active,
          title: company.name,
          subtitle:
              '${company.brandCount} marcas · ${company.productCount} productos',
          onTap: () {
            _update(() {
              _selectedCompanyId = company.id;
              _selectedBrandId = _firstBrandIdFor(company.id);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _relationBrandPanel() {
    final companyBrands = _brands
        .where((brand) => brand.companyId == _selectedCompanyId)
        .toList();
    return _SelectionPanel(
      title: '2 · Marca',
      children: companyBrands.map((brand) {
        final selected = brand.id == _selectedBrandId;
        final count = (_workingRelations[brand.id] ?? const <String>{}).length;
        return _SelectionTile(
          selected: selected,
          enabled: brand.active,
          title: brand.name,
          subtitle: '$count categorías principales habilitadas',
          onTap: () => _update(() => _selectedBrandId = brand.id),
        );
      }).toList(),
    );
  }

  Widget _relationCategoryPanel() {
    final brand = _selectedBrand;
    if (brand == null) {
      return const _SelectionPanel(
        title: '3 · Categorías principales',
        children: [
          _EmptyState(
            title: 'Selecciona una marca',
            message: 'Luego podrás editar sus categorías.',
            compact: true,
          ),
        ],
      );
    }

    final rows = <Widget>[];
    for (final root in _categories.where((item) => item.parentId == null)) {
      _appendRelationCategoryRows(rows, root, 0, brand);
    }

    return _SelectionPanel(
      title: '3 · Categorías principales',
      header: TextFormField(
        onChanged: (value) {
          _update(() => _relationCategoryQuery = value);
        },
        initialValue: _relationCategoryQuery,
        decoration: const InputDecoration(
          hintText: 'Buscar categoría o subcategoría',
          prefixIcon: Icon(Icons.search_rounded),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      children: rows,
    );
  }

  void _appendRelationCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
    CatalogBrand brand,
  ) {
    if (category.parentId != null) return;

    final children = _childrenOf(category.id);
    final query = _relationCategoryQuery.toLowerCase();
    final selfMatches = category.name.toLowerCase().contains(query);
    final childMatches = children.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    if (_relationCategoryQuery.isNotEmpty && !selfMatches && !childMatches) {
      return;
    }

    final saved = _savedRelations[brand.id] ?? const <String>{};
    final working = _workingRelations[brand.id] ?? const <String>{};
    final checked = working.contains(category.id);
    final wasSaved = saved.contains(category.id);
    final relation = _relationFor(brand.id, category.id);
    final locked = relation?.isLocked ?? false;
    final added = checked && !wasSaved;
    final removalPending = !checked && wasSaved;

    target.add(
      _RelationCategoryTile(
        category: category,
        depth: 0,
        checked: checked,
        added: added,
        removalPending: removalPending,
        locked: locked,
        productCount: relation?.activeProductCount ?? 0,
        brandName: brand.name,
        onChanged: category.active
            ? (value) => _changeRelation(
                brand: brand,
                category: category,
                selected: value,
              )
            : null,
        onViewProducts: locked
            ? () => _showMessage(
                '${relation!.activeProductCount} productos activos de '
                '${brand.name} usan ${category.name}.',
              )
            : null,
      ),
    );

    if (children.isNotEmpty) {
      target.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(42, 0, 8, 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Incluye:',
                style: TextStyle(color: _catalogMuted, fontSize: 11),
              ),
              ...children.map(
                (child) => _InfoPill(
                  label: child.name,
                  color: child.active
                      ? const Color(0xFFF1F3F6)
                      : _catalogRedSoft,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _relationSaveBar() {
    final brand = _selectedBrand;
    if (brand == null) return const SizedBox.shrink();
    final saved = _savedRelations[brand.id] ?? const <String>{};
    final working = _workingRelations[brand.id] ?? const <String>{};
    final added = working.difference(saved).length;
    final removed = saved.difference(working).length;
    final changed = added > 0 || removed > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D5),
        border: Border.all(color: const Color(0xFFFFE17A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _selectedCompany?.name ?? 'Empresa',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          Text(
            changed
                ? '$added ${added == 1 ? 'añadida' : 'añadidas'} · '
                      '$removed ${removed == 1 ? 'retirada' : 'retiradas'}'
                : '${working.length} categorías principales · Sin cambios',
          ),
          _PrimaryButton(
            label: 'Guardar cambios',
            onPressed: changed ? _saveRelations : null,
          ),
        ],
      ),
    );
  }
}
