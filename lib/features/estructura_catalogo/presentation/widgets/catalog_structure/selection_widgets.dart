part of '../catalog_structure_panel.dart';

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.title,
    required this.children,
    this.header,
  });

  final String title;
  final Widget? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _CatalogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (header != null) ...[const SizedBox(height: 12), header!],
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(child: Column(children: children)),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFFFFF5CC) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? _catalogYellow : _catalogBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          enabled: enabled,
          minTileHeight: 58,
          leading: Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? const Color(0xFFE7AD00) : _catalogBorder,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _catalogText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: _catalogMuted, fontSize: 11),
          ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
