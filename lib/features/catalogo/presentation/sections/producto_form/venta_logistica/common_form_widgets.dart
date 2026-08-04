part of '../venta_logistica_section.dart';

extension _Step4CommonFormWidgets on _Step4SalesLogisticsContentPanelState {
  Widget _buildSectionIntro({
    required IconData icon,
    required String title,
    required String description,
    required Widget trailing,
  }) {
    return _panel(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4C7),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 850) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 14), trailing],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 20),
              Flexible(child: trailing),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBinaryChoice({
    required String negativeLabel,
    required String positiveLabel,
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        ChoiceChip(
          selected: currentValue == false,
          onSelected: (_) => onChanged(false),
          label: Text(negativeLabel),
          selectedColor: _ink,
          backgroundColor: _soft,
          labelStyle: TextStyle(
            color: currentValue == false ? Colors.white : _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(color: currentValue == false ? _ink : _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        ChoiceChip(
          selected: currentValue == true,
          onSelected: (_) => onChanged(true),
          label: Text(positiveLabel),
          selectedColor: _primary,
          backgroundColor: _soft,
          labelStyle: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          side: BorderSide(color: currentValue == true ? _primary : _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ],
    );
  }

  Widget _buildScopeEditor({
    required String title,
    required bool allSelected,
    required Set<String> selectedIds,
    required ValueChanged<bool> onAllChanged,
    required VoidCallback onChangeSelection,
  }) {
    if (widget.variantLayout == Step4VariantLayout.single) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: _success, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Variante automática · ${widget.variants.first.label}',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _radioOption(
          selected: allSelected,
          title: 'Todas las variantes (${widget.variants.length})',
          onTap: () => onAllChanged(true),
        ),
        const SizedBox(height: 7),
        _radioOption(
          selected: !allSelected,
          title: 'Variantes seleccionadas (${selectedIds.length})',
          onTap: () => onAllChanged(false),
        ),
        if (!allSelected) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onChangeSelection,
              icon: const Icon(Icons.tune, size: 17),
              label: const Text('Cambiar selección'),
              style: _outlinedButtonStyle(compact: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _radioOption({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _primary : _border),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: _ink,
              onChanged: (_) => onTap(),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _undecidedOptionalState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return _panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(
          children: [
            Icon(icon, size: 44, color: _muted),
            const SizedBox(height: 13),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
