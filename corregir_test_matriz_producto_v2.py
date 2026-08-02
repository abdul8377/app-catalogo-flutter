from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/producto_detalle_dialog_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

required = (
    "la ficha de matriz muestra combinaciones y precios exactos",
    "variantes: const [",
    "presentaciones: const [",
    "sku: 'PER-025X1'",
    "sku: 'PER-038X1'",
    "Filas: Largo",
    "Columnas: Diámetro",
)
for marker in required:
    if marker not in source:
        fail(f"No se encontró el marcador esperado: {marker}")

if "sku: 'PER-025X2'" in source or "sku: 'PER-038X2'" in source:
    fail(
        "La prueba ya contiene las variantes de largo 2. "
        "No se aplicará nuevamente."
    )

variants_pattern = re.compile(
    r"""(?P<indent>^[ \t]*)variantes:\s*const\s*\[
        .*?
        ^(?P=indent)\],\s*
        (?=^[ \t]*presentaciones:\s*const\s*\[)""",
    re.MULTILINE | re.DOTALL | re.VERBOSE,
)

variant_matches = list(variants_pattern.finditer(source))
if len(variant_matches) != 1:
    fail(
        "No se pudo delimitar de forma única la lista de variantes. "
        f"Coincidencias: {len(variant_matches)}."
    )

indent = variant_matches[0].group("indent")
i1 = indent + "  "
i2 = indent + "    "
i3 = indent + "      "
i4 = indent + "        "

new_variants = f"""\
{indent}variantes: const [
{i1}ProductoVariante(
{i2}id: 'var-1',
{i2}sku: 'PER-025X1',
{i2}codigoProveedor: 'FAB-001',
{i2}nombreCorto: 'Perno 1/4 × 1',
{i2}atributos: [
{i3}AtributoProductoVariante(
{i4}nombre: 'Largo',
{i4}valor: '1',
{i4}unidad: 'in',
{i3}),
{i3}AtributoProductoVariante(
{i4}nombre: 'Diámetro',
{i4}valor: '1/4',
{i4}unidad: 'in',
{i3}),
{i2}],
{i1}),
{i1}ProductoVariante(
{i2}id: 'var-2',
{i2}sku: 'PER-038X1',
{i2}codigoProveedor: 'FAB-002',
{i2}nombreCorto: 'Perno 3/8 × 1',
{i2}atributos: [
{i3}AtributoProductoVariante(
{i4}nombre: 'Largo',
{i4}valor: '1',
{i4}unidad: 'in',
{i3}),
{i3}AtributoProductoVariante(
{i4}nombre: 'Diámetro',
{i4}valor: '3/8',
{i4}unidad: 'in',
{i3}),
{i2}],
{i1}),
{i1}ProductoVariante(
{i2}id: 'var-3',
{i2}sku: 'PER-025X2',
{i2}codigoProveedor: 'FAB-003',
{i2}nombreCorto: 'Perno 1/4 × 2',
{i2}atributos: [
{i3}AtributoProductoVariante(
{i4}nombre: 'Largo',
{i4}valor: '2',
{i4}unidad: 'in',
{i3}),
{i3}AtributoProductoVariante(
{i4}nombre: 'Diámetro',
{i4}valor: '1/4',
{i4}unidad: 'in',
{i3}),
{i2}],
{i1}),
{i1}ProductoVariante(
{i2}id: 'var-4',
{i2}sku: 'PER-038X2',
{i2}codigoProveedor: 'FAB-004',
{i2}nombreCorto: 'Perno 3/8 × 2',
{i2}atributos: [
{i3}AtributoProductoVariante(
{i4}nombre: 'Largo',
{i4}valor: '2',
{i4}unidad: 'in',
{i3}),
{i3}AtributoProductoVariante(
{i4}nombre: 'Diámetro',
{i4}valor: '3/8',
{i4}unidad: 'in',
{i3}),
{i2}],
{i1}),
{indent}],
"""

updated = variants_pattern.sub(new_variants, source, count=1)

def replace_id_list(
    text: str,
    field: str,
) -> str:
    pattern = re.compile(
        rf"""(?P<indent>^[ \t]*)'{re.escape(field)}'\s*:\s*\[
            \s*'var-1'\s*,\s*'var-2'\s*,?\s*
            \]""",
        re.MULTILINE | re.DOTALL | re.VERBOSE,
    )
    matches = list(pattern.finditer(text))
    if len(matches) != 1:
        fail(
            f"No se pudo actualizar {field}. "
            f"Coincidencias: {len(matches)}."
        )
    field_indent = matches[0].group("indent")
    replacement = (
        f"{field_indent}'{field}': "
        "['var-1', 'var-2', 'var-3', 'var-4']"
    )
    return pattern.sub(replacement, text, count=1)


updated = replace_id_list(updated, "assigned_variant_ids")
updated = replace_id_list(updated, "default_variant_ids")

# También comprobar que la prueba verificará al menos una variante de cada largo.
expectation_anchor = (
    "expect(find.textContaining('PER-038X1'), findsWidgets);"
)
if expectation_anchor in updated and "PER-025X2" not in updated.split(
    expectation_anchor, 1
)[1]:
    updated = updated.replace(
        expectation_anchor,
        expectation_anchor
        + "\n"
        + "    expect(find.textContaining('PER-025X2'), findsWidgets);\n"
        + "    expect(find.textContaining('PER-038X2'), findsWidgets);",
        1,
    )

backup_dir = ROOT / (
    ".backup_test_matriz_producto_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nLa prueba ahora representa una matriz real de 2 × 2.")
print("Ejecuta:")
print("  dart format test/producto_detalle_dialog_test.dart")
print("  flutter test test/producto_detalle_dialog_test.dart")
