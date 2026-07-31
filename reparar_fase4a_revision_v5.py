from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()
PAGE = (
    ROOT
    / "lib/features/catalogo/presentation/pages/producto_form_page.dart"
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not PAGE.exists():
    fail(f"No se encontró {PAGE}")

content = PAGE.read_text(encoding="utf-8")

if "import '../widgets/producto_revision_step.dart';" not in content:
    fail(
        "La página no importa producto_revision_step.dart; "
        "se necesita revisar la estructura antes de reparar."
    )

old_pattern = re.compile(
    r"_PasoEstado\s*\(\s*state\s*:\s*state\s*\)"
)

matches = list(old_pattern.finditer(content))

if not matches:
    if "ProductoRevisionStep(state: state)" in content:
        print("La referencia de revisión ya estaba corregida.")
        raise SystemExit(0)
    fail(
        "No se encontró `_PasoEstado(state: state)` ni la referencia "
        "correcta a `ProductoRevisionStep`."
    )

if len(matches) != 1:
    fail(
        "Se esperaba una referencia a `_PasoEstado`, "
        f"pero se encontraron {len(matches)}."
    )

updated = old_pattern.sub(
    "ProductoRevisionStep(state: state)",
    content,
    count=1,
)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_reparacion_fase4a_revision_{timestamp}"
backup_path = backup_dir / PAGE.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(PAGE, backup_path)

PAGE.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {PAGE.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nReferencia de revisión corregida.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/flujo_producto_coherencia_test.dart")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
