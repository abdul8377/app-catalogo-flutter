part of '../catalog_structure_panel.dart';

extension _CatalogHeaderAndTabs on _CatalogStructurePanelState {
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estructura del catálogo',
            style: TextStyle(
              color: _catalogText,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(switch (_tab) {
            CatalogStructureTab.companies =>
              'Las empresas agrupan marcas; no poseen categorías directamente.',
            CatalogStructureTab.brands =>
              'Cada marca pertenece a una empresa y utiliza categorías globales.',
            CatalogStructureTab.categories =>
              'Categorías globales de dos niveles, con atributos e herencia.',
            CatalogStructureTab.brandCategories =>
              'Define qué categorías globales puede utilizar cada marca.',
          }, style: const TextStyle(color: _catalogMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMainTabs() {
    final items = <(CatalogStructureTab, String)>[
      (CatalogStructureTab.companies, 'Empresas'),
      (CatalogStructureTab.brands, 'Marcas'),
      (CatalogStructureTab.categories, 'Categorías'),
      (CatalogStructureTab.brandCategories, 'Categorías por marca'),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _catalogBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            if (compact) {
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: items.map((item) {
                  return SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: _mainTabButton(item.$1, item.$2),
                  );
                }).toList(),
              );
            }
            return Row(
              children: items.map((item) {
                return Expanded(child: _mainTabButton(item.$1, item.$2));
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _mainTabButton(CatalogStructureTab value, String label) {
    final selected = _tab == value;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () {
          _update(() {
            _tab = value;
            _query = '';
            _filter = CatalogRecordFilter.all;
            if (value == CatalogStructureTab.brands) {
              _brandCompanyFilterId = null;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _catalogYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? const Color(0xFFE3A900) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab(double width) {
    return switch (_tab) {
      CatalogStructureTab.companies => _buildCompanies(width),
      CatalogStructureTab.brands => _buildBrands(width),
      CatalogStructureTab.categories => _buildCategories(width),
      CatalogStructureTab.brandCategories => _buildBrandCategories(width),
    };
  }
}
