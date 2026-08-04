part of '../catalog_structure_panel.dart';

extension _CatalogCompaniesTab on _CatalogStructurePanelState {
  Widget _buildCompanies(double width) {
    final visible = _companies.where((company) {
      final matchesQuery =
          company.name.toLowerCase().contains(_query.toLowerCase()) ||
          (company.ruc ?? '').contains(_query);
      return matchesQuery && _matchesStatus(company.active);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar empresa por nombre o RUC',
          createLabel: 'Nueva empresa',
          onCreate: _showCompanyForm,
          showStatusFilters: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${visible.length} ${visible.length == 1 ? 'empresa' : 'empresas'}',
              style: const TextStyle(
                color: _catalogText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const _InfoPill(
              label: 'Productos: activos e inactivos',
              color: _catalogBlueSoft,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const _EmptyState(
            title: 'No se encontraron empresas',
            message: 'Ajusta la búsqueda o el filtro de estado.',
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: visible.map((company) {
              return SizedBox(
                width: width >= 900 ? (width - 16) / 2 : width,
                child: _buildCompanyCard(company),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildCompanyCard(CatalogCompany company) {
    final companyBrands = _brands
        .where((brand) => brand.companyId == company.id)
        .toList();
    final categoryIds = <String>{};
    for (final brand in companyBrands) {
      categoryIds.addAll(_savedRelations[brand.id] ?? const <String>{});
    }

    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _InitialsAvatar(
                initials: company.initials,
                color: _catalogYellow,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        color: _catalogText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (company.ruc != null &&
                        company.ruc!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'RUC ${company.ruc}',
                        style: const TextStyle(
                          color: _catalogMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(active: company.active),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Marcas',
                  value: '${companyBrands.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Categorías vía marcas',
                  value: '${categoryIds.length}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Productos totales',
                  value: '${company.productCount}',
                ),
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
                onPressed: () => _showCompanyForm(existing: company),
              ),
              _SecondaryButton(
                label: 'Ver marcas',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  _update(() {
                    _tab = CatalogStructureTab.brands;
                    _selectedCompanyId = company.id;
                    _brandCompanyFilterId = company.id;
                    _query = '';
                  });
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Más acciones para ${company.name}',
                onSelected: (value) {
                  if (value == 'status') {
                    _confirmCompanyStatusChange(company);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'status',
                    child: Text(
                      company.active ? 'Desactivar empresa' : 'Activar empresa',
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
