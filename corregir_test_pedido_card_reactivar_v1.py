from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/pedido_card_reactivar_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

old = """      telefono: '999999999',
      direccion: 'Dirección',
      cantidadProductos: 1,
"""
new = """      telefono: '999999999',
      direccion: 'Dirección',
      referencia: '',
      cantidadProductos: 1,
"""

count = source.count(old)
if count != 1:
    fail(
        "No se encontró de forma única el fixture de PedidoResumen. "
        f"Coincidencias: {count}."
    )

updated = source.replace(old, new, 1)

backup_dir = ROOT / (
    ".backup_test_pedido_card_reactivar_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nAñadido el campo obligatorio referencia al fixture.")
print("No se modificó código de producción ni SQLite.")
print("\nEjecuta:")
print("  dart format test/pedido_card_reactivar_test.dart")
print("  flutter test test/pedido_card_reactivar_test.dart")
