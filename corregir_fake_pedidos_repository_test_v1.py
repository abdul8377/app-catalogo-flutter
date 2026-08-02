from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path.cwd()
TEST = ROOT / "test/pedidos_bloc_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


if not TEST.exists():
    fail(f"No se encontró {TEST.relative_to(ROOT)}")

source = TEST.read_text(encoding="utf-8")

anchor = """  @override
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) async => CotizacionPedidoGuardada(
    id: 'cotizacion-1',
    pedidoId: cotizacion.pedidoId,
    codigo: 'COT-2026-0001',
    total: cotizacion.total,
    creadoEn: DateTime(2026),
  );

"""
if source.count(anchor) != 1:
    fail(
        "No se encontró de forma única el método guardarCotizacion "
        f"del repositorio falso. Coincidencias: {source.count(anchor)}."
    )

methods = """  @override
  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async => null;

  @override
  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) => guardarCotizacion(cotizacion);

"""
updated = source.replace(anchor, methods + anchor, 1)

cancel_anchor = """  @override
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) async {}

"""
if updated.count(cancel_anchor) != 1:
    fail(
        "No se encontró de forma única el método cancelarPedido "
        f"del repositorio falso. Coincidencias: {updated.count(cancel_anchor)}."
    )

reactivate = """  @override
  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) async {}

"""
updated = updated.replace(cancel_anchor, cancel_anchor + reactivate, 1)

for marker in (
    "Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id)",
    "Future<CotizacionPedidoGuardada> actualizarCotizacion({",
    "Future<void> reactivarPedido({",
):
    if updated.count(marker) != 1:
        fail(f"El resultado no contiene una sola implementación de: {marker}")

backup_dir = ROOT / (
    ".backup_pedidos_bloc_fake_repository_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_path = backup_dir / TEST.relative_to(ROOT)
backup_path.parent.mkdir(parents=True, exist_ok=False)
shutil.copy2(TEST, backup_path)

TEST.write_text(updated, encoding="utf-8", newline="\n")

print(f"Modificado: {TEST.relative_to(ROOT)}")
print(f"Respaldo: {backup_dir}")
print("\nSe completó únicamente el repositorio falso de la prueba.")
print("No se modificó código de producción, SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format test/pedidos_bloc_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
