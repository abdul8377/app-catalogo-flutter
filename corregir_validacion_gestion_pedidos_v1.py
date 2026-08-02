from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "f0036d14741a218582b045e3938afd3946cff81a"

PAGE_TEST = ROOT / "test/pedidos_page_test.dart"
RESOLVER_TEST = ROOT / "test/producto_pedido_resolver_test.dart"
LOAD_DIALOG = ROOT / (
    "lib/features/pedidos/presentation/dialogs/confirmar_carga_dialog.dart"
)
DETAIL_DIALOG = ROOT / (
    "lib/features/pedidos/presentation/dialogs/pedido_detalle_dialog.dart"
)


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se modificó ningún archivo.")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return source.replace(old, new, 1)


def remove_between(
    source: str,
    start_marker: str,
    end_marker: str,
    label: str,
) -> str:
    starts = source.count(start_marker)
    ends = source.count(end_marker)
    if starts != 1 or ends != 1:
        fail(
            f"No se pudo delimitar “{label}”. "
            f"Inicio: {starts}; fin: {ends}."
        )
    start = source.index(start_marker)
    end = source.index(end_marker, start)
    return source[:start] + source[end:]


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

for path in (PAGE_TEST, RESOLVER_TEST, LOAD_DIALOG, DETAIL_DIALOG):
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

page_test = PAGE_TEST.read_text(encoding="utf-8")
resolver_test = RESOLVER_TEST.read_text(encoding="utf-8")
load_dialog = LOAD_DIALOG.read_text(encoding="utf-8")
detail_dialog = DETAIL_DIALOG.read_text(encoding="utf-8")

# La prueba debe usar el nombre operativo nuevo.
page_test = replace_once(
    page_test,
    """      'Registrar preparación',
""",
    """      'Registrar avance',
""",
    "expectativa del botón del consolidado",
)

# Completar el repositorio falso que usa implements PedidosRepository.
quote_anchor = """  @override
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) async {
"""
quote_methods = """  @override
  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async => null;

  @override
  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) => guardarCotizacion(cotizacion);

"""
page_test = replace_once(
    page_test,
    quote_anchor,
    quote_methods + quote_anchor,
    "métodos de cotización del repositorio falso",
)

cancel_anchor = """  @override
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) async {}

"""
reactivate_method = """  @override
  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) async {}

"""
page_test = replace_once(
    page_test,
    cancel_anchor,
    cancel_anchor + reactivate_method,
    "reactivación del repositorio falso",
)

save_anchor = """  @override
  Future<PedidoRegistrado> guardarPedido({
"""
update_method = """  @override
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async => PedidoRegistrado(
    id: pedidoId,
    codigo: 'PED-2026-0048',
    cliente: cliente.nombre,
    hojaCodigo: 'HP-2026-001',
    estado: 'Pendiente',
  );

"""
page_test = replace_once(
    page_test,
    save_anchor,
    update_method + save_anchor,
    "edición de pedido del repositorio falso",
)

# El import quedó obsoleto después de importar directamente catalogo_form_data.
resolver_test = replace_once(
    resolver_test,
    """import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
""",
    "",
    "import no utilizado del resolver",
)

# La advertencia dejó de mostrarse porque la carga solo admite pedidos completos.
load_dialog = remove_between(
    load_dialog,
    "  Widget _advertencia() => Container(\n",
    "  Widget _contadorPaquetes() => Container(\n",
    "advertencia redundante del modal de carga",
)

# Componente legado reemplazado por botones directos Cerrar / Editar pedido.
detail_dialog = remove_between(
    detail_dialog,
    "class _DialogActionButton extends StatelessWidget {\n",
    "class _InfoCard extends StatelessWidget {\n",
    "botón de diálogo sin uso",
)

updates = {
    PAGE_TEST: page_test,
    RESOLVER_TEST: resolver_test,
    LOAD_DIALOG: load_dialog,
    DETAIL_DIALOG: detail_dialog,
}

required_results = {
    PAGE_TEST: [
        "'Registrar avance'",
        "Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id)",
        "Future<CotizacionPedidoGuardada> actualizarCotizacion({",
        "Future<void> reactivarPedido({",
        "Future<PedidoRegistrado> actualizarPedido({",
    ],
    RESOLVER_TEST: [
        "catalogo_form_data.dart",
        "PresentacionProducto(",
    ],
    LOAD_DIALOG: [
        "Widget _contadorPaquetes()",
    ],
    DETAIL_DIALOG: [
        "class _InfoCard extends StatelessWidget",
    ],
}

for path, markers in required_results.items():
    content = updates[path]
    for marker in markers:
        if marker not in content:
            fail(
                f"El resultado de {path.relative_to(ROOT)} "
                f"no contiene el marcador esperado: {marker}"
            )

for forbidden in (
    "_advertencia()",
    "class _DialogActionButton extends StatelessWidget",
    "nuevo_producto.dart",
):
    if any(forbidden in content for content in updates.values()):
        fail(f"El elemento obsoleto permanece: {forbidden}")

backup_dir = ROOT / (
    ".backup_validacion_gestion_pedidos_v1_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nCorregido el repositorio falso y las advertencias recientes.")
print("No se modificó SQLite ni app_catalogo.db.")
print("\nEjecuta:")
print("  dart format lib test")
print("  flutter test test/pedidos_page_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")
