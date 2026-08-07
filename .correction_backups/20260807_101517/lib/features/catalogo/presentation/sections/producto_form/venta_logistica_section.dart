import 'package:flutter/material.dart';

import '../../models/producto_form/venta_logistica_draft.dart';

part 'venta_logistica/common_form_widgets.dart';
part 'venta_logistica/common_states_and_navigation.dart';
part 'venta_logistica/content_editing.dart';
part 'venta_logistica/content_editor.dart';
part 'venta_logistica/content_section.dart';
part 'venta_logistica/content_variant_actions.dart';
part 'venta_logistica/header_and_tabs.dart';
part 'venta_logistica/list_variant_selector.dart';
part 'venta_logistica/matrix_variant_selector.dart';
part 'venta_logistica/navigation_handlers.dart';
part 'venta_logistica/package_editing.dart';
part 'venta_logistica/package_editor.dart';
part 'venta_logistica/package_relations.dart';
part 'venta_logistica/packages_section.dart';
part 'venta_logistica/presentation_editing.dart';
part 'venta_logistica/presentation_editor.dart';
part 'venta_logistica/presentation_persistence.dart';
part 'venta_logistica/presentations_section.dart';
part 'venta_logistica/styles_and_validation.dart';

// ============================================================================
// PASO 4 · VENTA, LOGÍSTICA Y CONTENIDO
//
// Widget autocontenido para integrar en el PageView del registro de productos.
//
// Reglas principales:
// - Presentaciones de venta: obligatorias.
// - Empaques logísticos: opcionales y sin precio.
// - Contenido del producto: opcional y definido por variante.
// - No se gestionan imágenes ni precios en este paso.
// - El alcance variante + presentación alimenta automáticamente el paso 5.
// ============================================================================

enum Step4Section { salesPresentations, logisticsPackages, productContent }

const Color _primary = Color(0xFFFFC500);
const Color _ink = Color(0xFF242830);
const Color _muted = Color(0xFF667085);
const Color _border = Color(0xFFD5DDE8);
const Color _soft = Color(0xFFF4F6F9);
const Color _canvas = Color(0xFFF8FAFC);
const Color _success = Color(0xFF18794E);

class Step4SalesLogisticsContentPanel extends StatefulWidget {
  const Step4SalesLogisticsContentPanel({
    super.key,
    required this.familyName,
    required this.variantLayout,
    required this.variants,
    required this.onBack,
    required this.onNext,
    this.initialPresentations = const [],
    this.initialLogisticsPackages = const [],
    this.initialContentItems = const [],
    this.initialUsesLogisticsPackages,
    this.initialHasProductContent,
    this.catalogVariants = const [],
    this.baseUnits = const [
      'PZA',
      'M',
      'KG',
      'JGO',
      'ROLLO',
      'CAJA',
      'PAR',
      'L',
    ],
    this.onChanged,
  }) : assert(variants.length > 0, 'El paso 4 necesita al menos una variante.'),
       assert(
         baseUnits.length > 0,
         'El paso 4 necesita al menos una unidad de medida.',
       );

  final String familyName;
  final Step4VariantLayout variantLayout;
  final List<Step4VariantOption> variants;

  final List<SalesPresentationDraft> initialPresentations;
  final List<LogisticsPackageDraft> initialLogisticsPackages;
  final List<ProductContentItemDraft> initialContentItems;
  final bool? initialUsesLogisticsPackages;
  final bool? initialHasProductContent;
  final List<CatalogVariantOption> catalogVariants;
  final List<String> baseUnits;

  final VoidCallback onBack;
  final ValueChanged<Step4SalesDraft> onNext;
  final ValueChanged<Step4SalesDraft>? onChanged;

  @override
  State<Step4SalesLogisticsContentPanel> createState() =>
      _Step4SalesLogisticsContentPanelState();
}

class _Step4SalesLogisticsContentPanelState
    extends State<Step4SalesLogisticsContentPanel> {
  void _update(VoidCallback callback) => setState(callback);

  Step4Section _section = Step4Section.salesPresentations;

  late List<SalesPresentationDraft> _presentations;
  late List<LogisticsPackageDraft> _packages;
  late List<ProductContentItemDraft> _contentItems;
  bool? _usesPackages;
  bool? _hasContent;

  int _idSequence = DateTime.now().microsecondsSinceEpoch;

  // --------------------------------------------------------------------------
  // Editor de presentaciones
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _presentationFormKey = GlobalKey<FormState>();
  final TextEditingController _presentationNameController =
      TextEditingController();
  final TextEditingController _presentationEquivalentController =
      TextEditingController(text: '1');
  final TextEditingController _presentationMinimumController =
      TextEditingController(text: '1');
  final TextEditingController _presentationIncrementController =
      TextEditingController(text: '1');

  int? _editingPresentationIndex;
  String _presentationBaseUnit = 'PZA';
  bool _presentationAllowsDecimals = false;
  bool _presentationIsDefault = true;
  bool _presentationForAllVariants = true;
  Set<String> _presentationVariantIds = <String>{};
  Map<String, SalesPresentationVariantRule> _presentationVariantRules = {};

  // --------------------------------------------------------------------------
  // Editor de empaques
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _packageFormKey = GlobalKey<FormState>();
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _packageContainsController =
      TextEditingController(text: '1');
  final TextEditingController _packageSupplierCodeController =
      TextEditingController();
  final TextEditingController _packageDescriptionController =
      TextEditingController();

  int? _editingPackageIndex;
  PackageContentKind _packageContentKind = PackageContentKind.salesPresentation;
  String? _packageContentReferenceId;
  bool _packageForAllVariants = true;
  Set<String> _packageVariantIds = <String>{};

  // --------------------------------------------------------------------------
  // Editor de contenido
  // --------------------------------------------------------------------------

  final GlobalKey<FormState> _contentFormKey = GlobalKey<FormState>();
  final TextEditingController _componentNameController =
      TextEditingController();
  final TextEditingController _componentQuantityController =
      TextEditingController(text: '1');
  final ScrollController _contentTableScrollController = ScrollController();

  String _componentUnit = 'PZA';
  String? _relatedCatalogVariantId;
  String? _selectedContentVariantId;
  int? _editingContentIndex;

  Set<String> get _allVariantIds =>
      widget.variants.map((item) => item.id).toSet();

  Step4SalesDraft get _draft {
    return Step4SalesDraft(
      presentations: List.unmodifiable(_presentations),
      usesLogisticsPackages: _usesPackages,
      logisticsPackages: List.unmodifiable(_packages),
      hasProductContent: _hasContent,
      contentItems: List.unmodifiable(_contentItems),
    );
  }

  @override
  void initState() {
    super.initState();

    _presentations = [...widget.initialPresentations];
    _packages = [...widget.initialLogisticsPackages];
    _contentItems = [...widget.initialContentItems];
    _usesPackages =
        widget.initialUsesLogisticsPackages ??
        (widget.initialLogisticsPackages.isNotEmpty ? true : null);
    _hasContent =
        widget.initialHasProductContent ??
        (widget.initialContentItems.isNotEmpty ? true : null);
    _selectedContentVariantId = widget.variants.first.id;

    if (_presentations.isEmpty) {
      _startNewPresentation(rebuild: false);
    } else {
      _loadPresentation(0, rebuild: false);
    }

    if (_packages.isEmpty) {
      _startNewPackage(rebuild: false);
    } else {
      _loadPackage(0, rebuild: false);
    }

    _startNewContentItem(rebuild: false);
  }

  @override
  void dispose() {
    _presentationNameController.dispose();
    _presentationEquivalentController.dispose();
    _presentationMinimumController.dispose();
    _presentationIncrementController.dispose();
    _packageNameController.dispose();
    _packageContainsController.dispose();
    _packageSupplierCodeController.dispose();
    _packageDescriptionController.dispose();
    _componentNameController.dispose();
    _componentQuantityController.dispose();
    _contentTableScrollController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // INTERFAZ GENERAL
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 22),
                      _buildTabs(),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey(_section),
                          child: _buildCurrentSection(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }
}

String _step4PlainNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
