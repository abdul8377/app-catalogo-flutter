part of '../catalog_structure_panel.dart';

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _catalogMuted, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: _catalogText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CategoryTreeTile extends StatelessWidget {
  const _CategoryTreeTile({
    required this.category,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.onTap,
    required this.onEdit,
    required this.onToggleStatus,
    this.onAddChild,
  });

  final CatalogCategory category;
  final int depth;
  final bool selected;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onAddChild;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        border: Border.all(
          color: selected ? _catalogYellow : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Row(
            children: [
              SizedBox(width: 12 + depth * 22),
              Icon(
                hasChildren
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.subdirectory_arrow_right_rounded,
                size: 18,
                color: _catalogMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: category.active ? _catalogText : _catalogMuted,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${category.includingDescendantProductCount} prod.',
                style: const TextStyle(color: _catalogMuted, fontSize: 12),
              ),
              PopupMenuButton<String>(
                tooltip: 'Acciones para ${category.name}',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'add_child') onAddChild?.call();
                  if (value == 'status') onToggleStatus();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (onAddChild != null)
                    const PopupMenuItem(
                      value: 'add_child',
                      child: Text('Añadir subcategoría'),
                    ),
                  PopupMenuItem(
                    value: 'status',
                    child: Text(category.active ? 'Desactivar' : 'Activar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
