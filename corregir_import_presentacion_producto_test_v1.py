from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/producto_pedido_resolver_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

anchor = (
    "import 'package:app_catalogo/features/catalogo/domain/entities/"
    "nuevo_producto.dart';\n"
)
new_import = (
    "import 'package:app_catalogo/features/catalogo/domain/entities/"
    "catalogo_form_data.dart';\n"
)

if new_import in source:
    fail("El import de catalogo_form_data.dart ya existe.")

count = source.count(anchor)
if count != 1:
    fail(
        "No se encontró de forma única el import de nuevo_producto.dart. "
        f"Coincidencias: {count}."
    )

updated = source.replace(anchor, new_import + anchor, 1)

backup_dir = ROOT / (
    ".backup_test_producto_pedido_resolver_import_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nAñadido el import directo de catalogo_form_data.dart.")
print("No se modificó código de producción, SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format test/producto_pedido_resolver_test.dart")
print("  flutter test test/producto_pedido_resolver_test.dart")
