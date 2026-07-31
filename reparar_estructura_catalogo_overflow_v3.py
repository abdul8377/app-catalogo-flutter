from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

MANAGER_PATH = (
    ROOT
    / "lib/features/estructura_catalogo/presentation/pages/"
    / "gestionar_atributos_categoria.dart"
)
TEST_PATH = ROOT / "test/estructura_catalogo_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


for path in (MANAGER_PATH, TEST_PATH):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

manager = MANAGER_PATH.read_text(encoding="utf-8")
tests = TEST_PATH.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 1. Los dos dropdowns deben ocupar todo el ancho disponible.
# ---------------------------------------------------------------------------

dropdown_types = (
    "CategoryAttributeDataType",
    "AttributeCaptureLevel",
)

for dropdown_type in dropdown_types:
    declaration = f"DropdownButtonFormField<{dropdown_type}>("
    count = manager.count(declaration)
    if count != 1:
        fail(
            f"Se esperaba encontrar un único {declaration} "
            f"y se encontraron {count}."
        )

    start = manager.index(declaration)
    insertion_point = start + len(declaration)

    # No duplicar la propiedad si ya está aplicada.
    nearby = manager[insertion_point : insertion_point + 180]
    if re.search(r"\bisExpanded\s*:\s*true\s*,", nearby):
        continue

    manager = (
        manager[:insertion_point]
        + "\n                    isExpanded: true,"
        + manager[insertion_point:]
    )

# ---------------------------------------------------------------------------
# 2. Las etiquetas de las opciones deben truncarse dentro del dropdown.
# Solo se modifica el bloque de cada selector, no otros menús del archivo.
# ---------------------------------------------------------------------------

def patch_dropdown_item_text(
    source: str,
    dropdown_type: str,
    value_expression: str,
) -> str:
    start_marker = f"DropdownButtonFormField<{dropdown_type}>("
    start = source.index(start_marker)

    # El siguiente DropdownButtonFormField o la siguiente sección limita
    # el ámbito de búsqueda para no alterar otros controles.
    following_positions = [
        pos
        for marker in (
            "DropdownButtonFormField<",
            "const _SectionTitle(",
            "_EditorSwitch(",
        )
        if (pos := source.find(marker, start + len(start_marker))) >= 0
    ]
    end = min(following_positions) if following_positions else len(source)
    block = source[start:end]

    old_pattern = re.compile(
        rf"child:\s*Text\(\s*{re.escape(value_expression)}\s*\)",
        re.MULTILINE,
    )
    matches = list(old_pattern.finditer(block))
    if len(matches) != 1:
        fail(
            f"No se pudo localizar de forma única la etiqueta de "
            f"{dropdown_type}. Coincidencias: {len(matches)}."
        )

    replacement = (
        "child: Text(\n"
        f"                              {value_expression},\n"
        "                              maxLines: 1,\n"
        "                              overflow: TextOverflow.ellipsis,\n"
        "                            )"
    )
    block = old_pattern.sub(replacement, block, count=1)
    return source[:start] + block + source[end:]


manager = patch_dropdown_item_text(
    manager,
    "CategoryAttributeDataType",
    "_dataTypeLabel(type)",
)
manager = patch_dropdown_item_text(
    manager,
    "AttributeCaptureLevel",
    "_captureLevelLabel(level)",
)

# ---------------------------------------------------------------------------
# 3. La prueba debe aceptar las apariciones válidas del nombre:
# árbol, encabezado y panel de detalle.
# ---------------------------------------------------------------------------

test_pattern = re.compile(
    r"expect\(\s*"
    r"find\.text\(\s*['\"]Categoría temporal['\"]\s*\)\s*,\s*"
    r"findsOneWidget\s*,?\s*"
    r"\);",
    re.MULTILINE,
)

test_matches = list(test_pattern.finditer(tests))
if len(test_matches) != 1:
    fail(
        "No se pudo localizar de forma única la expectativa de "
        f"“Categoría temporal”. Coincidencias: {len(test_matches)}."
    )

tests = test_pattern.sub(
    "expect(find.text('Categoría temporal'), findsWidgets);",
    tests,
    count=1,
)

# ---------------------------------------------------------------------------
# Respaldo y escritura.
# ---------------------------------------------------------------------------

updates = {
    MANAGER_PATH: manager,
    TEST_PATH: tests,
}

backup_dir = ROOT / (
    ".backup_estructura_catalogo_overflow_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    backup = backup_dir / path.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, backup)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nDropdowns adaptables y prueba corregida.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/estructura_catalogo_page_test.dart")
print("  flutter analyze")
