from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
DESIGN_PATH = ROOT / "lib/features/estructura_catalogo/presentation/widgets/estructura_catalogo_corregida.dart"
MANAGER_PATH = ROOT / "lib/features/estructura_catalogo/presentation/pages/gestionar_atributos_categoria.dart"
INTEGRATED_PATH = ROOT / "lib/features/estructura_catalogo/presentation/pages/estructura_catalogo_integrada.dart"
TEST_PATH = ROOT / "test/estructura_catalogo_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
    label: str,
    *,
    anchor: str | None = None,
) -> str:
    search_from = 0
    if anchor is not None:
        count = source.count(anchor)
        if count != 1:
            fail(
                f"No se encontró de forma única el ancla de “{label}”. "
                f"Se encontraron {count}."
            )
        search_from = source.index(anchor)

    start = source.find(start_marker, search_from)
    if start < 0:
        fail(f"No se encontró el inicio de “{label}”.")
    if source.find(start_marker, start + len(start_marker)) >= 0 and anchor is None:
        fail(f"El inicio de “{label}” no es único.")
    end = source.find(end_marker, start + len(start_marker))
    if end < 0:
        fail(f"No se encontró el final de “{label}”.")
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


def replace_within(
    source: str,
    start_marker: str,
    end_marker: str,
    old: str,
    new: str,
    label: str,
) -> str:
    start = source.find(start_marker)
    if start < 0:
        fail(f"No se encontró el inicio de “{label}”.")
    end = source.find(end_marker, start + len(start_marker))
    if end < 0:
        fail(f"No se encontró el final de “{label}”.")
    segment = source[start:end]
    count = segment.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}” dentro de su método. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source[:start] + segment.replace(old, new, 1) + source[end:]


def dart_braces_balanced(source: str) -> bool:
    stack: list[str] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    quote: str | None = None
    line_comment = False
    block_comment = 0
    escaped = False
    index = 0

    while index < len(source):
        char = source[index]
        nxt = source[index + 1] if index + 1 < len(source) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue
        if block_comment:
            if char == "/" and nxt == "*":
                block_comment += 1
                index += 2
                continue
            if char == "*" and nxt == "/":
                block_comment -= 1
                index += 2
                continue
            index += 1
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char == "/" and nxt == "/":
            line_comment = True
            index += 2
            continue
        if char == "/" and nxt == "*":
            block_comment = 1
            index += 2
            continue
        if char in {"'", '"'}:
            quote = char
            index += 1
            continue
        if char in "([{":
            stack.append(char)
        elif char in ")]}":
            if not stack or stack.pop() != pairs[char]:
                return False
        index += 1

    return not stack and quote is None and block_comment == 0


for path in (DESIGN_PATH, MANAGER_PATH, INTEGRATED_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

design = DESIGN_PATH.read_text(encoding="utf-8")
manager = MANAGER_PATH.read_text(encoding="utf-8")
integrated = INTEGRATED_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

required_design_markers = (
    "Categorías globales de dos niveles",
    "Vista previa de atributos",
    "Añadir subcategoría",
    "categorías principales habilitadas",
)
missing = [marker for marker in required_design_markers if marker not in design]
if missing:
    fail(
        "La fase 1 coherente no coincide con la versión esperada. "
        f"Faltan: {', '.join(missing)}"
    )
if "await Navigator.of(context).push<void>(" not in integrated:
    fail("No se encontró la navegación actual de Gestionar atributos.")
if "labelText: 'Clave interna'" not in manager:
    fail("El formulario de atributos ya no coincide con la versión esperada.")

design = replace_once(design, 'const _catalogBlueSoft = Color(0xFFEFF6FF);', 'const _catalogYellowSoft = Color(0xFFFFF4CC);\nconst _catalogBlueSoft = _catalogYellowSoft;', 'paleta amarilla secundaria')
design = replace_once(design, 'enum CatalogStructureTab { companies, brands, categories, brandCategories }', 'ThemeData _catalogModuleTheme(BuildContext context) {\n  final base = Theme.of(context);\n  const overlay = Color(0x26FFC500);\n  const shadow = Color(0x52FFC500);\n  const focusedBorder = OutlineInputBorder(\n    borderSide: BorderSide(color: _catalogYellow, width: 1.6),\n    borderRadius: BorderRadius.all(Radius.circular(11)),\n  );\n\n  return base.copyWith(\n    colorScheme: base.colorScheme.copyWith(\n      primary: _catalogYellow,\n      onPrimary: Colors.black,\n      secondary: _catalogYellow,\n      onSecondary: Colors.black,\n      surfaceTint: _catalogYellow,\n    ),\n    filledButtonTheme: FilledButtonThemeData(\n      style: FilledButton.styleFrom(\n        backgroundColor: _catalogYellow,\n        foregroundColor: Colors.black,\n        overlayColor: overlay,\n        shadowColor: shadow,\n        elevation: 1,\n      ),\n    ),\n    outlinedButtonTheme: OutlinedButtonThemeData(\n      style: OutlinedButton.styleFrom(\n        foregroundColor: _catalogText,\n        side: const BorderSide(color: _catalogYellow),\n        overlayColor: overlay,\n      ),\n    ),\n    textButtonTheme: TextButtonThemeData(\n      style: TextButton.styleFrom(\n        foregroundColor: _catalogText,\n        overlayColor: overlay,\n      ),\n    ),\n    chipTheme: base.chipTheme.copyWith(\n      selectedColor: _catalogYellowSoft,\n      checkmarkColor: Colors.black,\n      side: const BorderSide(color: _catalogYellow),\n      labelStyle: const TextStyle(color: _catalogText),\n    ),\n    inputDecorationTheme: base.inputDecorationTheme.copyWith(\n      filled: true,\n      fillColor: Colors.white,\n      focusedBorder: focusedBorder,\n      enabledBorder: const OutlineInputBorder(\n        borderSide: BorderSide(color: _catalogBorder),\n        borderRadius: BorderRadius.all(Radius.circular(11)),\n      ),\n      border: const OutlineInputBorder(\n        borderSide: BorderSide(color: _catalogBorder),\n        borderRadius: BorderRadius.all(Radius.circular(11)),\n      ),\n    ),\n  );\n}\n\nenum CatalogStructureTab { companies, brands, categories, brandCategories }', 'tema local del módulo')
design = replace_once(design, '  String? _selectedBrandId;\n', '  String? _selectedBrandId;\n  String? _brandCompanyFilterId;\n', 'estado del filtro de empresa')
design = replace_once(design, '    _selectedBrandId = _firstBrandIdFor(_selectedCompanyId);\n', '    _selectedBrandId = _firstBrandIdFor(_selectedCompanyId);\n    _brandCompanyFilterId = null;\n', 'inicializar filtro de empresa')
design = replace_between(design, '  @override\n  Widget build(BuildContext context) {', '  Widget _buildHeader() {', '  @override\n  Widget build(BuildContext context) {\n    return Theme(\n      data: _catalogModuleTheme(context),\n      child: ColoredBox(\n        color: _catalogBackground,\n        child: Column(\n          crossAxisAlignment: CrossAxisAlignment.stretch,\n          children: [\n            _buildHeader(),\n            Expanded(\n              child: LayoutBuilder(\n                builder: (context, constraints) {\n                  return SingleChildScrollView(\n                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),\n                    child: ConstrainedBox(\n                      constraints: BoxConstraints(\n                        minHeight: constraints.maxHeight - 46,\n                      ),\n                      child: Column(\n                        crossAxisAlignment: CrossAxisAlignment.stretch,\n                        children: [\n                          _buildMainTabs(),\n                          const SizedBox(height: 18),\n                          AnimatedSwitcher(\n                            duration: const Duration(milliseconds: 180),\n                            child: KeyedSubtree(\n                              key: ValueKey(_tab),\n                              child: _buildCurrentTab(constraints.maxWidth),\n                            ),\n                          ),\n                        ],\n                      ),\n                    ),\n                  );\n                },\n              ),\n            ),\n          ],\n        ),\n      ),\n    );\n  }', 'tema y estructura principal', anchor='class _CatalogStructurePanelState extends State<CatalogStructurePanel> {')
design = replace_once(design, "          setState(() {\n            _tab = value;\n            _query = '';\n            _filter = CatalogRecordFilter.all;\n          });", "          setState(() {\n            _tab = value;\n            _query = '';\n            _filter = CatalogRecordFilter.all;\n            if (value == CatalogStructureTab.brands) {\n              _brandCompanyFilterId = null;\n            }\n          });", 'reiniciar filtro de marcas')
design = replace_once(design, "                    _tab = CatalogStructureTab.brands;\n                    _selectedCompanyId = company.id;\n                    _query = '';", "                    _tab = CatalogStructureTab.brands;\n                    _selectedCompanyId = company.id;\n                    _brandCompanyFilterId = company.id;\n                    _query = '';", 'abrir marcas de una empresa')
design = replace_once(design, '_selectedCompanyId == null || brand.companyId == _selectedCompanyId;', '_brandCompanyFilterId == null ||\n          brand.companyId == _brandCompanyFilterId;', 'filtrar marcas mediante dropdown')
design = replace_between(design, '  Widget _buildCompanyFilter() {', '  Widget _buildBrandCard(CatalogBrand brand) {', "  Widget _buildCompanyFilter() {\n    const allCompanies = '__all_companies__';\n    final selectedCompanyId = _companies.any(\n      (company) => company.id == _brandCompanyFilterId,\n    )\n        ? _brandCompanyFilterId\n        : null;\n\n    return Align(\n      alignment: Alignment.centerLeft,\n      child: KeyedSubtree(\n        key: const Key('estructura_filtro_empresa'),\n        child: SizedBox(\n          width: 360,\n          child: DropdownButtonFormField<String>(\n          key: ValueKey(\n            'estructura_filtro_empresa_${selectedCompanyId ?? allCompanies}',\n          ),\n          initialValue: selectedCompanyId ?? allCompanies,\n          isExpanded: true,\n          decoration: const InputDecoration(\n            labelText: 'Empresa',\n            prefixIcon: Icon(Icons.business_outlined),\n          ),\n          items: [\n            const DropdownMenuItem(\n              value: allCompanies,\n              child: Text('Todas las empresas'),\n            ),\n            ..._companies.map(\n              (company) => DropdownMenuItem(\n                value: company.id,\n                child: Text(company.name),\n              ),\n            ),\n          ],\n            onChanged: (value) {\n              setState(() {\n                _brandCompanyFilterId =\n                    value == null || value == allCompanies ? null : value;\n              });\n            },\n          ),\n        ),\n      ),\n    );\n  }", 'dropdown de empresa')
design = replace_once(design, '                color: const Color(0xFF2F66EB),', '                color: _catalogYellow,', 'avatar de marca amarillo')
design = replace_once(design, '        existing?.companyId ??\n        _selectedCompanyId ??\n        availableCompanies.first.id;', '        existing?.companyId ??\n        _brandCompanyFilterId ??\n        _selectedCompanyId ??\n        availableCompanies.first.id;', 'empresa inicial del formulario de marca')
design = replace_between(design, '  Widget _buildToolbar({', '  Widget _filterChip(CatalogRecordFilter filter, String label) {', "  Widget _buildToolbar({\n    required String searchHint,\n    required String createLabel,\n    required VoidCallback onCreate,\n    required bool showStatusFilters,\n    String? secondaryLabel,\n    VoidCallback? onSecondary,\n  }) {\n    final actions = <Widget>[\n      if (secondaryLabel != null && onSecondary != null)\n        _SecondaryButton(\n          label: secondaryLabel,\n          onPressed: onSecondary,\n        ),\n      _PrimaryButton(\n        label: createLabel,\n        icon: Icons.add_rounded,\n        onPressed: onCreate,\n      ),\n    ];\n\n    return Column(\n      crossAxisAlignment: CrossAxisAlignment.stretch,\n      children: [\n        TextField(\n          key: const Key('estructura_busqueda'),\n          onChanged: (value) => setState(() => _query = value),\n          decoration: InputDecoration(\n            hintText: searchHint,\n            prefixIcon: const Icon(Icons.search_rounded),\n            filled: true,\n            fillColor: Colors.white,\n          ),\n        ),\n        const SizedBox(height: 12),\n        Wrap(\n          spacing: 12,\n          runSpacing: 10,\n          alignment: WrapAlignment.spaceBetween,\n          crossAxisAlignment: WrapCrossAlignment.center,\n          children: [\n            if (showStatusFilters)\n              Wrap(\n                spacing: 8,\n                runSpacing: 8,\n                children: [\n                  _filterChip(CatalogRecordFilter.all, 'Todas'),\n                  _filterChip(CatalogRecordFilter.active, 'Activas'),\n                  _filterChip(CatalogRecordFilter.inactive, 'Inactivas'),\n                ],\n              ),\n            Wrap(\n              spacing: 8,\n              runSpacing: 8,\n              children: actions,\n            ),\n          ],\n        ),\n      ],\n    );\n  }", 'buscador de ancho completo')
design = replace_once(design, '    return ChoiceChip(\n      label: Text(label),\n      selected: _filter == filter,\n      onSelected: (_) => setState(() => _filter = filter),\n    );', '    return ChoiceChip(\n      label: Text(label),\n      selected: _filter == filter,\n      selectedColor: _catalogYellowSoft,\n      side: BorderSide(\n        color: _filter == filter ? _catalogYellow : _catalogBorder,\n      ),\n      onSelected: (_) => setState(() => _filter = filter),\n    );', 'chips de estado amarillos')
design = replace_within(design, '  Future<void> _showCompanyForm({CatalogCompany? existing}) async {', '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', "          title: Text(existing == null ? 'Nueva empresa' : 'Editar empresa'),", "          title: _CatalogDialogHeader(\n            icon: Icons.business_outlined,\n            title: existing == null ? 'Nueva empresa' : 'Editar empresa',\n            subtitle: 'Identificación y datos de contacto',\n          ),", 'encabezado del formulario de empresa')
design = replace_within(design, '  Future<void> _showCompanyForm({CatalogCompany? existing}) async {', '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '            width: 540,', '            width: 620,', 'ancho del formulario de empresa')
design = replace_within(design, '  Future<void> _showCompanyForm({CatalogCompany? existing}) async {', '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', "                  children: [\n                    TextFormField(\n                      key: const Key('estructura_empresa_nombre'),", "                  children: [\n                    const _FormSectionTitle('Identificación'),\n                    const SizedBox(height: 10),\n                    TextFormField(\n                      key: const Key('estructura_empresa_nombre'),", 'sección de identificación de empresa')
design = replace_within(design, '  Future<void> _showCompanyForm({CatalogCompany? existing}) async {', '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '                    TextFormField(\n                      controller: phoneController,', "                    const _FormSectionTitle('Contacto'),\n                    const SizedBox(height: 10),\n                    TextFormField(\n                      controller: phoneController,", 'sección de contacto de empresa')
design = replace_within(design, '  Future<void> _showCompanyForm({CatalogCompany? existing}) async {', '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', "                    const SizedBox(height: 12),\n                    const Text(\n                      'El estado se administra desde las acciones de la '\n                      'empresa para mostrar antes el impacto.',\n                      style: TextStyle(color: _catalogMuted, fontSize: 12),\n                    ),", '', 'retirar nota redundante de empresa')
design = replace_within(design, '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '  Future<void> _showCategoryForm({', "              title: Text(existing == null ? 'Nueva marca' : 'Editar marca'),", "              title: _CatalogDialogHeader(\n                icon: Icons.sell_outlined,\n                title: existing == null ? 'Nueva marca' : 'Editar marca',\n                subtitle: 'Identificación y empresa propietaria',\n              ),", 'encabezado del formulario de marca')
design = replace_within(design, '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '  Future<void> _showCategoryForm({', '                      children: [\n                        DropdownButtonFormField<String>(', "                      children: [\n                        const _FormSectionTitle('Empresa propietaria'),\n                        const SizedBox(height: 10),\n                        DropdownButtonFormField<String>(", 'sección de pertenencia de marca')
design = replace_within(design, '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '  Future<void> _showCategoryForm({', "                        TextFormField(\n                          key: const Key('estructura_marca_nombre'),", "                        const _FormSectionTitle('Identificación'),\n                        const SizedBox(height: 10),\n                        TextFormField(\n                          key: const Key('estructura_marca_nombre'),", 'sección de identificación de marca')
design = replace_within(design, '  Future<void> _showBrandForm({CatalogBrand? existing}) async {', '  Future<void> _showCategoryForm({', "                        const SizedBox(height: 12),\n                        const Text(\n                          'Las categorías de la marca se administran en '\n                          'Categorías por marca.',\n                          style: TextStyle(color: _catalogMuted, fontSize: 12),\n                        ),", '', 'retirar nota redundante de marca')
design = replace_within(design, '  Future<void> _showCategoryForm({', '  Future<void> _showAttributeForm(', '              title: Text(title),', "              title: _CatalogDialogHeader(\n                icon: isSubcategory\n                    ? Icons.subdirectory_arrow_right_rounded\n                    : Icons.account_tree_outlined,\n                title: title,\n                subtitle: isSubcategory\n                    ? 'Ubicación e identificación de la subcategoría'\n                    : 'Información de la categoría principal',\n              ),", 'encabezado del formulario de categoría')
design = replace_within(design, '  Future<void> _showCategoryForm({', '  Future<void> _showAttributeForm(', '                      children: [\n                        if (isSubcategory)', "                      children: [\n                        const _FormSectionTitle('Ubicación'),\n                        const SizedBox(height: 10),\n                        if (isSubcategory)", 'sección de ubicación de categoría')
design = replace_within(design, '  Future<void> _showCategoryForm({', '  Future<void> _showAttributeForm(', "                        TextFormField(\n                          key: const Key('estructura_categoria_nombre'),", "                        const _FormSectionTitle('Información'),\n                        const SizedBox(height: 10),\n                        TextFormField(\n                          key: const Key('estructura_categoria_nombre'),", 'sección de información de categoría')
design = replace_once(design, 'class _CatalogCard extends StatelessWidget {', 'class _CatalogDialogHeader extends StatelessWidget {\n  const _CatalogDialogHeader({\n    required this.icon,\n    required this.title,\n    required this.subtitle,\n  });\n\n  final IconData icon;\n  final String title;\n  final String subtitle;\n\n  @override\n  Widget build(BuildContext context) {\n    return Row(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: [\n        Container(\n          width: 46,\n          height: 46,\n          decoration: BoxDecoration(\n            color: _catalogYellow,\n            borderRadius: BorderRadius.circular(12),\n            boxShadow: const [\n              BoxShadow(\n                color: Color(0x42FFC500),\n                blurRadius: 12,\n                offset: Offset(0, 4),\n              ),\n            ],\n          ),\n          child: Icon(icon, color: Colors.black),\n        ),\n        const SizedBox(width: 12),\n        Expanded(\n          child: Column(\n            crossAxisAlignment: CrossAxisAlignment.start,\n            children: [\n              Text(\n                title,\n                style: const TextStyle(\n                  color: _catalogText,\n                  fontSize: 20,\n                  fontWeight: FontWeight.w800,\n                ),\n              ),\n              const SizedBox(height: 3),\n              Text(\n                subtitle,\n                style: const TextStyle(\n                  color: _catalogMuted,\n                  fontSize: 12,\n                  height: 1.35,\n                ),\n              ),\n            ],\n          ),\n        ),\n      ],\n    );\n  }\n}\n\nclass _FormSectionTitle extends StatelessWidget {\n  const _FormSectionTitle(this.label);\n\n  final String label;\n\n  @override\n  Widget build(BuildContext context) {\n    return Row(\n      children: [\n        Container(\n          width: 5,\n          height: 20,\n          decoration: BoxDecoration(\n            color: _catalogYellow,\n            borderRadius: BorderRadius.circular(3),\n          ),\n        ),\n        const SizedBox(width: 8),\n        Text(\n          label,\n          style: const TextStyle(\n            color: _catalogText,\n            fontSize: 14,\n            fontWeight: FontWeight.w800,\n          ),\n        ),\n      ],\n    );\n  }\n}\n\nclass _CatalogCard extends StatelessWidget {', 'componentes visuales de formularios')
design = replace_once(design, '        style: OutlinedButton.styleFrom(\n          foregroundColor: _catalogText,\n          side: const BorderSide(color: _catalogBorder),\n          shape: RoundedRectangleBorder(\n            borderRadius: BorderRadius.circular(10),\n          ),\n        ),', '        style: OutlinedButton.styleFrom(\n          foregroundColor: _catalogText,\n          side: const BorderSide(color: _catalogYellow),\n          overlayColor: const Color(0x26FFC500),\n          shadowColor: const Color(0x42FFC500),\n          shape: RoundedRectangleBorder(\n            borderRadius: BorderRadius.circular(10),\n          ),\n        ),', 'estilo amarillo de botones secundarios')
manager = replace_once(manager, 'const _blue = Color(0xFF2563EB);\nconst _blueSoft = Color(0xFFEFF6FF);', 'const _blue = _yellow;\nconst _blueSoft = Color(0xFFFFF4CC);', 'paleta del gestor de atributos')
manager = replace_once(manager, 'enum CategoryAttributeDataType {', 'ThemeData _attributeManagerTheme(BuildContext context) {\n  final base = Theme.of(context);\n  const overlay = Color(0x26FFC500);\n  const focusedBorder = OutlineInputBorder(\n    borderSide: BorderSide(color: _yellow, width: 1.6),\n    borderRadius: BorderRadius.all(Radius.circular(10)),\n  );\n\n  return base.copyWith(\n    colorScheme: base.colorScheme.copyWith(\n      primary: _yellow,\n      onPrimary: Colors.black,\n      secondary: _yellow,\n      onSecondary: Colors.black,\n      surfaceTint: _yellow,\n    ),\n    filledButtonTheme: FilledButtonThemeData(\n      style: FilledButton.styleFrom(\n        backgroundColor: _yellow,\n        foregroundColor: Colors.black,\n        overlayColor: overlay,\n        shadowColor: const Color(0x52FFC500),\n        elevation: 1,\n      ),\n    ),\n    outlinedButtonTheme: OutlinedButtonThemeData(\n      style: OutlinedButton.styleFrom(\n        foregroundColor: _text,\n        side: const BorderSide(color: _yellow),\n        overlayColor: overlay,\n      ),\n    ),\n    textButtonTheme: TextButtonThemeData(\n      style: TextButton.styleFrom(\n        foregroundColor: _text,\n        overlayColor: overlay,\n      ),\n    ),\n    chipTheme: base.chipTheme.copyWith(\n      selectedColor: const Color(0xFFFFF4CC),\n      checkmarkColor: Colors.black,\n      side: const BorderSide(color: _yellow),\n      labelStyle: const TextStyle(color: _text),\n    ),\n    inputDecorationTheme: base.inputDecorationTheme.copyWith(\n      filled: true,\n      fillColor: Colors.white,\n      focusedBorder: focusedBorder,\n      enabledBorder: const OutlineInputBorder(\n        borderSide: BorderSide(color: _border),\n        borderRadius: BorderRadius.all(Radius.circular(10)),\n      ),\n      border: const OutlineInputBorder(\n        borderSide: BorderSide(color: _border),\n        borderRadius: BorderRadius.all(Radius.circular(10)),\n      ),\n    ),\n  );\n}\n\nenum CategoryAttributeDataType {', 'tema del gestor de atributos')
manager = replace_once(manager, '    _filterable = source?.filterable ?? false;', '    _filterable = source?.filterable ?? true;', 'filtro predeterminado para atributos nuevos')
manager = replace_once(manager, '          attribute.name.toLowerCase().contains(query) ||\n          attribute.keyName.toLowerCase().contains(query);', '          attribute.name.toLowerCase().contains(query);', 'búsqueda solo por nombre')
manager = replace_once(manager, "                    hintText: 'Buscar por nombre o clave',", "                    hintText: 'Buscar atributo',", 'texto del buscador de atributos')
manager = replace_between(manager, '  @override\n  Widget build(BuildContext context) {', '  Widget _buildHeader() {', '  @override\n  Widget build(BuildContext context) {\n    return Theme(\n      data: _attributeManagerTheme(context),\n      child: Scaffold(\n        backgroundColor: _background,\n        body: SafeArea(\n          child: LayoutBuilder(\n            builder: (context, constraints) {\n              final wide = constraints.maxWidth >= 900;\n              final compactEditor = !wide;\n              if (compactEditor && _editorOpen) {\n                return _buildCompactEditor();\n              }\n\n              return Column(\n                crossAxisAlignment: CrossAxisAlignment.stretch,\n                children: [\n                  _buildHeader(),\n                  Expanded(\n                    child: Padding(\n                      padding: EdgeInsets.fromLTRB(\n                        wide ? 24 : 16,\n                        16,\n                        wide ? 24 : 16,\n                        20,\n                      ),\n                      child: Row(\n                        crossAxisAlignment: CrossAxisAlignment.stretch,\n                        children: [\n                          Expanded(child: _buildListPanel()),\n                          if (wide && _editorOpen) ...[\n                            const SizedBox(width: 16),\n                            SizedBox(width: 470, child: _buildEditorPanel()),\n                          ],\n                        ],\n                      ),\n                    ),\n                  ),\n                ],\n              );\n            },\n          ),\n        ),\n      ),\n    );\n  }', 'diseño adaptable del gestor', anchor='class _CategoryAttributesManagerPageState')
manager = replace_between(manager, '                  TextFormField(\n                    controller: _keyController,', '                  TextFormField(\n                    controller: _helpController,', '', 'ocultar clave interna')
manager = replace_between(manager, "                  _EditorSwitch(\n                    title: 'Disponible como filtro del catálogo',", "                  _EditorSwitch(\n                    title: 'Puede utilizarse como eje de variante',", '', 'ocultar filtro automático')
manager = replace_between(manager, "                  _EditorSwitch(\n                    title: 'Activo para nuevos productos',", '                  if (!readOnly)\n                    _EditorSwitch(', '', 'retirar activo para nuevos productos')
manager = replace_once(manager, "                  if (!readOnly)\n                    _EditorSwitch(\n                      title: 'Atributo activo',", "                  if (!readOnly && _source != null)\n                    _EditorSwitch(\n                      title: 'Atributo activo',", 'mostrar estado solo al editar')
manager = replace_between(manager, '      case CategoryAttributeDataType.shortText:', '      case CategoryAttributeDataType.number:', '      case CategoryAttributeDataType.shortText:\n        return const SizedBox.shrink();', 'retirar configuración de texto', anchor='  Widget _buildTypeConfiguration(bool readOnly) {')
manager = replace_once(manager, '                        Text(\n                          attribute.keyName,\n                          style: const TextStyle(color: _muted, fontSize: 11),\n                        ),', '', 'ocultar clave en la tabla')
manager = replace_once(manager, '    final source = _source;\n    final attribute = CategoryAttributeDefinition(', "    final keyName = _keyController.text.trim().isEmpty\n        ? _toKey(_nameController.text)\n        : _toKey(_keyController.text);\n    if (keyName.isEmpty || widget.reservedKeys.contains(keyName)) {\n      _showError('Ya existe un atributo con ese identificador interno.');\n      return;\n    }\n\n    final source = _source;\n    final attribute = CategoryAttributeDefinition(", 'generar clave automáticamente')
manager = replace_once(manager, '      keyName: _keyController.text.trim(),', '      keyName: keyName,', 'guardar clave generada')
manager = replace_between(manager, 'class _SectionTitle extends StatelessWidget {', 'class _Notice extends StatelessWidget {', 'class _SectionTitle extends StatelessWidget {\n  const _SectionTitle(this.label);\n\n  final String label;\n\n  @override\n  Widget build(BuildContext context) {\n    return Container(\n      margin: const EdgeInsets.only(top: 22, bottom: 10),\n      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),\n      decoration: BoxDecoration(\n        color: const Color(0xFFFFF8DD),\n        borderRadius: BorderRadius.circular(9),\n        border: const Border(\n          left: BorderSide(color: _yellow, width: 5),\n        ),\n      ),\n      child: Text(\n        label,\n        style: const TextStyle(\n          color: _text,\n          fontSize: 15,\n          fontWeight: FontWeight.w800,\n        ),\n      ),\n    );\n  }\n}', 'títulos de sección amarillos')
integrated = replace_between(integrated, 'class EstructuraCatalogoIntegradaView extends StatelessWidget {', '  static List<design.CatalogCompany> _companies(', "class EstructuraCatalogoIntegradaView extends StatelessWidget {\n  const EstructuraCatalogoIntegradaView({super.key});\n\n  @override\n  Widget build(BuildContext context) =>\n      BlocListener<EstructuraCatalogoBloc, EstructuraCatalogoState>(\n        listenWhen: (previous, current) =>\n            previous.error != current.error ||\n            previous.mensaje != current.mensaje,\n        listener: (context, state) {\n          if (state.error != null) {\n            AppNotice.error(context, state.error!);\n          } else if (state.mensaje != null) {\n            AppNotice.success(context, state.mensaje!);\n          }\n          context.read<EstructuraCatalogoBloc>().add(\n            const MensajeEstructuraConsumido(),\n          );\n        },\n        child: Navigator(\n          onGenerateRoute: (_) => MaterialPageRoute<void>(\n            settings: const RouteSettings(name: 'estructura-catalogo'),\n            builder: (moduleContext) =>\n                BlocBuilder<EstructuraCatalogoBloc, EstructuraCatalogoState>(\n                  builder: (context, state) {\n                    if (state.loading) {\n                      return const Scaffold(\n                        backgroundColor: Color(0xFFF4F6F8),\n                        body: Center(child: CircularProgressIndicator()),\n                      );\n                    }\n                    final snapshot = state.snapshot;\n                    return Scaffold(\n                      backgroundColor: const Color(0xFFF4F6F8),\n                      body: Stack(\n                        children: [\n                          design.CatalogStructurePanel(\n                            key: ValueKey(snapshot),\n                            companies: _companies(snapshot),\n                            brands: _brands(snapshot),\n                            categories: _categories(snapshot),\n                            attributes: _simpleAttributes(snapshot),\n                            relations: _relations(snapshot),\n                            onCompaniesChanged: (items) =>\n                                _saveCompanies(context, snapshot, items),\n                            onBrandsChanged: (items) =>\n                                _saveBrands(context, snapshot, items),\n                            onCategoriesChanged: (items) =>\n                                _saveCategories(context, snapshot, items),\n                            onAttributesChanged: (items) =>\n                                _saveSimpleAttributes(context, snapshot, items),\n                            onRelationsChanged: (items) =>\n                                _saveRelations(context, snapshot, items),\n                            onManageCategoryAttributes: (id) =>\n                                _openAttributeManager(\n                                  moduleContext,\n                                  snapshot,\n                                  int.parse(id),\n                                ),\n                          ),\n                          if (state.saving)\n                            const Positioned(\n                              top: 18,\n                              right: 20,\n                              child: SizedBox.square(\n                                dimension: 22,\n                                child: CircularProgressIndicator(\n                                  strokeWidth: 2.5,\n                                ),\n                              ),\n                            ),\n                        ],\n                      ),\n                    );\n                  },\n                ),\n          ),\n        ),\n      );\n\n", 'navegador interno del módulo')
tests = replace_once(tests, "    expect(find.text('DINA'), findsOneWidget);\n", "    expect(find.text('DINA'), findsOneWidget);\n    expect(\n      find.byKey(const Key('estructura_filtro_empresa')),\n      findsOneWidget,\n    );\n    expect(\n      find.widgetWithText(ChoiceChip, 'DINAFAST'),\n      findsNothing,\n    );\n", 'prueba del dropdown de empresa')
tests = replace_once(tests, "    expect(find.text('Nuevo atributo'), findsOneWidget);\n    expect(find.text('Agregar atributo'), findsNothing);\n    expect(tester.takeException(), isNull);\n", "    expect(find.text('Nuevo atributo'), findsOneWidget);\n    expect(find.text('Agregar atributo'), findsNothing);\n\n    await tester.tap(find.text('Nuevo atributo'));\n    await tester.pumpAndSettle();\n    expect(find.text('Nombre del atributo *'), findsOneWidget);\n    expect(find.text('Clave interna'), findsNothing);\n    expect(\n      find.text('Disponible como filtro del catálogo'),\n      findsNothing,\n    );\n    expect(find.text('Activo para nuevos productos'), findsNothing);\n    expect(find.text('Configuración del texto'), findsNothing);\n    expect(tester.takeException(), isNull);\n", 'prueba del formulario simplificado de atributos')

updates = {
    DESIGN_PATH: design,
    MANAGER_PATH: manager,
    INTEGRATED_PATH: integrated,
    TEST_PATH: tests,
}

for path, content in updates.items():
    if not dart_braces_balanced(content):
        fail(
            f"El resultado de {path.relative_to(ROOT)} tiene delimitadores "
            "desbalanceados."
        )

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_estructura_catalogo_fase1b_diseno_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    destination = backup_dir / path.relative_to(ROOT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, destination)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nDiseño del módulo Estructura del catálogo actualizado.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
