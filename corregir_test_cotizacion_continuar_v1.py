from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "f0036d14741a218582b045e3938afd3946cff81a"
TEST = ROOT / "test/pedidos_page_test.dart"


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

if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

old = "find.widgetWithText(ElevatedButton, 'Continuar')"
new = "find.widgetWithText(FilledButton, 'Continuar')"

count = source.count(old)
if count != 2:
    fail(
        "No se encontraron exactamente las dos búsquedas antiguas de "
        f"Continuar. Coincidencias: {count}."
    )

updated = source.replace(old, new)

if updated.count(new) != 2:
    fail("El resultado no contiene las dos búsquedas con FilledButton.")

backup_dir = ROOT / (
    ".backup_test_cotizacion_continuar_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nActualizadas las dos búsquedas de Continuar a FilledButton.")
print("No se modificó código de producción, SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format test/pedidos_page_test.dart")
print("  flutter test test/pedidos_page_test.dart")
print("  flutter analyze")
