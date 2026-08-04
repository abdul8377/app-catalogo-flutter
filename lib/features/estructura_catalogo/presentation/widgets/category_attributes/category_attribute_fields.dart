part of '../../pages/gestionar_atributos_categoria.dart';

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.attribute});

  final CategoryAttributeDefinition attribute;

  @override
  Widget build(BuildContext context) {
    final label =
        '${attribute.name}${attribute.requiredToActivate ? ' *' : ''}';
    switch (attribute.dataType) {
      case CategoryAttributeDataType.shortText:
        return TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: attribute.example,
            helperText: attribute.helpText,
          ),
        );
      case CategoryAttributeDataType.number:
        return TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: '10',
            helperText: attribute.helpText,
          ),
        );
      case CategoryAttributeDataType.numberWithUnit:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: '10',
                  helperText: attribute.helpText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                value: attribute.defaultUnitCode,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: attribute.allowedUnitCodes
                    .map(
                      (code) =>
                          DropdownMenuItem(value: code, child: Text(code)),
                    )
                    .toList(),
                onChanged: null,
              ),
            ),
          ],
        );
      case CategoryAttributeDataType.singleList:
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            helperText: attribute.helpText,
          ),
          items: attribute.options
              .where((option) => option.active)
              .map(
                (option) => DropdownMenuItem(
                  value: option.id,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: null,
        );
      case CategoryAttributeDataType.multipleList:
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            helperText: attribute.helpText,
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: attribute.options
                .where((option) => option.active)
                .take(2)
                .map(
                  (option) => Chip(label: Text(option.label), onDeleted: null),
                )
                .toList(),
          ),
        );
      case CategoryAttributeDataType.yesNo:
        return Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: attribute.helpText == null
                ? null
                : Text(attribute.helpText!),
            value: false,
            onChanged: null,
          ),
        );
    }
  }
}

class _EditorSwitch extends StatelessWidget {
  const _EditorSwitch({
    required this.title,
    required this.value,
    required this.readOnly,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool readOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: readOnly ? null : onChanged,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DD),
        borderRadius: BorderRadius.circular(9),
        border: const Border(left: BorderSide(color: _yellow, width: 5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _text,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _blueSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(color: _text, fontSize: 13, height: 1.35),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
