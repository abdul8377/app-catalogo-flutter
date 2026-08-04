part of '../catalog_structure_panel.dart';

extension _CatalogBrandsTab on _CatalogStructurePanelState {
  Widget _buildBrands(double width) {
    final visible = _brands.where((brand) {
      final company = _companyById(brand.companyId);
      final text = '${brand.name} ${company?.name ?? ''}'.toLowerCase();
      final matchesCompany =
          _brandCompanyFilterId == null ||
          brand.companyId == _brandCompanyFilterId;
      return matchesCompany &&
          text.contains(_query.toLowerCase()) &&
          _matchesStatus(brand.active);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar marca o empresa',
          createLabel: 'Nueva marca',
          onCreate: _showBrandForm,
          showStatusFilters: true,
          secondaryLabel: 'Administrar categorías por marca',
          onSecondary: () {
            _update(() {
              _tab = CatalogStructureTab.brandCategories;
              _selectedBrandId ??= _firstBrandIdFor(_selectedCompanyId);
            });
          },
        ),
        const SizedBox(height: 12),
        _buildCompanyFilter(),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          const _EmptyState(
            title: 'No se encontraron marcas',
            message: 'Cada marca debe pertenecer a una empresa.',
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: visible.map((brand) {
              return SizedBox(
                width: width >= 1100
                    ? (width - 32) / 3
                    : width >= 720
                    ? (width - 16) / 2
                    : width,
                child: _buildBrandCard(brand),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCompanyFilter() {
    const allCompanies = '__all_companies__';
    final selectedCompanyId =
        _companies.any((company) => company.id == _brandCompanyFilterId)
        ? _brandCompanyFilterId
        : null;

    return Align(
      alignment: Alignment.centerLeft,
      child: KeyedSubtree(
        key: const Key('estructura_filtro_empresa'),
        child: SizedBox(
          width: 360,
          child: DropdownButtonFormField<String>(
            key: ValueKey(
              'estructura_filtro_empresa_${selectedCompanyId ?? allCompanies}',
            ),
            initialValue: selectedCompanyId ?? allCompanies,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Empresa',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: [
              const DropdownMenuItem(
                value: allCompanies,
                child: Text('Todas las empresas'),
              ),
              ..._companies.map(
                (company) => DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                ),
              ),
            ],
            onChanged: (value) {
              _update(() {
                _brandCompanyFilterId = value == null || value == allCompanies
                    ? null
                    : value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCard(CatalogBrand brand) {
    final company = _companyById(brand.companyId);
    final relationIds = _savedRelations[brand.id] ?? const <String>{};
    final related = _categories
        .where(
          (category) =>
              category.parentId == null && relationIds.contains(category.id),
        )
        .toList();

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(initials: brand.initials, color: _catalogYellow),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Empresa: ${company?.name ?? 'Sin empresa'}',
                      style: const TextStyle(
                        color: _catalogMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(active: brand.active),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Categorías principales habilitadas',
            style: TextStyle(color: _catalogMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (related.isEmpty)
            const Text(
              'Sin categorías habilitadas',
              style: TextStyle(color: _catalogMuted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...related
                    .take(3)
                    .map((category) => _InfoPill(label: category.name)),
                if (related.length > 3)
                  _InfoPill(label: '+${related.length - 3}'),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            '${brand.productCount} productos totales',
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SecondaryButton(
                label: 'Editar',
                icon: Icons.edit_outlined,
                onPressed: () => _showBrandForm(existing: brand),
              ),
              _SecondaryButton(
                label: 'Administrar categorías',
                icon: Icons.account_tree_outlined,
                onPressed: () {
                  _update(() {
                    _tab = CatalogStructureTab.brandCategories;
                    _selectedCompanyId = brand.companyId;
                    _selectedBrandId = brand.id;
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${brand.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmBrandStatusChange(brand);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      brand.active ? 'Desactivar marca' : 'Activar marca',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
