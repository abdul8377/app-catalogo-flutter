part of '../venta_logistica_section.dart';

extension _Step4NavigationHandlers on _Step4SalesLogisticsContentPanelState {
  void _goToSection(Step4Section section) {
    _update(() {
      _section = section;
    });
  }

  void _handleBack() {
    switch (_section) {
      case Step4Section.salesPresentations:
        widget.onBack();
        break;
      case Step4Section.logisticsPackages:
        _goToSection(Step4Section.salesPresentations);
        break;
      case Step4Section.productContent:
        _goToSection(Step4Section.logisticsPackages);
        break;
    }
  }

  void _handleNext() {
    switch (_section) {
      case Step4Section.salesPresentations:
        if (!_validatePresentationsForNext()) {
          return;
        }
        _goToSection(Step4Section.logisticsPackages);
        break;
      case Step4Section.logisticsPackages:
        if (_usesPackages == null) {
          _showMessage(
            'Indica si el producto utiliza empaques logísticos.',
            error: true,
          );
          return;
        }
        if (_usesPackages == true && _packages.isEmpty) {
          _showMessage(
            'Agrega un empaque o selecciona “No aplica”.',
            error: true,
          );
          return;
        }
        _goToSection(Step4Section.productContent);
        break;
      case Step4Section.productContent:
        if (_hasContent == null) {
          _showMessage(
            'Indica si el producto contiene varios elementos.',
            error: true,
          );
          return;
        }
        if (_hasContent == true && _contentItems.isEmpty) {
          _showMessage(
            'Agrega al menos un componente o selecciona “No aplica”.',
            error: true,
          );
          return;
        }
        if (!_validatePresentationsForNext()) {
          _goToSection(Step4Section.salesPresentations);
          return;
        }
        widget.onNext(_draft);
        break;
    }
  }
}
