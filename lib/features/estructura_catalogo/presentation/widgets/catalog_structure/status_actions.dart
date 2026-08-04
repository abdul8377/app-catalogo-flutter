part of '../catalog_structure_panel.dart';

extension _CatalogStatusActions on _CatalogStructurePanelState {
  Future<void> _confirmCompanyStatusChange(CatalogCompany company) async {
    if (company.active) {
      final brands = _brands.where(
        (brand) => brand.companyId == company.id && brand.active,
      );
      final confirmed = await _confirm(
        title: 'Desactivar empresa',
        message:
            'Sus ${brands.length} marcas dejarán de estar disponibles para '
            'registrar productos. El historial se conservará.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    }

    _update(() {
      final index = _companies.indexWhere((item) => item.id == company.id);
      _companies[index] = company.copyWith(active: !company.active);
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }

  Future<void> _confirmBrandStatusChange(CatalogBrand brand) async {
    final company = _companyById(brand.companyId);
    if (!brand.active && (company == null || !company.active)) {
      _showMessage('Activa primero la empresa propietaria.', error: true);
      return;
    }

    if (brand.active) {
      final confirmed = await _confirm(
        title: 'Desactivar marca',
        message:
            'La marca dejará de estar disponible para nuevos productos. '
            'Sus ${brand.productCount} productos conservarán su clasificación '
            'y el historial.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    }

    _update(() {
      final index = _brands.indexWhere((item) => item.id == brand.id);
      _brands[index] = brand.copyWith(active: !brand.active);
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }

  Future<void> _confirmCategoryStatusChange(CatalogCategory category) async {
    if (category.active) {
      final descendants = _descendantsOf(category.id);
      final confirmed = await _confirm(
        title: category.parentId == null
            ? 'Desactivar categoría'
            : 'Desactivar subcategoría',
        message: category.parentId == null
            ? 'La categoría dejará de estar disponible para nuevos productos. '
                  'Sus ${descendants.length} subcategorías quedarán bloqueadas '
                  'por dependencia, pero conservarán su estado y el historial.'
            : 'La subcategoría dejará de estar disponible para nuevos '
                  'productos. El historial se conservará.',
        action: 'Desactivar',
      );
      if (!confirmed) return;
    } else {
      final parent = _categoryById(category.parentId);
      if (parent != null && !parent.active) {
        _showMessage(
          'Primero activa la categoría superior ${parent.name}.',
          error: true,
        );
        return;
      }
    }

    _update(() {
      final index = _categories.indexWhere((item) => item.id == category.id);
      _categories[index] = category.copyWith(active: !category.active);
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? _catalogRed : _catalogText,
      ),
    );
  }
}
