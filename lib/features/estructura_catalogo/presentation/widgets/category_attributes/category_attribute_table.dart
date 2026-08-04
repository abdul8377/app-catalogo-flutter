part of '../../pages/gestionar_atributos_categoria.dart';

class _AttributeTableHeader extends StatelessWidget {
  const _AttributeTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Atributo')),
          Expanded(flex: 2, child: Text('Tipo')),
          Expanded(flex: 4, child: Text('Configuración')),
          Expanded(flex: 2, child: Text('Origen')),
          Expanded(flex: 2, child: Text('Productos')),
          Expanded(flex: 2, child: Text('Estado')),
          SizedBox(width: 92, child: Text('Acción')),
        ],
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    super.key,
    required this.attribute,
    required this.selected,
    required this.onOpen,
    this.reorderIndex,
  });

  final CategoryAttributeDefinition attribute;
  final bool selected;
  final VoidCallback onOpen;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final settings = <String>[
      if (attribute.requiredToActivate) 'Obligatorio',
      if (attribute.filterable) 'Filtrable',
      if (attribute.visibleInTechnicalSheet) 'Visible en ficha',
      if (attribute.canBeVariantAxis) 'Eje permitido',
    ];
    return InkWell(
      onTap: onOpen,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFAE6) : Colors.white,
          border: Border(
            left: BorderSide(
              color: selected ? _yellow : _border,
              width: selected ? 4 : 1,
            ),
            right: const BorderSide(color: _border),
            bottom: const BorderSide(color: _border),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (reorderIndex != null) ...[
                    ReorderableDragStartListener(
                      index: reorderIndex!,
                      child: const SizedBox(
                        width: 38,
                        height: 44,
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attribute.name,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _dataTypeLabel(attribute.dataType),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                settings.isEmpty
                    ? 'Sin reglas adicionales'
                    : settings.join(' · '),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                attribute.inherited ? 'Heredado' : attribute.ownerCategoryName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${attribute.usedByProductCount}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Expanded(
              flex: 2,
              child: _StatusLabel(
                active: attribute.active && attribute.activeForNewProducts,
                pendingSync: attribute.syncState == AttributeSyncState.pending,
              ),
            ),
            SizedBox(
              width: 92,
              child: TextButton(
                onPressed: onOpen,
                child: Text(attribute.inherited ? 'Ver' : 'Editar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
