part of '../catalog_structure_panel.dart';

class _RelationCategoryTile extends StatelessWidget {
  const _RelationCategoryTile({
    required this.category,
    required this.depth,
    required this.checked,
    required this.added,
    required this.removalPending,
    required this.locked,
    required this.productCount,
    required this.brandName,
    required this.onChanged,
    required this.onViewProducts,
  });

  final CatalogCategory category;
  final int depth;
  final bool checked;
  final bool added;
  final bool removalPending;
  final bool locked;
  final int productCount;
  final String brandName;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onViewProducts;

  @override
  Widget build(BuildContext context) {
    final status = added
        ? 'Añadida en esta edición'
        : removalPending
        ? 'Eliminación pendiente'
        : locked
        ? 'Vinculada · $productCount productos activos'
        : checked
        ? 'Ya vinculada'
        : 'Disponible';
    final background = removalPending
        ? _catalogRedSoft
        : added
        ? _catalogGreenSoft
        : checked
        ? const Color(0xFFFFFAE8)
        : Colors.white;
    final borderColor = removalPending
        ? const Color(0xFFF4A6A1)
        : added
        ? const Color(0xFF99D6B7)
        : checked
        ? _catalogYellow
        : _catalogBorder;

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, bottom: 7),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: CheckboxListTile(
          value: checked,
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          secondary: locked
              ? IconButton(
                  tooltip: 'Ver productos afectados de $brandName',
                  onPressed: onViewProducts,
                  icon: const Icon(Icons.lock_outline_rounded),
                )
              : null,
          title: Text(
            category.name,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            status,
            style: TextStyle(
              color: removalPending
                  ? _catalogRed
                  : added
                  ? _catalogGreen
                  : _catalogMuted,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
