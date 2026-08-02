from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/producto_card_layout_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

required = [
    "height: 480,",
    "expect(find.text('+4 más'), findsOneWidget);",
    "la tarjeta compacta resume presentaciones sin desbordar",
]
for marker in required:
    if marker not in source:
        fail(f"No se encontró el marcador esperado: {marker}")

updated = source.replace(
    "la tarjeta compacta resume presentaciones sin desbordar",
    "la tarjeta resume presentaciones sin desbordar en su altura real",
    1,
)
updated = updated.replace(
    "expect(find.text('+4 más'), findsOneWidget);",
    "expect(find.text('+3 más'), findsOneWidget);",
    1,
)

# Garantiza que la prueba siga representando la altura usada por la grilla.
if updated.count("height: 480,") != 1:
    fail("La altura representativa de la tarjeta no aparece una sola vez.")

backup_dir = ROOT / (
    ".backup_test_producto_card_layout_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nLa prueba ahora espera 3 chips visibles y el resumen “+3 más”.")
print("Ejecuta:")
print("  dart format test/producto_card_layout_test.dart")
print("  flutter test test/producto_card_layout_test.dart")
