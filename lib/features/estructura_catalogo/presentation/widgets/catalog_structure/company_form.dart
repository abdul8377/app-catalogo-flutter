part of '../catalog_structure_panel.dart';

extension _CatalogCompanyForm on _CatalogStructurePanelState {
  Future<void> _showCompanyForm({CatalogCompany? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final rucController = TextEditingController(text: existing?.ruc);
    final phoneController = TextEditingController(text: existing?.phone);
    final addressController = TextEditingController(text: existing?.address);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: _CatalogDialogHeader(
            icon: Icons.business_outlined,
            title: existing == null ? 'Nueva empresa' : 'Editar empresa',
            subtitle: 'Identificación y datos de contacto',
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _FormSectionTitle('Identificación'),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('estructura_empresa_nombre'),
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre *'),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        final duplicate = _companies.any(
                          (item) =>
                              item.id != existing?.id &&
                              item.name.trim().toLowerCase() ==
                                  name.toLowerCase(),
                        );
                        return duplicate
                            ? 'Ya existe una empresa con ese nombre.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: rucController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RUC (opcional)',
                      ),
                      validator: (value) {
                        final ruc = value?.trim() ?? '';
                        if (ruc.isEmpty) return null;
                        return RegExp(r'^\d{11}$').hasMatch(ruc)
                            ? null
                            : 'El RUC debe contener 11 dígitos.';
                      },
                    ),
                    const SizedBox(height: 14),
                    const _FormSectionTitle('Contacto'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono (opcional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Dirección (opcional)',
                      ),
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

    if (saved != true || !mounted) {
      return;
    }

    final name = nameController.text.trim();
    final ruc = _emptyToNull(rucController.text);
    final phone = _emptyToNull(phoneController.text);
    final address = _emptyToNull(addressController.text);
    _update(() {
      if (existing == null) {
        _companies.add(
          CatalogCompany(
            id: 'company-${DateTime.now().microsecondsSinceEpoch}',
            name: name,
            initials: _initialsFor(name),
            ruc: ruc,
            phone: phone,
            address: address,
            brandCount: 0,
            productCount: 0,
            active: true,
          ),
        );
      } else {
        final index = _companies.indexWhere((item) => item.id == existing.id);
        _companies[index] = existing.copyWith(
          name: name,
          initials: _initialsFor(name),
          ruc: ruc,
          phone: phone,
          address: address,
          active: existing.active,
        );
      }
    });
    widget.onCompaniesChanged?.call(List.unmodifiable(_companies));
  }
}
