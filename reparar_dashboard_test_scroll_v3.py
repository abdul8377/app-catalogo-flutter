from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()
TEST_PATH = ROOT / "test/dashboard_page_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST_PATH.exists():
    fail(f"No se encontró {TEST_PATH.relative_to(ROOT)}")

source = TEST_PATH.read_text(encoding="utf-8")

if "abre el periodo personalizado y los pendientes offline" not in source:
    fail("No se encontró la prueba del periodo personalizado.")

new_scrollable = """scrollable: find.descendant(
        of: find.byKey(const ValueKey('dashboard-body-list')),
        matching: find.byType(Scrollable),
      ),"""

pattern = re.compile(
    r"""scrollable:\s*find\.byKey\(\s*
        const\s+ValueKey\(\s*['"]dashboard-body-list['"]\s*\)\s*
        \)\s*,""",
    re.VERBOSE | re.MULTILINE,
)

matches = list(pattern.finditer(source))
if len(matches) == 0:
    if "matching: find.byType(Scrollable)" in source:
        print(
            "La prueba ya utiliza el Scrollable interno. "
            "No se modificó ningún archivo."
        )
        raise SystemExit(0)
    fail(
        "No se pudo localizar el parámetro scrollable de la prueba. "
        "Se encontraron 0 coincidencias."
    )
if len(matches) != 1:
    fail(
        "Se esperaba una única referencia al ListView del Dashboard y "
        f"se encontraron {len(matches)}."
    )

updated = pattern.sub(new_scrollable, source, count=1)

backup_dir = ROOT / (
    ".backup_dashboard_test_scroll_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST_PATH.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST_PATH, backup_path)

TEST_PATH.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST_PATH.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nPrueba de desplazamiento del Dashboard corregida.")
print("Ejecuta:")
print("  dart format test/dashboard_page_test.dart")
print("  flutter test test/dashboard_page_test.dart")
print("  flutter analyze")
