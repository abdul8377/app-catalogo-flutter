part of '../../pages/gestionar_atributos_categoria.dart';

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.active, required this.pendingSync});

  final bool active;
  final bool pendingSync;

  @override
  Widget build(BuildContext context) {
    final label = pendingSync
        ? 'Pendiente sync'
        : active
        ? 'Activo'
        : 'Inactivo';
    final background = pendingSync
        ? const Color(0xFFFFF4CC)
        : active
        ? _greenSoft
        : _redSoft;
    final foreground = pendingSync
        ? const Color(0xFF8A5A00)
        : active
        ? _green
        : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pendingSync
                ? Icons.cloud_upload_outlined
                : active
                ? Icons.check_circle_outline
                : Icons.pause_circle_outline,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.icon,
    this.background = const Color(0xFFF1F3F5),
  });

  final String label;
  final IconData? icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: _muted),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      selectedColor: const Color(0xFFFFF4C2),
      side: BorderSide(color: selected ? _yellow : _border),
      onSelected: (_) => onSelected(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _yellow,
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 44),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _border),
        minimumSize: const Size(0, 44),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.data_object_rounded, size: 38, color: _muted),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

String _dataTypeLabel(CategoryAttributeDataType type) {
  return switch (type) {
    CategoryAttributeDataType.shortText => 'Texto corto',
    CategoryAttributeDataType.number => 'Número',
    CategoryAttributeDataType.numberWithUnit => 'Número con unidad',
    CategoryAttributeDataType.singleList => 'Lista de una opción',
    CategoryAttributeDataType.multipleList => 'Lista de varias opciones',
    CategoryAttributeDataType.yesNo => 'Sí / No',
  };
}

String _captureLevelLabel(AttributeCaptureLevel level) {
  return switch (level) {
    AttributeCaptureLevel.family => 'Compartido por toda la familia',
    AttributeCaptureLevel.variant => 'Cambia por variante',
    AttributeCaptureLevel.decideWhenRegistering =>
      'Se decide al registrar el producto',
  };
}

String _filterLabel(AttributeListFilter filter) {
  return switch (filter) {
    AttributeListFilter.all => 'Todos',
    AttributeListFilter.own => 'Propios',
    AttributeListFilter.inherited => 'Heredados',
    AttributeListFilter.inactive => 'Inactivos',
  };
}

bool _supportsAxis(CategoryAttributeDataType type) {
  return type == CategoryAttributeDataType.number ||
      type == CategoryAttributeDataType.numberWithUnit ||
      type == CategoryAttributeDataType.singleList;
}

String _toKey(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var normalized = value.trim().toLowerCase();
  accents.forEach((source, replacement) {
    normalized = normalized.replaceAll(source, replacement);
  });
  normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  normalized = normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized;
}

String _canonicalAttributeIdentity(String value) {
  final normalized = _toKey(value).replaceAll('_', '');
  if (value.trim() == 'Ø' || normalized == 'diameter' || normalized == 'diam') {
    return 'diametro';
  }
  return normalized;
}

double? _parseDouble(String value) {
  final normalized = value.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
