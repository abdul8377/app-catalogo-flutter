part of '../catalog_structure_panel.dart';

extension _CatalogCategoriesTab on _CatalogStructurePanelState {
  Widget _buildCategories(double width) {
    final narrow = width < 880;
    final tree = _buildCategoryTreePanel();
    final detail = _buildCategoryDetailPanel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(
          searchHint: 'Buscar categoría o subcategoría',
          createLabel: 'Nueva categoría raíz',
          onCreate: _showCategoryForm,
          showStatusFilters: true,
        ),
        const SizedBox(height: 16),
        if (narrow)
          Column(children: [tree, const SizedBox(height: 16), detail])
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: tree),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: detail),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryTreePanel() {
    final roots = _categories
        .where((category) => category.parentId == null)
        .toList();
    final rows = <Widget>[];
    for (final root in roots) {
      _appendCategoryRows(rows, root, 0);
    }

    return _CatalogCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Categorías y subcategorías',
                    style: TextStyle(
                      color: _catalogText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _InfoPill(label: '${_categories.length} categorías'),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(children: rows),
            ),
          ),
        ],
      ),
    );
  }

  void _appendCategoryRows(
    List<Widget> target,
    CatalogCategory category,
    int depth,
  ) {
    final descendants = _descendantsOf(category.id);
    final query = _query.toLowerCase();
    final selfMatchesQuery = category.name.toLowerCase().contains(query);
    final descendantMatchesQuery = descendants.any(
      (item) => item.name.toLowerCase().contains(query),
    );
    final selfMatchesStatus = _matchesStatus(category.active);
    final descendantMatchesStatus = descendants.any(
      (item) => _matchesStatus(item.active),
    );

    if (_query.isNotEmpty && !selfMatchesQuery && !descendantMatchesQuery) {
      return;
    }
    if (_filter != CatalogRecordFilter.all &&
        !selfMatchesStatus &&
        !descendantMatchesStatus) {
      return;
    }

    target.add(
      _CategoryTreeTile(
        category: category,
        depth: depth,
        selected: category.id == _selectedCategoryId,
        hasChildren: _childrenOf(category.id).isNotEmpty,
        onTap: () => _update(() {
          _selectedCategoryId = category.id;
          _categorySection = CategoryDetailSection.summary;
        }),
        onEdit: () => _showCategoryForm(existing: category),
        onAddChild: category.parentId == null && category.active
            ? () => _showCategoryForm(
                parentId: category.id,
                createSubcategory: true,
              )
            : null,
        onToggleStatus: () => _confirmCategoryStatusChange(category),
      ),
    );

    for (final child in _childrenOf(category.id)) {
      _appendCategoryRows(target, child, depth + 1);
    }
  }

  Widget _buildCategoryDetailPanel() {
    final category = _selectedCategory;
    if (category == null) {
      return const _EmptyState(
        title: 'Selecciona una categoría',
        message: 'Verás su resumen y sus atributos en este panel.',
      );
    }

    return _CatalogCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _InfoPill(
                            label: 'SELECCIONADA',
                            color: Color(0xFFFFE277),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(active: category.active),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: _catalogText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _buildCategorySectionTabs(),
          ),
          const Divider(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: _categorySection == CategoryDetailSection.summary
                ? _buildCategorySummary(category)
                : _buildAttributeManager(category),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySectionTabs() {
    return Row(
      children: [
        Expanded(
          child: _sectionTab(
            label: 'Resumen',
            selected: _categorySection == CategoryDetailSection.summary,
            onTap: () {
              _update(() {
                _categorySection = CategoryDetailSection.summary;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _sectionTab(
            label: 'Vista previa de atributos',
            selected: _categorySection == CategoryDetailSection.attributes,
            onTap: () {
              _update(() {
                _categorySection = CategoryDetailSection.attributes;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5CC) : Colors.white,
          border: Border.all(color: selected ? _catalogYellow : _catalogBorder),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _catalogText,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
