from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/producto_detalle_dialog_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

required_markers = [
    "expect(find.textContaining('Filas: Largo'), findsOneWidget);",
    "expect(find.textContaining('Columnas: Diámetro'), findsOneWidget);",
    "sku: 'PER-025X1'",
    "sku: 'PER-038X1'",
    "'assigned_variant_ids': ['var-1', 'var-2']",
    "'default_variant_ids': ['var-1', 'var-2']",
]
for marker in required_markers:
    if marker not in source:
        fail(f"No se encontró el marcador esperado: {marker}")

old_variants = """        variantes: const [
          ProductoVariante(
            id: 'var-1',
            sku: 'PER-025X1',
            codigoProveedor: 'FAB-001',
            nombreCorto: 'Perno 1/4 × 1',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '1',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '1/4',
                unidad: 'in',
              ),
            ],
          ),
          ProductoVariante(
            id: 'var-2',
            sku: 'PER-038X1',
            codigoProveedor: 'FAB-002',
            nombreCorto: 'Perno 3/8 × 1',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '1',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '3/8',
                unidad: 'in',
              ),
            ],
          ),
        ],
"""

new_variants = """        variantes: const [
          ProductoVariante(
            id: 'var-1',
            sku: 'PER-025X1',
            codigoProveedor: 'FAB-001',
            nombreCorto: 'Perno 1/4 × 1',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '1',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '1/4',
                unidad: 'in',
              ),
            ],
          ),
          ProductoVariante(
            id: 'var-2',
            sku: 'PER-038X1',
            codigoProveedor: 'FAB-002',
            nombreCorto: 'Perno 3/8 × 1',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '1',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '3/8',
                unidad: 'in',
              ),
            ],
          ),
          ProductoVariante(
            id: 'var-3',
            sku: 'PER-025X2',
            codigoProveedor: 'FAB-003',
            nombreCorto: 'Perno 1/4 × 2',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '2',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '1/4',
                unidad: 'in',
              ),
            ],
          ),
          ProductoVariante(
            id: 'var-4',
            sku: 'PER-038X2',
            codigoProveedor: 'FAB-004',
            nombreCorto: 'Perno 3/8 × 2',
            atributos: [
              AtributoProductoVariante(
                nombre: 'Largo',
                valor: '2',
                unidad: 'in',
              ),
              AtributoProductoVariante(
                nombre: 'Diámetro',
                valor: '3/8',
                unidad: 'in',
              ),
            ],
          ),
        ],
"""

if source.count(old_variants) != 1:
    fail(
        "La sección de variantes de la prueba no coincide con la versión "
        "esperada."
    )

updated = source.replace(old_variants, new_variants, 1)
updated = updated.replace(
    "'assigned_variant_ids': ['var-1', 'var-2']",
    "'assigned_variant_ids': ['var-1', 'var-2', 'var-3', 'var-4']",
    1,
)
updated = updated.replace(
    "'default_variant_ids': ['var-1', 'var-2']",
    "'default_variant_ids': ['var-1', 'var-2', 'var-3', 'var-4']",
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
print("\nLa prueba ahora usa una matriz real de 2 largos × 2 diámetros.")
print("Ejecuta:")
print("  dart format test/producto_detalle_dialog_test.dart")
print("  flutter test test/producto_detalle_dialog_test.dart")
