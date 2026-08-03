from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "21517315da055204666ac2c11e0755690e634777"
TARGET = ROOT / (
    "lib/features/catalogo/presentation/widgets/filtros_catalogo.dart"
)


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
        "El repositorio local no está sobre el commit validado. "
        f"Esperado: {EXPECTED_HEAD}; actual: {head}."
    )

if not TARGET.exists():
    fail(f"No se encontró {TARGET.relative_to(ROOT)}")

source = TARGET.read_text(encoding="utf-8")

old_brand = """    if (!_brands(result).contains(result.marca)) {
      result = result.copyWith(clearMarca: true);
    }
"""
new_brand = """    if (result.marca != null &&
        !_brands(result).contains(result.marca)) {
      result = result.copyWith(clearMarca: true);
    }
"""

old_category = """    if (!_categories(result).contains(result.categoria)) {
      result = result.copyWith(
        clearCategoria: true,
        clearSubcategoria: true,
      );
    }
"""
new_category = """    if (result.categoria != null &&
        !_categories(result).contains(result.categoria)) {
      result = result.copyWith(
        clearCategoria: true,
        clearSubcategoria: true,
      );
    }
"""

for old, label in (
    (old_brand, "validación de marca"),
    (old_category, "validación de categoría"),
):
    count = source.count(old)
    if count != 1:
        fail(
            f"No se encontró exactamente una vez “{label}”. "
            f"Coincidencias: {count}."
        )

updated = source.replace(old_brand, new_brand, 1)
updated = updated.replace(old_category, new_category, 1)

for marker in (
    "if (result.marca != null &&",
    "if (result.categoria != null &&",
):
    if marker not in updated:
        fail(f"El resultado no contiene el marcador esperado: {marker}")

backup_dir = ROOT / (
    ".backup_normalizacion_subcategorias_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TARGET.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TARGET, backup_path)

TARGET.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TARGET.relative_to(ROOT)}")
print(f"\nRespaldo: {backup_dir}")
print("\nCorregida la normalización de filtros:")
print("- Una marca vacía ya no se considera inválida.")
print("- Una categoría vacía ya no borra las subcategorías seleccionadas.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib/features/catalogo/presentation/widgets/filtros_catalogo.dart")
print("  flutter test test/filtros_subcategorias_multiple_test.dart")
print("  flutter test test/filtros_catalogo_test.dart")
