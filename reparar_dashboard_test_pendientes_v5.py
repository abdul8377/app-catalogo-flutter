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

pattern = re.compile(
    r"""final\s+pendingButton\s*=\s*find\.byKey\(\s*
        const\s+ValueKey\(\s*['"]dashboard-sync-pending['"]\s*\)\s*
        \)\s*;\s*
        await\s+tester\.dragUntilVisible\(\s*
        pendingButton\s*,\s*
        find\.byKey\(\s*
        const\s+ValueKey\(\s*['"]dashboard-body-list['"]\s*\)\s*
        \)\s*,\s*
        const\s+Offset\(\s*0\s*,\s*-300\s*\)\s*,?\s*
        \)\s*;\s*
        await\s+tester\.tap\(\s*pendingButton\s*\)\s*;\s*
        await\s+tester\.pumpAndSettle\(\s*\)\s*;""",
    re.VERBOSE | re.MULTILINE,
)

matches = list(pattern.finditer(source))

if len(matches) == 0:
    if "tester.widget<OutlinedButton>(pendingButton)" in source:
        print(
            "La prueba ya invoca directamente la acción del botón. "
            "No se modificó ningún archivo."
        )
        raise SystemExit(0)
    fail(
        "No se pudo localizar el bloque dragUntilVisible actual. "
        "Se encontraron 0 coincidencias."
    )

if len(matches) != 1:
    fail(
        "Se esperaba un único bloque de interacción con Ver pendientes y "
        f"se encontraron {len(matches)}."
    )

replacement = """final pendingButton = find.byKey(
      const ValueKey('dashboard-sync-pending'),
    );
    expect(pendingButton, findsOneWidget);

    final pendingAction = tester
        .widget<OutlinedButton>(pendingButton)
        .onPressed;
    expect(pendingAction, isNotNull);
    pendingAction!.call();
    await tester.pumpAndSettle();"""

updated = pattern.sub(replacement, source, count=1)

backup_dir = ROOT / (
    ".backup_dashboard_test_pending_action_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST_PATH.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST_PATH, backup_path)

TEST_PATH.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST_PATH.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nInteracción de la prueba cambiada a invocación directa del botón.")
print("Ejecuta:")
print("  dart format test/dashboard_page_test.dart")
print("  flutter test test/dashboard_page_test.dart")
print("  flutter analyze")
