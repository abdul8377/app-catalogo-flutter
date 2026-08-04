part of '../catalog_structure_panel.dart';

extension _CatalogBrandForm on _CatalogStructurePanelState {
  Future<void> _showBrandForm({CatalogBrand? existing}) async {
    final availableCompanies = _companies
        .where((company) => company.active || company.id == existing?.companyId)
        .toList();
    if (availableCompanies.isEmpty) {
      _showMessage('Primero registra una empresa activa.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    var companyId =
        existing?.companyId ??
        _brandCompanyFilterId ??
        _selectedCompanyId ??
        availableCompanies.first.id;
    final ownerLocked = existing != null && existing.productCount > 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: _CatalogDialogHeader(
                icon: Icons.sell_outlined,
                title: existing == null ? 'Nueva marca' : 'Editar marca',
                subtitle: 'Identificación y empresa propietaria',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FormSectionTitle('Empresa propietaria'),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: companyId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Empresa propietaria *',
                          ),
                          items: availableCompanies
                              .map(
                                (company) => DropdownMenuItem(
                                  value: company.id,
                                  child: Text(company.name),
                                ),
                              )
                              .toList(),
                          validator: (value) =>
                              value == null ? 'Selecciona una empresa.' : null,
                          onChanged: ownerLocked
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setDialogState(() => companyId = value);
                                },
                        ),
                        if (ownerLocked) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _catalogBlueSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'La empresa propietaria no puede cambiarse '
                              'porque esta marca tiene '
                              '${existing.productCount} productos.',
                              style: const TextStyle(
                                color: _catalogText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const _FormSectionTitle('Identificación'),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('estructura_marca_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final duplicate = _brands.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.companyId == companyId &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'La empresa ya tiene una marca con ese nombre.'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) {
      return;
    }

    final name = nameController.text.trim();
    _update(() {
      if (existing == null) {
        _brands.add(
          CatalogBrand(
            id: 'brand-${DateTime.now().microsecondsSinceEpoch}',
            companyId: companyId,
            name: name,
            initials: _initialsFor(name),
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _brands.indexWhere((item) => item.id == existing.id);
        _brands[index] = existing.copyWith(
          companyId: companyId,
          name: name,
          initials: _initialsFor(name),
          active: existing.active,
        );
      }
    });
    widget.onBrandsChanged?.call(List.unmodifiable(_brands));
  }
}
