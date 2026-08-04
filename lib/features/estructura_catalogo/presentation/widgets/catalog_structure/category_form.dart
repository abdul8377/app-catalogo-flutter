part of '../catalog_structure_panel.dart';

extension _CatalogCategoryForm on _CatalogStructurePanelState {
  Future<void> _showCategoryForm({
    CatalogCategory? existing,
    String? parentId,
    bool createSubcategory = false,
  }) async {
    final isExistingChild = existing?.parentId != null;
    final isSubcategory = createSubcategory || isExistingChild;
    var selectedParentId = existing?.parentId ?? parentId;

    if (isSubcategory && selectedParentId == null) {
      _showMessage('Selecciona primero una categoría principal.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.name);
    final descriptionController = TextEditingController(
      text: existing?.description,
    );
    final activeRoots = _categories
        .where(
          (item) =>
              item.parentId == null &&
              (item.active || item.id == selectedParentId),
        )
        .toList();

    final title = existing == null
        ? isSubcategory
              ? 'Nueva subcategoría'
              : 'Nueva categoría raíz'
        : isExistingChild
        ? 'Editar subcategoría'
        : 'Editar categoría raíz';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: _CatalogDialogHeader(
                icon: isSubcategory
                    ? Icons.subdirectory_arrow_right_rounded
                    : Icons.account_tree_outlined,
                title: title,
                subtitle: isSubcategory
                    ? 'Ubicación e identificación de la subcategoría'
                    : 'Información de la categoría principal',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _FormSectionTitle('Ubicación'),
                        const SizedBox(height: 10),
                        if (isSubcategory)
                          DropdownButtonFormField<String>(
                            initialValue: selectedParentId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Categoría superior *',
                              helperText:
                                  'La subcategoría heredará sus atributos.',
                            ),
                            items: activeRoots
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            validator: (value) => value == null
                                ? 'Selecciona una categoría superior.'
                                : null,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedParentId = value;
                              });
                            },
                          )
                        else
                          const InputDecorator(
                            decoration: InputDecoration(labelText: 'Nivel'),
                            child: Text('Categoría principal'),
                          ),
                        const SizedBox(height: 14),
                        const _FormSectionTitle('Información'),
                        const SizedBox(height: 10),
                        TextFormField(
                          key: const Key('estructura_categoria_nombre'),
                          controller: nameController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: isSubcategory
                                ? 'Nombre de la subcategoría *'
                                : 'Nombre de la categoría *',
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) {
                              return 'El nombre es obligatorio.';
                            }
                            final effectiveParent = isSubcategory
                                ? selectedParentId
                                : null;
                            final duplicate = _categories.any(
                              (item) =>
                                  item.id != existing?.id &&
                                  item.parentId == effectiveParent &&
                                  item.name.trim().toLowerCase() ==
                                      name.toLowerCase(),
                            );
                            return duplicate
                                ? 'Ya existe un registro con ese nombre '
                                      'en el mismo nivel.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _catalogBlueSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSubcategory
                                ? 'Las marcas se relacionan con la categoría '
                                      'principal. Esta subcategoría quedará '
                                      'disponible automáticamente.'
                                : 'Después podrás añadir subcategorías y '
                                      'gestionar los atributos técnicos.',
                            style: const TextStyle(
                              color: _catalogText,
                              fontSize: 12,
                              height: 1.4,
                            ),
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
                  child: Text(existing == null ? 'Crear' : 'Guardar cambios'),
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

    final savedName = nameController.text.trim();
    final savedDescription = _emptyToNull(descriptionController.text);
    _update(() {
      if (existing == null) {
        final created = CatalogCategory(
          id: 'category-${DateTime.now().microsecondsSinceEpoch}',
          parentId: isSubcategory ? selectedParentId : null,
          name: savedName,
          description: savedDescription,
          directProductCount: 0,
          includingDescendantProductCount: 0,
          active: true,
        );
        _categories.add(created);
        _selectedCategoryId = created.id;
      } else {
        final index = _categories.indexWhere((item) => item.id == existing.id);
        _categories[index] = existing.copyWith(
          parentId: isExistingChild ? selectedParentId : null,
          clearParent: !isExistingChild,
          name: savedName,
          description: savedDescription,
          active: existing.active,
        );
        _selectedCategoryId = existing.id;
      }
      _categorySection = CategoryDetailSection.summary;
    });
    widget.onCategoriesChanged?.call(List.unmodifiable(_categories));
  }
}
