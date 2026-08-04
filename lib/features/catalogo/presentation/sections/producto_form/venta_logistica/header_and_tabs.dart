part of '../venta_logistica_section.dart';

extension _Step4HeaderAndTabs on _Step4SalesLogisticsContentPanelState {
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paso 3 · Venta, logística y contenido',
              style: TextStyle(
                color: _ink,
                fontSize: 25,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Define cómo compra el cliente y, cuando corresponda, cómo se transporta el producto o qué incluye.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
            ),
          ],
        );

        final familyBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4C7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Familia: ${widget.familyName} · '
            '${widget.variants.length} '
            '${widget.variants.length == 1 ? 'variante' : 'variantes'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: familyBadge),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: familyBadge,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              section: Step4Section.salesPresentations,
              title: 'Presentaciones de venta',
              status:
                  '${_presentations.length} ${_presentations.length == 1 ? 'configurada' : 'configuradas'}',
              requiredSection: true,
            ),
          ),
          Expanded(
            child: _buildTab(
              section: Step4Section.logisticsPackages,
              title: 'Empaques logísticos',
              status: _usesPackages == false
                  ? 'Opcional · No aplica'
                  : _usesPackages == true
                  ? 'Opcional · ${_packages.length} ${_packages.length == 1 ? 'registrado' : 'registrados'}'
                  : 'Opcional · Sin definir',
            ),
          ),
          Expanded(
            child: _buildTab(
              section: Step4Section.productContent,
              title: 'Contenido del producto',
              status: _hasContent == false
                  ? 'Opcional · No aplica'
                  : _hasContent == true
                  ? 'Opcional · ${_contentItems.length} ${_contentItems.length == 1 ? 'componente' : 'componentes'}'
                  : 'Opcional · Sin definir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required Step4Section section,
    required String title,
    required String status,
    bool requiredSection = false,
  }) {
    final selected = _section == section;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _goToSection(section),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _ink : _muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              requiredSection ? 'Obligatoria · $status' : status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? _muted : _muted.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 3,
              width: selected ? 110 : 0,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    switch (_section) {
      case Step4Section.salesPresentations:
        return _buildPresentationsSection();
      case Step4Section.logisticsPackages:
        return _buildPackagesSection();
      case Step4Section.productContent:
        return _buildContentSection();
    }
  }
}
