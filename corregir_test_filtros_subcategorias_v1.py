from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "21517315da055204666ac2c11e0755690e634777"
TARGET = ROOT / "test/filtros_catalogo_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


try:
    head = subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        text=True,
    ).strip()
except Exception as error:
    fail(f"No se pudo leer el commit actual: {error}")

if head != EXPECTED_HEAD:
    fail(
        "El repositorio local no está en el commit validado. "
        f"Esperado: {EXPECTED_HEAD}; actual: {head}."
    )

if not TARGET.exists():
    fail(f"No se encontró {TARGET.relative_to(ROOT)}")

source = TARGET.read_text(encoding="utf-8")

replacements = [
    (
        "'categoría y subcategoría se gestionan únicamente desde Más filtros'",
        "'categoría y subcategorías se gestionan únicamente desde Más filtros'",
        "nombre de la prueba",
    ),
    (
        "expect(find.text('Subcategoría'), findsWidgets);",
        "expect(find.text('Subcategorías'), findsWidgets);",
        "etiqueta plural del selector",
    ),
]

updated = source
for old, new, label in replacements:
    count = updated.count(old)
    if count != 1:
        fail(
            f"No se pudo corregir “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    updated = updated.replace(old, new, 1)

if updated == source:
    fail("La transformación no produjo cambios.")

for marker in (
    "'categoría y subcategorías se gestionan únicamente desde Más filtros'",
    "expect(find.text('Subcategorías'), findsWidgets);",
):
    if marker not in updated:
        fail(f"El resultado no contiene el marcador esperado: {marker}")

backup_dir = ROOT / (
    ".backup_test_filtros_subcategorias_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TARGET.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TARGET, backup_path)

TARGET.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TARGET.relative_to(ROOT)}")
print(f"\nRespaldo: {backup_dir}")
print("\nSe actualizó la prueba al nombre plural “Subcategorías”.")
print("No se modificó la lógica, SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format test/filtros_catalogo_test.dart")
print("  flutter test test/filtros_catalogo_test.dart")
print("  flutter test test/filtros_subcategorias_multiple_test.dart")
