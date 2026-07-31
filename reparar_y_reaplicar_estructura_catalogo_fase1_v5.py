from __future__ import annotations

import ast
from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()

ORIGINAL_SCRIPT = ROOT / "aplicar_estructura_catalogo_fase1_coherencia_v1.py"

RELATIVE_FILES = (
    Path(
        "lib/features/estructura_catalogo/presentation/widgets/"
        "estructura_catalogo_corregida.dart"
    ),
    Path(
        "lib/features/estructura_catalogo/presentation/pages/"
        "estructura_catalogo_integrada.dart"
    ),
    Path("test/estructura_catalogo_page_test.dart"),
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se completó la reparación.")


def latest_valid_backup() -> Path:
    candidates = sorted(
        (
            path
            for path in ROOT.glob(".backup_estructura_catalogo_fase1_*")
            if "_rota_" not in path.name
        ),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    for candidate in candidates:
        if all((candidate / relative).exists() for relative in RELATIVE_FILES):
            return candidate
    fail(
        "No se encontró un respaldo completo "
        ".backup_estructura_catalogo_fase1_*."
    )
    raise AssertionError


def replace_python_function(
    source: str,
    function_name: str,
    replacement: str,
) -> str:
    tree = ast.parse(source)
    nodes = [
        node
        for node in tree.body
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
        and node.name == function_name
    ]
    if len(nodes) != 1:
        fail(
            f"No se encontró exactamente una función Python llamada "
            f"{function_name} en el script de fase 1."
        )

    node = nodes[0]
    lines = source.splitlines(keepends=True)
    start = node.lineno - 1
    end = node.end_lineno
    lines[start:end] = [replacement.rstrip() + "\n\n"]
    return "".join(lines)


ROBUST_REPLACE_BLOCK = 'def _scan_member_span(source: str, marker: str, label: str) -> tuple[int, int]:\n    count = source.count(marker)\n    if count != 1:\n        fail(\n            f"No se pudo localizar “{label}”. "\n            f"Se esperaba 1 marcador y se encontraron {count}."\n        )\n\n    start = source.index(marker)\n\n    if marker.lstrip().startswith("class "):\n        opening = source.find("{", start)\n        if opening < 0:\n            fail(f"No se encontró el cuerpo de “{label}”.")\n        closing = _matching_brace(source, opening)\n        end = closing + 1\n        while end < len(source) and source[end] in " \\t\\r\\n":\n            end += 1\n        return start, end\n\n    opening_paren = source.find("(", start)\n    if opening_paren < 0:\n        fail(f"No se encontró la lista de parámetros de “{label}”.")\n\n    depth = 0\n    index = opening_paren\n    quote: str | None = None\n    triple = False\n    line_comment = False\n    block_comment = 0\n    closing_paren = -1\n\n    while index < len(source):\n        char = source[index]\n        next_char = source[index + 1] if index + 1 < len(source) else ""\n\n        if line_comment:\n            if char == "\\n":\n                line_comment = False\n            index += 1\n            continue\n\n        if block_comment:\n            if char == "/" and next_char == "*":\n                block_comment += 1\n                index += 2\n                continue\n            if char == "*" and next_char == "/":\n                block_comment -= 1\n                index += 2\n                continue\n            index += 1\n            continue\n\n        if quote is not None:\n            if triple:\n                if source.startswith(quote * 3, index):\n                    quote = None\n                    triple = False\n                    index += 3\n                    continue\n                index += 1\n                continue\n\n            if char == "\\\\":\n                index += 2\n                continue\n            if char == quote:\n                quote = None\n            index += 1\n            continue\n\n        if char == "/" and next_char == "/":\n            line_comment = True\n            index += 2\n            continue\n\n        if char == "/" and next_char == "*":\n            block_comment = 1\n            index += 2\n            continue\n\n        if char in ("\'", \'"\'):\n            if source.startswith(char * 3, index):\n                quote = char\n                triple = True\n                index += 3\n            else:\n                quote = char\n                index += 1\n            continue\n\n        if char == "(":\n            depth += 1\n        elif char == ")":\n            depth -= 1\n            if depth == 0:\n                closing_paren = index\n                break\n\n        index += 1\n\n    if closing_paren < 0:\n        fail(f"No se encontró el cierre de parámetros de “{label}”.")\n\n    index = closing_paren + 1\n    while index < len(source) and source[index].isspace():\n        index += 1\n\n    for modifier in ("async*", "sync*", "async", "sync"):\n        if source.startswith(modifier, index):\n            index += len(modifier)\n            while index < len(source) and source[index].isspace():\n                index += 1\n            break\n\n    if source.startswith("=>", index):\n        index += 2\n        paren = bracket = brace = 0\n        quote = None\n        triple = False\n        line_comment = False\n        block_comment = 0\n\n        while index < len(source):\n            char = source[index]\n            next_char = source[index + 1] if index + 1 < len(source) else ""\n\n            if line_comment:\n                if char == "\\n":\n                    line_comment = False\n                index += 1\n                continue\n\n            if block_comment:\n                if char == "/" and next_char == "*":\n                    block_comment += 1\n                    index += 2\n                    continue\n                if char == "*" and next_char == "/":\n                    block_comment -= 1\n                    index += 2\n                    continue\n                index += 1\n                continue\n\n            if quote is not None:\n                if triple:\n                    if source.startswith(quote * 3, index):\n                        quote = None\n                        triple = False\n                        index += 3\n                        continue\n                    index += 1\n                    continue\n\n                if char == "\\\\":\n                    index += 2\n                    continue\n                if char == quote:\n                    quote = None\n                index += 1\n                continue\n\n            if char == "/" and next_char == "/":\n                line_comment = True\n                index += 2\n                continue\n\n            if char == "/" and next_char == "*":\n                block_comment = 1\n                index += 2\n                continue\n\n            if char in ("\'", \'"\'):\n                if source.startswith(char * 3, index):\n                    quote = char\n                    triple = True\n                    index += 3\n                else:\n                    quote = char\n                    index += 1\n                continue\n\n            if char == "(":\n                paren += 1\n            elif char == ")":\n                paren -= 1\n            elif char == "[":\n                bracket += 1\n            elif char == "]":\n                bracket -= 1\n            elif char == "{":\n                brace += 1\n            elif char == "}":\n                brace -= 1\n            elif (\n                char == ";"\n                and paren == 0\n                and bracket == 0\n                and brace == 0\n            ):\n                end = index + 1\n                while end < len(source) and source[end] in " \\t\\r\\n":\n                    end += 1\n                return start, end\n\n            index += 1\n\n        fail(f"No se encontró el final de la expresión “{label}”.")\n\n    if index >= len(source) or source[index] != "{":\n        preview = source[index : index + 40].replace("\\n", "\\\\n")\n        fail(\n            f"No se encontró el cuerpo real de “{label}”. "\n            f"Contenido encontrado: {preview!r}"\n        )\n\n    closing = _matching_brace(source, index)\n    end = closing + 1\n    while end < len(source) and source[end] in " \\t\\r\\n":\n        end += 1\n    return start, end\n\n\ndef replace_block(source: str, marker: str, replacement: str, label: str) -> str:\n    start, end = _scan_member_span(source, marker, label)\n    return source[:start] + replacement.rstrip() + "\\n\\n" + source[end:]'

ROBUST_REMOVE_MEMBER = 'def remove_member(source: str, marker: str, label: str) -> str:\n    start, end = _scan_member_span(source, marker, label)\n    return source[:start] + source[end:]'


if not ORIGINAL_SCRIPT.exists():
    fail(f"No se encontró {ORIGINAL_SCRIPT.name} en la raíz del proyecto.")

backup = latest_valid_backup()

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
broken_backup = ROOT / f".backup_estructura_catalogo_fase1_rota_{timestamp}"

for relative in RELATIVE_FILES:
    current = ROOT / relative
    if current.exists():
        destination = broken_backup / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(current, destination)

for relative in RELATIVE_FILES:
    source = backup / relative
    destination = ROOT / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)

print(f"Restaurado desde: {backup}")
print(f"Estado roto respaldado en: {broken_backup}")

phase_source = ORIGINAL_SCRIPT.read_text(encoding="utf-8")
phase_source = replace_python_function(
    phase_source,
    "replace_block",
    ROBUST_REPLACE_BLOCK,
)
phase_source = replace_python_function(
    phase_source,
    "remove_member",
    ROBUST_REMOVE_MEMBER,
)


def _phase_remove_once(source: str, block: str, label: str) -> str:
    count = source.count(block)
    if count != 1:
        fail(
            f"No se pudo preparar “{label}”. "
            f"Se esperaba 1 bloque y se encontraron {count}."
        )
    return source.replace(block, "", 1)


def _phase_replace_once(
    source: str,
    old: str,
    new: str,
    label: str,
) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo preparar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


_phase_callback_blocks = (
    '''design = replace_once(
    design,
    "    this.onAttributesChanged,\\n",
    "",
    "retirar callback simplificado de atributos",
)
''',
    '''design = replace_once(
    design,
    "  final ValueChanged<List<CategoryAttributeDefinition>>? "
    "onAttributesChanged;\\n",
    "",
    "retirar propiedad simplificada de atributos",
)
''',
    '''integrated = replace_once(
    integrated,
    "                  onAttributesChanged: (items) =>\\n"
    "                      _saveSimpleAttributes(context, snapshot, items),\\n",
    "",
    "retirar guardado simplificado de atributos",
)
''',
)

for _index, _block in enumerate(_phase_callback_blocks, start=1):
    phase_source = _phase_remove_once(
        phase_source,
        _block,
        f"conservar compatibilidad de atributos {_index}",
    )

phase_source = _phase_replace_once(
    phase_source,
    "...effective.map(_buildAttributeCard),",
    "...effective.map(_buildAttributePreviewCard),",
    "usar tarjeta de vista previa",
)

phase_source = _phase_replace_once(
    phase_source,
    "new_attribute_card = r'''  Widget _buildAttributeCard("
    "EffectiveCategoryAttribute item) {",
    "new_attribute_card = r'''  Widget _buildAttributePreviewCard("
    "EffectiveCategoryAttribute item) {",
    "renombrar tarjeta de vista previa",
)

_old_card_operation = '''design = replace_block(
    design,
    "  Widget _buildAttributeCard(EffectiveCategoryAttribute item) {",
    new_attribute_card,
    "tarjeta de atributo de solo lectura",
)
'''

_new_card_operation = '''preview_anchor = (
    "  Widget _buildAttributeManager(CatalogCategory category) {"
)
preview_declaration = (
    "  Widget _buildAttributePreviewCard("
    "EffectiveCategoryAttribute item) {"
)
if preview_declaration in design:
    fail("La tarjeta de vista previa ya existe antes de aplicar la fase.")
if design.count(preview_anchor) != 1:
    fail(
        "No se encontró de forma única dónde insertar la tarjeta "
        "de vista previa de atributos."
    )
design = design.replace(
    preview_anchor,
    new_attribute_card.rstrip() + "\\n\\n" + preview_anchor,
    1,
)
'''

phase_source = _phase_replace_once(
    phase_source,
    _old_card_operation,
    _new_card_operation,
    "insertar tarjeta de vista previa sin depender del editor antiguo",
)

_phase_dead_code_blocks = (
    '''design = remove_member(
    design,
    "  Future<void> _showAttributeForm(",
    "formulario simplificado de atributo",
)
''',
    '''design = remove_member(
    design,
    "  void _toggleAttributeStatus(",
    "cambio simplificado de estado de atributo",
)
''',
    '''design = remove_member(
    design,
    "List<String> _splitValues(",
    "separador usado solo por el formulario simplificado",
)
''',
    '''for marker, label in (
    (
        "  static void _saveSimpleAttributes(",
        "adaptador de guardado simplificado",
    ),
    (
        "  static AtributoCategoriaCatalogo _domainFromSimple(",
        "conversión simplificada de atributo",
    ),
    (
        "  static List<OpcionAtributoCategoriaCatalogo> _optionsFromSimple(",
        "conversión simplificada de opciones",
    ),
    (
        "  static String _domainSimpleType(",
        "conversión simplificada de tipo",
    ),
):
    integrated = remove_member(integrated, marker, label)
''',
)

for _index, _block in enumerate(_phase_dead_code_blocks, start=1):
    phase_source = _phase_remove_once(
        phase_source,
        _block,
        f"conservar código heredado no accesible {_index}",
    )


_form_operations = (
    (
        '''design = replace_block(
    design,
    "  Future<void> _showCompanyForm({CatalogCompany? existing}) async {",
    new_company_form,
    "formulario de empresa",
)
''',
        '''company_form_start_marker = "  Future<void> _showCompanyForm("
company_form_end_marker = "  Future<void> _showBrandForm("
if design.count(company_form_start_marker) != 1:
    fail("No se encontró de forma única el formulario de empresa.")
if design.count(company_form_end_marker) != 1:
    fail("No se encontró de forma única el límite del formulario de empresa.")
company_form_start = design.index(company_form_start_marker)
company_form_end = design.index(company_form_end_marker, company_form_start)
design = (
    design[:company_form_start]
    + new_company_form.rstrip()
    + "\\n\\n"
    + design[company_form_end:]
)
''',
        "reemplazo acotado del formulario de empresa",
    ),
    (
        '''design = replace_block(
    design,
    "  Future<void> _showBrandForm({CatalogBrand? existing}) async {",
    new_brand_form,
    "formulario de marca",
)
''',
        '''brand_form_start_marker = "  Future<void> _showBrandForm("
brand_form_end_marker = "  Future<void> _showCategoryForm("
if design.count(brand_form_start_marker) != 1:
    fail("No se encontró de forma única el formulario de marca.")
if design.count(brand_form_end_marker) != 1:
    fail("No se encontró de forma única el límite del formulario de marca.")
brand_form_start = design.index(brand_form_start_marker)
brand_form_end = design.index(brand_form_end_marker, brand_form_start)
design = (
    design[:brand_form_start]
    + new_brand_form.rstrip()
    + "\\n\\n"
    + design[brand_form_end:]
)
''',
        "reemplazo acotado del formulario de marca",
    ),
    (
        '''design = replace_block(
    design,
    "  Future<void> _showCategoryForm(",
    new_category_form,
    "formulario explícito de categoría y subcategoría",
)
''',
        '''category_form_start_marker = "  Future<void> _showCategoryForm("
category_form_end_marker = "  Future<void> _showAttributeForm("
if design.count(category_form_start_marker) != 1:
    fail("No se encontró de forma única el formulario de categoría.")
if design.count(category_form_end_marker) != 1:
    fail("No se encontró de forma única el límite del formulario de categoría.")
category_form_start = design.index(category_form_start_marker)
category_form_end = design.index(
    category_form_end_marker,
    category_form_start,
)
design = (
    design[:category_form_start]
    + new_category_form.rstrip()
    + "\\n\\n"
    + design[category_form_end:]
)
''',
        "reemplazo acotado del formulario de categoría",
    ),
)

for _old_operation, _new_operation, _operation_label in _form_operations:
    phase_source = _phase_replace_once(
        phase_source,
        _old_operation,
        _new_operation,
        _operation_label,
    )

compile(phase_source, str(ORIGINAL_SCRIPT), "exec")

namespace = {
    "__name__": "__main__",
    "__file__": str(ORIGINAL_SCRIPT),
}
exec(compile(phase_source, str(ORIGINAL_SCRIPT), "exec"), namespace)

print("\nFase 1 restaurada y reaplicada con formularios acotados.")
print(
    "No ejecutes nuevamente "
    "aplicar_estructura_catalogo_fase1_coherencia_v1.py."
)
