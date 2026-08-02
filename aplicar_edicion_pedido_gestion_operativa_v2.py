from __future__ import annotations

from datetime import datetime
from pathlib import Path
import json
import shutil
import subprocess

ROOT = Path.cwd()
EXPECTED_HEAD = "f0036d14741a218582b045e3938afd3946cff81a"

DB = ROOT / "lib/core/database/app_database.dart"
PEDIDO = ROOT / "lib/features/pedidos/domain/entities/pedido.dart"
DETALLE = ROOT / "lib/features/pedidos/domain/entities/pedido_detalle.dart"
REPOSITORY = ROOT / "lib/features/pedidos/domain/repositories/pedidos_repository.dart"
REPOSITORY_IMPL = ROOT / "lib/features/pedidos/data/repositories/pedidos_repository_impl.dart"
DATASOURCE = ROOT / "lib/features/pedidos/data/datasources/pedidos_local_datasource.dart"
EVENT = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_event.dart"
STATE = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_state.dart"
BLOC = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_bloc.dart"
NEW_ORDER_PAGE = ROOT / "lib/features/pedidos/presentation/pages/nuevo_pedido_page.dart"
CONFIRM_DIALOG = ROOT / "lib/features/pedidos/presentation/widgets/confirmar_pedido_dialog.dart"
LIST_VIEW = ROOT / "lib/features/pedidos/presentation/views/pedidos_listado_view.dart"
ORDER_CARD = ROOT / "lib/features/pedidos/presentation/widgets/pedido_card.dart"
HEADER = ROOT / "lib/features/pedidos/presentation/widgets/pedidos_header.dart"
CONSOLIDATED_CARD = ROOT / "lib/features/pedidos/presentation/widgets/consolidado_producto_card.dart"
PREP_STATE = ROOT / "lib/features/pedidos/presentation/bloc/preparacion_carga_state.dart"
PREP_VIEW = ROOT / "lib/features/pedidos/presentation/views/preparacion_carga_view.dart"
PREP_CARD = ROOT / "lib/features/pedidos/presentation/widgets/preparacion_pedido_card.dart"
PREP_DIALOG = ROOT / "lib/features/pedidos/presentation/dialogs/registrar_preparacion_dialog.dart"
LOAD_DIALOG = ROOT / "lib/features/pedidos/presentation/dialogs/confirmar_carga_dialog.dart"
TEST = ROOT / "test/pedidos_bloc_test.dart"

PATHS = [
    DB,
    PEDIDO,
    DETALLE,
    REPOSITORY,
    REPOSITORY_IMPL,
    DATASOURCE,
    EVENT,
    STATE,
    BLOC,
    NEW_ORDER_PAGE,
    CONFIRM_DIALOG,
    LIST_VIEW,
    ORDER_CARD,
    HEADER,
    CONSOLIDATED_CARD,
    PREP_STATE,
    PREP_VIEW,
    PREP_CARD,
    PREP_DIALOG,
    LOAD_DIALOG,
    TEST,
]


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


def replace_count(
    source: str,
    old: str,
    new: str,
    expected: int,
    label: str,
) -> str:
    count = source.count(old)
    if count != expected:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaban {expected} coincidencias y se encontraron {count}."
        )
    return source.replace(old, new)


def replace_between(
    source: str,
    start_marker: str,
    end_marker: str,
    replacement: str,
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
    return source[:start] + replacement.rstrip() + "\n\n" + source[end:]


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

for path in PATHS:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

sources = {path: path.read_text(encoding="utf-8") for path in PATHS}

required_markers = {
    DB: [
        "version: 21,",
        "if (oldVersion < 21)",
        "CREATE TABLE IF NOT EXISTS pedido_items(",
    ],
    PEDIDO: ["class PedidoItem extends Equatable", "String get claveCarrito"],
    DETALLE: ["class PedidoDetalleProducto extends Equatable"],
    REPOSITORY: ["Future<PedidoRegistrado> guardarPedido({"],
    REPOSITORY_IMPL: ["Future<PedidoRegistrado> guardarPedido({"],
    DATASOURCE: [
        "Future<PedidoRegistrado> guardarPedido({",
        "PedidoDetalleProducto _pedidoDetalleProductoFromMap(",
        "FROM pedido_items i",
    ],
    EVENT: ["class PedidosStarted extends PedidosEvent"],
    STATE: ["factory PedidosState.initial()", "PedidosState copyWith({"],
    BLOC: ["Future<void> _started(", "Future<void> _confirmar("],
    NEW_ORDER_PAGE: ["class NuevoPedidoPage extends StatelessWidget"],
    CONFIRM_DIALOG: ["'Confirmar pedido'", "'Confirmar pedido',"],
    LIST_VIEW: [
        "La edición de productos se aplicará en la siguiente fase",
        "class PedidosListadoView extends StatefulWidget",
    ],
    ORDER_CARD: ["child: Text('Editar pedido')"],
    HEADER: ["class _SyncPill extends StatelessWidget"],
    CONSOLIDATED_CARD: ["'Registrar preparación'"],
    PREP_STATE: ["int get pedidosCargados"],
    PREP_VIEW: ["PreparacionModoChips(", "class _SubTabs extends StatelessWidget"],
    PREP_CARD: ["label: const Text('Ver productos')"],
    PREP_DIALOG: ["label: const Text('Marcar todos')"],
    LOAD_DIALOG: ["if (widget.pedido.tienePendientes) ...["],
    TEST: ["class _PedidosRepositoryFake implements PedidosRepository"],
}
for path, markers in required_markers.items():
    for marker in markers:
        if marker not in sources[path]:
            fail(
                f"{path.relative_to(ROOT)} no contiene el marcador esperado: "
                f"{marker}"
            )

db = sources[DB]
pedido = sources[PEDIDO]
detalle = sources[DETALLE]
repository = sources[REPOSITORY]
repository_impl = sources[REPOSITORY_IMPL]
datasource = sources[DATASOURCE]
event = sources[EVENT]
state = sources[STATE]
bloc = sources[BLOC]
new_order_page = sources[NEW_ORDER_PAGE]
confirm_dialog = sources[CONFIRM_DIALOG]
list_view = sources[LIST_VIEW]
order_card = sources[ORDER_CARD]
header = sources[HEADER]
consolidated_card = sources[CONSOLIDATED_CARD]
prep_state = sources[PREP_STATE]
prep_view = sources[PREP_VIEW]
prep_card = sources[PREP_CARD]
prep_dialog = sources[PREP_DIALOG]
load_dialog = sources[LOAD_DIALOG]
test = sources[TEST]

# ---------------------------------------------------------------------------
# SQLite v22: identidad completa y desactivación lógica de líneas.
# ---------------------------------------------------------------------------
db = replace_once(db, "version: 21,", "version: 22,", "versión SQLite 22")

upgrade_anchor = """        if (oldVersion < 21) {
          await _migrarValoresTecnicos(db);
        }
"""
upgrade_new = upgrade_anchor + """        if (oldVersion < 22) {
          await _asegurarIdentidadPedidoItems(db);
        }
"""
db = replace_once(
    db,
    upgrade_anchor,
    upgrade_new,
    "migración aditiva de pedido_items",
)

old_table = """    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_items(
      id TEXT PRIMARY KEY, pedido_id TEXT NOT NULL, producto_id TEXT NOT NULL,
      codigo TEXT NOT NULL, nombre TEXT NOT NULL, presentacion TEXT NOT NULL,
      equivalencia TEXT NOT NULL, cantidad INTEGER NOT NULL,
      factor_unidad_base INTEGER NOT NULL DEFAULT 1,
      unidad_base TEXT NOT NULL DEFAULT 'UND',
      precio_unitario REAL, subtotal REAL,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
      FOREIGN KEY(producto_id) REFERENCES productos(id)
    )''');
    await _crearTablasCotizaciones(db);
"""
new_table = """    await db.execute('''CREATE TABLE IF NOT EXISTS pedido_items(
      id TEXT PRIMARY KEY, pedido_id TEXT NOT NULL, producto_id TEXT NOT NULL,
      codigo TEXT NOT NULL, nombre TEXT NOT NULL, presentacion TEXT NOT NULL,
      equivalencia TEXT NOT NULL, cantidad INTEGER NOT NULL,
      factor_unidad_base INTEGER NOT NULL DEFAULT 1,
      unidad_base TEXT NOT NULL DEFAULT 'UND',
      precio_unitario REAL, subtotal REAL,
      activo INTEGER NOT NULL DEFAULT 1,
      variante_id TEXT NOT NULL DEFAULT '',
      variante_sku TEXT NOT NULL DEFAULT '',
      variante_nombre TEXT NOT NULL DEFAULT '',
      atributos_variante_json TEXT NOT NULL DEFAULT '{}',
      presentacion_id TEXT NOT NULL DEFAULT '',
      precio_lista_id TEXT NOT NULL DEFAULT '',
      precio_lista_nombre TEXT NOT NULL DEFAULT '',
      precio_configuracion TEXT NOT NULL DEFAULT 'precio_fijo',
      imagen_path TEXT,
      FOREIGN KEY(pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
      FOREIGN KEY(producto_id) REFERENCES productos(id)
    )''');
    await _asegurarIdentidadPedidoItems(db);
    await _crearTablasCotizaciones(db);
"""
db = replace_once(
    db,
    old_table,
    new_table,
    "estructura enriquecida de pedido_items",
)

identity_method = """  Future<void> _asegurarIdentidadPedidoItems(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(pedido_items)');
    if (info.isEmpty) return;
    final columns = info.map((row) => row['name'] as String).toSet();

    Future<void> addColumn(String name, String sql) async {
      if (!columns.contains(name)) await db.execute(sql);
    }

    await addColumn(
      'activo',
      'ALTER TABLE pedido_items ADD COLUMN activo INTEGER NOT NULL DEFAULT 1',
    );
    await addColumn(
      'variante_id',
      "ALTER TABLE pedido_items ADD COLUMN variante_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'variante_sku',
      "ALTER TABLE pedido_items ADD COLUMN variante_sku TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'variante_nombre',
      "ALTER TABLE pedido_items ADD COLUMN variante_nombre TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'atributos_variante_json',
      "ALTER TABLE pedido_items ADD COLUMN atributos_variante_json TEXT NOT NULL DEFAULT '{}'",
    );
    await addColumn(
      'presentacion_id',
      "ALTER TABLE pedido_items ADD COLUMN presentacion_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_lista_id',
      "ALTER TABLE pedido_items ADD COLUMN precio_lista_id TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_lista_nombre',
      "ALTER TABLE pedido_items ADD COLUMN precio_lista_nombre TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'precio_configuracion',
      "ALTER TABLE pedido_items ADD COLUMN precio_configuracion TEXT NOT NULL DEFAULT 'precio_fijo'",
    );
    await addColumn(
      'imagen_path',
      'ALTER TABLE pedido_items ADD COLUMN imagen_path TEXT',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pedido_items_activos '
      'ON pedido_items(pedido_id, activo)',
    );
  }

"""
db = replace_once(
    db,
    "  Future<void> _crearTablasCotizaciones(Database db) async {",
    identity_method + "  Future<void> _crearTablasCotizaciones(Database db) async {",
    "helper de migración de pedido_items",
)

# ---------------------------------------------------------------------------
# Entidades: conservar ID de línea e identidad comercial.
# ---------------------------------------------------------------------------
pedido = replace_once(
    pedido,
    """class PedidoItem extends Equatable {
  const PedidoItem({
    required this.productoId,
""",
    """class PedidoItem extends Equatable {
  const PedidoItem({
    this.pedidoItemId = '',
    required this.productoId,
""",
    "ID persistente de la línea",
)
pedido = replace_once(
    pedido,
    "  final String productoId;\n",
    "  final String pedidoItemId;\n  final String productoId;\n",
    "campo pedidoItemId",
)
pedido = replace_once(
    pedido,
    """  PedidoItem copyWith({
    String? presentacionId,
""",
    """  PedidoItem copyWith({
    String? pedidoItemId,
    String? presentacionId,
""",
    "copyWith de pedidoItemId",
)
pedido = replace_once(
    pedido,
    """  }) => PedidoItem(
    productoId: productoId,
""",
    """  }) => PedidoItem(
    pedidoItemId: pedidoItemId ?? this.pedidoItemId,
    productoId: productoId,
""",
    "persistencia de pedidoItemId en copyWith",
)
pedido = replace_once(
    pedido,
    """  List<Object?> get props => [
    productoId,
""",
    """  List<Object?> get props => [
    pedidoItemId,
    productoId,
""",
    "equatable de pedidoItemId",
)

detalle = replace_once(
    detalle,
    """    this.marca,
    this.imagenPath,
    this.descuentoCotizado = 0,
""",
    """    this.marca,
    this.imagenPath,
    this.varianteId = '',
    this.varianteSku = '',
    this.varianteNombre = '',
    this.atributosVariante = const {},
    this.presentacionId = '',
    this.precioListaId = '',
    this.precioListaNombre = '',
    this.precioConfiguracion = 'precio_fijo',
    this.precioPedido,
    this.descuentoCotizado = 0,
""",
    "identidad comercial en detalle",
)
detalle = replace_once(
    detalle,
    """  final String? marca;
  final String? imagenPath;
  final double descuentoCotizado;
""",
    """  final String? marca;
  final String? imagenPath;
  final String varianteId;
  final String varianteSku;
  final String varianteNombre;
  final Map<String, String> atributosVariante;
  final String presentacionId;
  final String precioListaId;
  final String precioListaNombre;
  final String precioConfiguracion;
  final double? precioPedido;
  final double descuentoCotizado;
""",
    "campos de identidad comercial",
)
detalle = replace_once(
    detalle,
    """    marca,
    imagenPath,
    descuentoCotizado,
""",
    """    marca,
    imagenPath,
    varianteId,
    varianteSku,
    varianteNombre,
    atributosVariante,
    presentacionId,
    precioListaId,
    precioListaNombre,
    precioConfiguracion,
    precioPedido,
    descuentoCotizado,
""",
    "props de identidad comercial",
)

# ---------------------------------------------------------------------------
# Contrato y repositorio.
# ---------------------------------------------------------------------------
repository = replace_once(
    repository,
    """  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  });
""",
    """  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  });
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) => throw UnimplementedError(
    'Este repositorio no implementa la edición de pedidos.',
  );
""",
    "contrato actualizarPedido",
)

repository_impl = replace_once(
    repository_impl,
    """  @override
  Future<PedidoRegistrado> guardarPedido({
""",
    """  @override
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) => localDatasource.actualizarPedido(
    pedidoId: pedidoId,
    cliente: cliente,
    items: items,
    vendedor: vendedor,
  );

  @override
  Future<PedidoRegistrado> guardarPedido({
""",
    "implementación actualizarPedido",
)

# ---------------------------------------------------------------------------
# Consultas y persistencia.
# ---------------------------------------------------------------------------
datasource = replace_once(
    datasource,
    """            WHERE DATE(p.creado_en, 'localtime') = DATE('now', 'localtime')
              AND LOWER(p.estado) <> 'cancelado'
""",
    """            WHERE i.activo = 1
              AND DATE(p.creado_en, 'localtime') = DATE('now', 'localtime')
              AND LOWER(p.estado) <> 'cancelado'
""",
    "resumen sin precio solo con líneas activas",
)
datasource = replace_once(
    datasource,
    "      LEFT JOIN pedido_items i ON i.pedido_id = p.id\n",
    "      LEFT JOIN pedido_items i ON i.pedido_id = p.id AND i.activo = 1\n",
    "resumen de pedidos con líneas activas",
)
datasource = replace_count(
    datasource,
    "                  WHERE px.pedido_id = p.id\n",
    "                  WHERE px.pedido_id = p.id\n                    AND px.activo = 1\n",
    2,
    "estado de preparación con líneas activas",
)

detail_select_old = """             i.presentacion,
             i.equivalencia,
             i.cantidad,
             COALESCE(ci.precio_cotizacion, i.precio_unitario) AS precio_unitario,
             COALESCE(ci.subtotal, i.subtotal) AS subtotal,
"""
detail_select_new = """             i.presentacion,
             i.equivalencia,
             i.cantidad,
             i.variante_id,
             i.variante_sku,
             i.variante_nombre,
             i.atributos_variante_json,
             i.presentacion_id,
             i.precio_lista_id,
             i.precio_lista_nombre,
             i.precio_configuracion,
             i.precio_unitario AS precio_pedido,
             COALESCE(ci.precio_cotizacion, i.precio_unitario) AS precio_unitario,
             COALESCE(ci.subtotal, i.subtotal) AS subtotal,
"""
datasource = replace_once(
    datasource,
    detail_select_old,
    detail_select_new,
    "identidad en consulta de detalle",
)
datasource = replace_once(
    datasource,
    """             pr.marca,
             pr.imagen_path
      FROM pedido_items i
""",
    """             pr.marca,
             COALESCE(i.imagen_path, pr.imagen_path) AS imagen_path
      FROM pedido_items i
""",
    "imagen persistida de línea",
)
datasource = replace_once(
    datasource,
    """      WHERE i.pedido_id = ?
      ORDER BY i.nombre ASC
""",
    """      WHERE i.pedido_id = ?
        AND i.activo = 1
      ORDER BY i.nombre ASC
""",
    "detalle solo con líneas activas",
)
datasource = replace_once(
    datasource,
    "'SELECT COUNT(*) FROM pedido_items WHERE pedido_id = ?',",
    "'SELECT COUNT(*) FROM pedido_items WHERE pedido_id = ? AND activo = 1',",
    "validación de cotización con líneas activas",
)
datasource = replace_once(
    datasource,
    """        WHERE LOWER(p.estado) <> 'cancelado'
          ${soloHojaActiva ? "AND h.activa = 1 AND h.estado = 'Abierta'" : ''}
""",
    """        WHERE i.activo = 1
          AND LOWER(p.estado) <> 'cancelado'
          ${soloHojaActiva ? "AND h.activa = 1 AND h.estado = 'Abierta'" : ''}
""",
    "preparación solo con líneas activas",
)
datasource = replace_count(
    datasource,
    """      WHERE i.pedido_id = ?
      GROUP BY i.id
""",
    """      WHERE i.pedido_id = ?
        AND i.activo = 1
      GROUP BY i.id
""",
    2,
    "consultas operativas internas por pedido activo",
)
datasource = replace_once(
    datasource,
    """        WHERE i.pedido_id = ?
        GROUP BY i.id
""",
    """        WHERE i.pedido_id = ?
          AND i.activo = 1
        GROUP BY i.id
""",
    "consulta de carga por pedido activo",
)
datasource = replace_once(
    datasource,
    """        WHERE i.pedido_id = ?
          AND i.producto_id = ?
""",
    """        WHERE i.pedido_id = ?
          AND i.producto_id = ?
          AND i.activo = 1
""",
    "validación completa con líneas activas",
)
datasource = replace_once(
    datasource,
    """          WHERE i.id = ?
            AND h.activa = 1
""",
    """          WHERE i.id = ?
            AND i.activo = 1
            AND h.activa = 1
""",
    "registro de preparación sobre línea activa",
)

# Guardado nuevo con identidad.
insert_old = """        await txn.insert('pedido_items', {
          'id': const Uuid().v4(),
          'pedido_id': pedidoId,
          'producto_id': item.productoId,
          'codigo': item.codigo,
          'nombre': item.nombre,
          'presentacion': item.presentacion,
          'equivalencia': item.equivalencia,
          'cantidad': item.cantidad,
          'factor_unidad_base': _factorUnidadBase(
            item.presentacion,
            item.equivalencia,
          ),
          'unidad_base': _unidadBase(item.presentacion, item.equivalencia),
          'precio_unitario': item.precioUnitario,
          'subtotal': item.subtotal,
        });
"""
insert_new = """        await txn.insert(
          'pedido_items',
          _pedidoItemValues(
            item,
            pedidoId: pedidoId,
            itemId: const Uuid().v4(),
          ),
        );
"""
datasource = replace_once(
    datasource,
    insert_old,
    insert_new,
    "guardado enriquecido de nuevas líneas",
)

update_method = """  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async {
    if (items.isEmpty) throw StateError('El carrito está vacío.');
    final db = await _db;
    return db.transaction((txn) async {
      final pedidos = await txn.rawQuery(
        '''
        SELECT p.id, p.codigo, p.estado, p.vendedor, p.hoja_id,
               h.codigo AS hoja_codigo
        FROM pedidos p
        INNER JOIN hojas_pedido h ON h.id = p.hoja_id
        WHERE p.id = ?
        LIMIT 1
        ''',
        [pedidoId],
      );
      if (pedidos.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final pedido = pedidos.first;
      final estadoAnterior = _normalizarEstadoPedido(
        pedido['estado'] as String? ?? '',
      );
      if (estadoAnterior == 'cancelado') {
        throw StateError('Reactiva el pedido antes de editarlo.');
      }
      if (estadoAnterior == 'entregado') {
        throw StateError('Un pedido entregado no puede modificarse.');
      }

      final clienteId = await _obtenerOCrearCliente(txn, cliente);
      final existingRows = await txn.query(
        'pedido_items',
        columns: ['id'],
        where: 'pedido_id = ? AND activo = 1',
        whereArgs: [pedidoId],
      );
      final existingIds = existingRows
          .map((row) => row['id'] as String)
          .toSet();
      final incomingExistingIds = items
          .map((item) => item.pedidoItemId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!existingIds.containsAll(incomingExistingIds)) {
        throw StateError(
          'Una de las líneas editadas ya no pertenece a este pedido.',
        );
      }

      await txn.delete(
        'preparacion_productos',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );
      await txn.delete(
        'pedido_cargas',
        where: 'pedido_id = ?',
        whereArgs: [pedidoId],
      );

      final now = DateTime.now().toIso8601String();
      await txn.update(
        'cotizaciones',
        {'estado': 'Archivada', 'actualizado_en': now},
        where:
            "pedido_id = ? AND LOWER(estado) IN ('generada', 'borrador')",
        whereArgs: [pedidoId],
      );

      await txn.update(
        'pedido_items',
        {'activo': 0},
        where: 'pedido_id = ? AND activo = 1',
        whereArgs: [pedidoId],
      );

      var agregadas = 0;
      var actualizadas = 0;
      for (final item in items) {
        final storedId = item.pedidoItemId.trim();
        if (storedId.isNotEmpty && existingIds.contains(storedId)) {
          final count = await txn.update(
            'pedido_items',
            _pedidoItemValues(
              item,
              pedidoId: pedidoId,
              itemId: storedId,
            ),
            where: 'id = ? AND pedido_id = ?',
            whereArgs: [storedId, pedidoId],
          );
          if (count != 1) {
            throw StateError('No se pudo actualizar una línea del pedido.');
          }
          actualizadas++;
        } else {
          await txn.insert(
            'pedido_items',
            _pedidoItemValues(
              item,
              pedidoId: pedidoId,
              itemId: const Uuid().v4(),
            ),
          );
          agregadas++;
        }
      }

      final subtotal = items.fold<double>(
        0,
        (total, item) => total + (item.subtotal ?? 0),
      );
      final parcial = items.any((item) => item.precioUnitario == null);
      await txn.update(
        'pedidos',
        {
          'cliente_id': clienteId,
          'vendedor': vendedor,
          'estado': 'Pendiente',
          'subtotal_conocido': subtotal,
          'total_parcial': parcial ? 1 : 0,
          'sincronizado': 0,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );

      final removed = existingIds.difference(incomingExistingIds).length;
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Pedido editado • estado Pendiente',
        observacion:
            '$actualizadas líneas actualizadas · $agregadas agregadas · '
            '$removed retiradas. Se reinició preparación y carga; '
            'las cotizaciones anteriores quedaron archivadas.',
        responsable: vendedor,
        creadoEn: now,
      );

      return PedidoRegistrado(
        id: pedidoId,
        codigo: pedido['codigo'] as String,
        cliente: cliente.nombre,
        hojaCodigo: pedido['hoja_codigo'] as String? ?? '',
        estado: 'Pendiente',
      );
    });
  }

"""
datasource = replace_once(
    datasource,
    "  Future<PedidoRegistrado> guardarPedido({",
    update_method + "  Future<PedidoRegistrado> guardarPedido({",
    "actualización transaccional del pedido",
)

item_values = """  Map<String, Object?> _pedidoItemValues(
    PedidoItem item, {
    required String pedidoId,
    required String itemId,
  }) {
    final selected = item.opcionSeleccionada;
    final factor = selected == null
        ? _factorUnidadBase(item.presentacion, item.equivalencia)
        : selected.equivalenteA.round().clamp(1, 1000000000);
    final unidad = selected?.unidadBase.trim().isNotEmpty == true
        ? selected!.unidadBase
        : _unidadBase(item.presentacion, item.equivalencia);
    return {
      'id': itemId,
      'pedido_id': pedidoId,
      'producto_id': item.productoId,
      'codigo': item.codigo,
      'nombre': item.nombre,
      'presentacion': item.presentacion,
      'equivalencia': item.equivalencia,
      'cantidad': item.cantidad,
      'factor_unidad_base': factor,
      'unidad_base': unidad,
      'precio_unitario': item.precioUnitario,
      'subtotal': item.subtotal,
      'activo': 1,
      'variante_id': item.varianteId,
      'variante_sku': item.varianteSku,
      'variante_nombre': item.varianteNombre,
      'atributos_variante_json': jsonEncode(item.atributosVariante),
      'presentacion_id': item.presentacionId,
      'precio_lista_id': item.precioListaId,
      'precio_lista_nombre': item.precioListaNombre,
      'precio_configuracion': item.precioConfiguracion,
      'imagen_path': item.imagenPath,
    };
  }

"""
datasource = replace_once(
    datasource,
    "  Future<String> _obtenerOCrearCliente(\n",
    item_values + "  Future<String> _obtenerOCrearCliente(\n",
    "mapeo central de pedido_items",
)

mapping_old = """    precioUnitario: (row['precio_unitario'] as num?)?.toDouble(),
    subtotal: (row['subtotal'] as num?)?.toDouble(),
    marca: row['marca'] as String?,
    imagenPath: row['imagen_path'] as String?,
    descuentoCotizado: (row['descuento_cotizado'] as num? ?? 0).toDouble(),
"""
mapping_new = """    precioUnitario: (row['precio_unitario'] as num?)?.toDouble(),
    subtotal: (row['subtotal'] as num?)?.toDouble(),
    marca: row['marca'] as String?,
    imagenPath: row['imagen_path'] as String?,
    varianteId: row['variante_id'] as String? ?? '',
    varianteSku: row['variante_sku'] as String? ?? '',
    varianteNombre: row['variante_nombre'] as String? ?? '',
    atributosVariante: _stringMapFromJson(
      row['atributos_variante_json'] as String?,
    ),
    presentacionId: row['presentacion_id'] as String? ?? '',
    precioListaId: row['precio_lista_id'] as String? ?? '',
    precioListaNombre: row['precio_lista_nombre'] as String? ?? '',
    precioConfiguracion:
        row['precio_configuracion'] as String? ?? 'precio_fijo',
    precioPedido: (row['precio_pedido'] as num?)?.toDouble(),
    descuentoCotizado: (row['descuento_cotizado'] as num? ?? 0).toDouble(),
"""
datasource = replace_once(
    datasource,
    mapping_old,
    mapping_new,
    "mapeo de identidad al detalle",
)

map_helper = """  Map<String, String> _stringMapFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): entry.value.toString(),
      };
    } catch (_) {
      return const {};
    }
  }

"""
datasource = replace_once(
    datasource,
    "  String _varianteFromJson(String? raw) {\n",
    map_helper + "  String _varianteFromJson(String? raw) {\n",
    "lector de atributos de variante",
)

# ---------------------------------------------------------------------------
# Evento, estado y BLoC en modo edición.
# ---------------------------------------------------------------------------
event = replace_once(
    event,
    """class PedidosStarted extends PedidosEvent {
  const PedidosStarted();
}
""",
    """class PedidosStarted extends PedidosEvent {
  const PedidosStarted({this.pedidoId});

  final String? pedidoId;

  @override
  List<Object?> get props => [pedidoId];
}
""",
    "inicio opcional en modo edición",
)

state = replace_once(
    state,
    """    this.imagen,
    this.filtrosRapidos = const {'Todos'},
""",
    """    this.imagen,
    this.pedidoIdEditando,
    this.pedidoCodigoEditando,
    this.pedidoEstadoOriginal,
    this.pedidoHojaEditando,
    this.filtrosRapidos = const {'Todos'},
""",
    "metadatos de edición en estado",
)
state = replace_once(
    state,
    """  final String? imagen;
  final Set<String> filtrosRapidos;
""",
    """  final String? imagen;
  final String? pedidoIdEditando;
  final String? pedidoCodigoEditando;
  final String? pedidoEstadoOriginal;
  final String? pedidoHojaEditando;
  final Set<String> filtrosRapidos;
""",
    "campos de edición",
)
state = replace_once(
    state,
    """  int get lineasCarrito => carrito.length;
""",
    """  bool get modoEdicion =>
      pedidoIdEditando != null && pedidoIdEditando!.trim().isNotEmpty;
  int get lineasLegadas => carrito
      .where(
        (item) =>
            item.pedidoItemId.isNotEmpty &&
            item.varianteId.isEmpty &&
            item.presentacionId.isEmpty,
      )
      .length;

  int get lineasCarrito => carrito.length;
""",
    "getters de edición",
)
state = replace_once(
    state,
    """    String? imagen,
    Set<String>? filtrosRapidos,
""",
    """    String? imagen,
    String? pedidoIdEditando,
    String? pedidoCodigoEditando,
    String? pedidoEstadoOriginal,
    String? pedidoHojaEditando,
    Set<String>? filtrosRapidos,
""",
    "copyWith de edición",
)
state = replace_once(
    state,
    """    imagen: limpiarFiltros ? null : imagen ?? this.imagen,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
""",
    """    imagen: limpiarFiltros ? null : imagen ?? this.imagen,
    pedidoIdEditando: pedidoIdEditando ?? this.pedidoIdEditando,
    pedidoCodigoEditando: pedidoCodigoEditando ?? this.pedidoCodigoEditando,
    pedidoEstadoOriginal:
        pedidoEstadoOriginal ?? this.pedidoEstadoOriginal,
    pedidoHojaEditando: pedidoHojaEditando ?? this.pedidoHojaEditando,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
""",
    "construcción de copyWith de edición",
)
state = replace_once(
    state,
    """    imagen,
    filtrosRapidos,
""",
    """    imagen,
    pedidoIdEditando,
    pedidoCodigoEditando,
    pedidoEstadoOriginal,
    pedidoHojaEditando,
    filtrosRapidos,
""",
    "props de edición",
)

bloc = replace_once(
    bloc,
    "import '../../domain/repositories/pedidos_repository.dart';\n",
    """import '../../domain/entities/pedido.dart';
import '../../domain/entities/pedido_detalle.dart';
import '../../domain/repositories/pedidos_repository.dart';
import '../../domain/services/producto_pedido_resolver.dart';
""",
    "imports del editor de pedidos",
)

started_method = """  Future<void> _started(
    PedidosStarted event,
    Emitter<PedidosState> emit,
  ) async {
    emit(state.copyWith(loading: true, limpiarError: true));
    try {
      final results = await Future.wait<Object?>([
        _catalogoRepository.obtenerProductos(),
        _pedidosRepository.obtenerHojaActiva(),
        _pedidosRepository.buscarClientes(''),
        event.pedidoId == null
            ? Future<PedidoDetalle?>.value(null)
            : _pedidosRepository.obtenerPedidoDetalle(event.pedidoId!),
      ]);
      final detalle = results[3] as PedidoDetalle?;
      if (event.pedidoId != null && detalle == null) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      if (detalle?.estadoNormalizado == 'cancelado') {
        throw StateError('Reactiva el pedido antes de editarlo.');
      }
      if (detalle?.estadoNormalizado == 'entregado') {
        throw StateError('Un pedido entregado no puede modificarse.');
      }

      final carrito = detalle == null
          ? const <PedidoItem>[]
          : await Future.wait(
              detalle.productos.map(_reconstruirItemEdicion),
            );
      final cliente = detalle == null
          ? null
          : ClientePedido(
              id: detalle.clienteId,
              nombre: detalle.clienteNombre,
              telefono: detalle.telefono,
              dni: detalle.clienteDni,
              ruc: detalle.clienteRuc,
              direccion: detalle.direccion,
              referencia: detalle.referencia,
              fotoUbicacionPath: detalle.fotoUbicacionPath,
              observaciones: detalle.observacionesEntrega,
            );

      emit(
        state.copyWith(
          loading: false,
          productos: results[0] as dynamic,
          hojaActiva: results[1] as dynamic,
          limpiarHoja: results[1] == null,
          clientes: results[2] as dynamic,
          carrito: carrito,
          cliente: cliente,
          pedidoIdEditando: detalle?.id,
          pedidoCodigoEditando: detalle?.codigo,
          pedidoEstadoOriginal: detalle?.estadoLabel,
          pedidoHojaEditando: detalle?.hoja,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          error: error is StateError
              ? error.message.toString()
              : 'No se pudo cargar el módulo de pedidos.',
        ),
      );
    }
  }

  Future<PedidoItem> _reconstruirItemEdicion(
    PedidoDetalleProducto producto,
  ) async {
    var opciones = const <PresentacionPedidoOpcion>[];
    double? precio = producto.precioPedido ?? producto.precioUnitario;

    if (producto.varianteId.isNotEmpty) {
      final catalogo = await _catalogoRepository.obtenerDetalleProducto(
        producto.productoId,
      );
      if (catalogo != null) {
        final resolved = ProductoPedidoResolver.resolver(catalogo);
        final variante = resolved.variantes
            .where((item) => item.id == producto.varianteId)
            .firstOrNull;
        if (variante != null) {
          final listId = producto.precioListaId.isEmpty
              ? resolved.listaPredeterminada.id
              : producto.precioListaId;
          final list = resolved.listas
              .where((item) => item.id == listId)
              .firstOrNull;
          opciones = variante.presentaciones.map((presentacion) {
            final price = presentacion.precioParaLista(listId);
            return PresentacionPedidoOpcion(
              id: presentacion.id,
              nombre: presentacion.nombre,
              equivalencia: presentacion.equivalenciaTexto,
              equivalenteA: presentacion.equivalencia,
              unidadBase: presentacion.unidadBase,
              pedidoMinimo: presentacion.pedidoMinimo,
              incremento: presentacion.incremento,
              listaPrecioId: listId,
              listaPrecioNombre:
                  producto.precioListaNombre.isNotEmpty
                  ? producto.precioListaNombre
                  : list?.nombre ?? '',
              configuracionPrecio:
                  price?.configuracion ?? producto.precioConfiguracion,
              precio: price?.precioFijo,
              rangos: price?.rangos ?? const [],
            );
          }).toList();
          final selected = opciones
              .where(
                (item) =>
                    (producto.presentacionId.isNotEmpty &&
                        item.id == producto.presentacionId) ||
                    item.nombre == producto.presentacion,
              )
              .firstOrNull;
          if (selected != null) {
            precio = selected.precioPara(producto.cantidad);
          }
        }
      }
    }

    return PedidoItem(
      pedidoItemId: producto.id,
      productoId: producto.productoId,
      codigo: producto.codigo,
      nombre: producto.nombre,
      varianteId: producto.varianteId,
      varianteSku: producto.varianteSku,
      varianteNombre: producto.varianteNombre,
      atributosVariante: producto.atributosVariante,
      presentacionId: producto.presentacionId,
      presentacion: producto.presentacion,
      equivalencia: producto.equivalencia,
      cantidad: producto.cantidad,
      precioUnitario: precio,
      precioListaId: producto.precioListaId,
      precioListaNombre: producto.precioListaNombre,
      precioConfiguracion: producto.precioConfiguracion,
      opciones: opciones,
      imagenPath: producto.imagenPath,
    );
  }"""
bloc = replace_between(
    bloc,
    "  Future<void> _started(\n",
    "  void _agregarProducto(\n",
    started_method,
    "carga del pedido existente",
)

confirm_method = """  Future<void> _confirmar(
    PedidoConfirmado event,
    Emitter<PedidosState> emit,
  ) async {
    if (state.carrito.isEmpty) {
      emit(state.copyWith(error: 'Agrega al menos un producto.'));
      return;
    }
    final cliente = state.cliente;
    if (cliente == null || cliente.nombre.trim().isEmpty) {
      emit(state.copyWith(error: 'Selecciona o registra un cliente.'));
      return;
    }
    final digits = cliente.telefono.replaceAll(RegExp(r'\\D'), '');
    if (digits.length < 7) {
      emit(state.copyWith(error: 'Ingresa un teléfono válido.'));
      return;
    }
    if (cliente.direccion.trim().isEmpty) {
      emit(state.copyWith(error: 'La dirección del cliente es obligatoria.'));
      return;
    }
    emit(state.copyWith(guardando: true, limpiarError: true));
    try {
      late final PedidoRegistrado result;
      if (state.modoEdicion) {
        result = await _pedidosRepository.actualizarPedido(
          pedidoId: state.pedidoIdEditando!,
          cliente: cliente,
          items: state.carrito,
          vendedor: 'Alfonzo Esteban',
        );
      } else {
        final hojaActiva = await _pedidosRepository.obtenerHojaActiva();
        if (hojaActiva == null) {
          emit(
            state.copyWith(
              guardando: false,
              limpiarHoja: true,
              error: 'No existe una hoja de pedido activa.',
            ),
          );
          return;
        }
        result = await _pedidosRepository.guardarPedido(
          hoja: hojaActiva,
          cliente: cliente,
          items: state.carrito,
          vendedor: 'Alfonzo Esteban',
        );
      }
      emit(
        state.copyWith(
          guardando: false,
          carrito: const [],
          limpiarCliente: true,
          resultado: result,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          guardando: false,
          error: error is StateError
              ? error.message.toString()
              : state.modoEdicion
              ? 'No se pudo actualizar el pedido.'
              : 'No se pudo registrar el pedido.',
        ),
      );
    }
  }"""
bloc = replace_between(
    bloc,
    "  Future<void> _confirmar(\n",
    "  Future<void> _crearHoja(\n",
    confirm_method,
    "confirmación diferenciada",
)

# ---------------------------------------------------------------------------
# Nuevo pedido en modo edición.
# ---------------------------------------------------------------------------
new_order_page = replace_once(
    new_order_page,
    """class NuevoPedidoPage extends StatelessWidget {
  const NuevoPedidoPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
""",
    """class NuevoPedidoPage extends StatelessWidget {
  const NuevoPedidoPage({this.pedidoId, super.key});

  final String? pedidoId;

  @override
  Widget build(BuildContext context) => BlocProvider(
""",
    "parámetro pedidoId en página",
)
new_order_page = replace_once(
    new_order_page,
    """    )..add(const PedidosStarted()),
""",
    """    )..add(PedidosStarted(pedidoId: pedidoId)),
""",
    "inicio de edición",
)
new_order_page = replace_once(
    new_order_page,
    """              'Nuevo pedido',
""",
    """              state.modoEdicion ? 'Editar pedido' : 'Nuevo pedido',
""",
    "título contextual",
)
new_order_page = replace_once(
    new_order_page,
    """              state.hojaActiva == null
                  ? 'Sin hoja activa'
                  : 'Hoja activa: ${state.hojaActiva!.codigo}',
""",
    """              state.modoEdicion
                  ? '${state.pedidoCodigoEditando ?? ''} · '
                        'Hoja ${state.pedidoHojaEditando ?? ''}'
                  : state.hojaActiva == null
                  ? 'Sin hoja activa'
                  : 'Hoja activa: ${state.hojaActiva!.codigo}',
""",
    "subtítulo contextual",
)
new_order_page = replace_once(
    new_order_page,
    """                if (state.hojaActiva == null) const _SinHojaBanner(),
                FiltrosCatalogo(
""",
    """                if (state.modoEdicion) _EdicionPedidoBanner(state: state),
                if (!state.modoEdicion && state.hojaActiva == null)
                  const _SinHojaBanner(),
                FiltrosCatalogo(
""",
    "banner de edición",
)
new_order_page = replace_once(
    new_order_page,
    """    final confirmado = await ConfirmarPedidoDialog.show(context);
    if (!confirmado || !context.mounted) return;
    final resultado = context.read<PedidosBloc>().state.resultado;
    if (resultado != null) await _mostrarResultado(context, resultado);
""",
    """    final confirmado = await ConfirmarPedidoDialog.show(context);
    if (!confirmado || !context.mounted) return;
    final state = context.read<PedidosBloc>().state;
    final resultado = state.resultado;
    if (resultado == null) return;
    await _mostrarResultado(
      context,
      resultado,
      modoEdicion: state.modoEdicion,
    );
    if (state.modoEdicion && context.mounted) {
      Navigator.of(context).pop(true);
    }
""",
    "retorno de edición a Gestión",
)
new_order_page = replace_once(
    new_order_page,
    """  Future<void> _mostrarResultado(
    BuildContext context,
    PedidoRegistrado resultado,
  ) => showDialog<void>(
""",
    """  Future<void> _mostrarResultado(
    BuildContext context,
    PedidoRegistrado resultado, {
    required bool modoEdicion,
  }) => showDialog<void>(
""",
    "resultado contextual",
)
new_order_page = replace_once(
    new_order_page,
    """                      'Pedido registrado',
""",
    """                      modoEdicion ? 'Pedido actualizado' : 'Pedido registrado',
""",
    "título del resultado",
)
new_order_page = replace_once(
    new_order_page,
    """                      'Quedó guardado localmente en la hoja activa.',
""",
    """                      modoEdicion
                          ? 'Se conservaron el código, la hoja y el historial. '
                                'El pedido volvió a Pendiente.'
                          : 'Quedó guardado localmente en la hoja activa.',
""",
    "mensaje del resultado",
)

result_buttons_old = """                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cerrar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              context.read<PedidosBloc>().add(
                                const PedidoNuevoSolicitado(),
                              );
                              Navigator.pop(dialogContext);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 46),
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('Nuevo pedido'),
                          ),
                        ),
                      ],
                    ),
"""
result_buttons_new = """                    if (modoEdicion)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(0, 46),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Volver a Gestión de pedidos'),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cerrar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                context.read<PedidosBloc>().add(
                                  const PedidoNuevoSolicitado(),
                                );
                                Navigator.pop(dialogContext);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(0, 46),
                              ),
                              icon: const Icon(Icons.add_shopping_cart_rounded),
                              label: const Text('Nuevo pedido'),
                            ),
                          ),
                        ],
                      ),
"""
new_order_page = replace_once(
    new_order_page,
    result_buttons_old,
    result_buttons_new,
    "acciones del resultado de edición",
)
new_order_page = replace_once(
    new_order_page,
    """            label: const Text('Revisar'),
""",
    """            label: Text(state.modoEdicion ? 'Revisar cambios' : 'Revisar'),
""",
    "botón revisar cambios",
)

edit_banner = """class _EdicionPedidoBanner extends StatelessWidget {
  const _EdicionPedidoBanner({required this.state});

  final PedidosState state;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    color: const Color(0xFFFFF8DB),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.edit_note_rounded, color: Color(0xFF8A6500)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            state.lineasLegadas > 0
                ? 'Editando ${state.pedidoCodigoEditando}. '
                      '${state.lineasLegadas} línea(s) antigua(s) no conservan '
                      'la variante exacta; puedes cambiar su cantidad o '
                      'retirarlas y agregarlas nuevamente.'
                : 'Editando ${state.pedidoCodigoEditando}. Al guardar se '
                      'reiniciarán preparación y carga, y las cotizaciones '
                      'anteriores quedarán archivadas.',
            style: GoogleFonts.inter(
              color: const Color(0xFF5D4600),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

"""
new_order_page = replace_once(
    new_order_page,
    "class _CarritoBar extends StatelessWidget {\n",
    edit_banner + "class _CarritoBar extends StatelessWidget {\n",
    "componente de aviso de edición",
)

# Confirmar pedido contextual.
confirm_dialog = replace_once(
    confirm_dialog,
    "                  _header(context),\n",
    "                  _header(context, state),\n",
    "estado en encabezado de confirmación",
)
confirm_dialog = replace_once(
    confirm_dialog,
    "  Widget _header(BuildContext context) => Container(\n",
    "  Widget _header(BuildContext context, PedidosState state) => Container(\n",
    "firma del encabezado",
)
confirm_dialog = replace_once(
    confirm_dialog,
    """                'Confirmar pedido',
""",
    """                state.modoEdicion ? 'Confirmar cambios' : 'Confirmar pedido',
""",
    "título del modal de confirmación",
)
confirm_dialog = replace_once(
    confirm_dialog,
    """                _resumenRow('Estado inicial:', 'Pendiente'),
""",
    """                _resumenRow(
                  state.modoEdicion ? 'Estado al guardar:' : 'Estado inicial:',
                  'Pendiente',
                ),
""",
    "estado al guardar",
)
confirm_dialog = replace_once(
    confirm_dialog,
    """                          : 'Confirmar pedido',
""",
    """                          : state.modoEdicion
                          ? 'Guardar cambios'
                          : 'Confirmar pedido',
""",
    "acción final del modal",
)

# ---------------------------------------------------------------------------
# Navegación desde Gestión de pedidos.
# ---------------------------------------------------------------------------
list_view = replace_once(
    list_view,
    "import '../dialogs/pedido_detalle_dialog.dart';\n",
    """import '../dialogs/pedido_detalle_dialog.dart';
import '../pages/nuevo_pedido_page.dart';
""",
    "import de NuevoPedidoPage",
)

edit_flow = """  Future<void> _editarPedido(PedidoResumen pedido) async {
    if (pedido.estadoNormalizado == 'cancelado') {
      AppNotice.warning(
        context,
        'Reactiva el pedido antes de editar sus productos.',
      );
      return;
    }
    if (pedido.estadoNormalizado == 'entregado') {
      AppNotice.warning(context, 'Un pedido entregado no puede modificarse.');
      return;
    }

    if (pedido.estadoNormalizado == 'en_proceso' ||
        pedido.estadoNormalizado == 'listo') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.restart_alt_rounded,
            color: Color(0xFFF57C00),
          ),
          title: const Text('Editar pedido operativo'),
          content: Text(
            pedido.estadoNormalizado == 'listo'
                ? 'Este pedido ya fue preparado y cargado. Al guardar cambios '
                      'volverá a Pendiente y se eliminarán esos avances.'
                : 'Este pedido ya tiene avances de preparación. Al guardar '
                      'cambios volverá a Pendiente y se reiniciará la operación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC500),
                foregroundColor: Colors.black,
              ),
              child: const Text('Continuar edición'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NuevoPedidoPage(pedidoId: pedido.id),
      ),
    );
    if (!mounted || changed != true) return;
    context.read<PedidosListadoBloc>().add(
      const PedidosListadoRecargado(),
    );
  }"""
list_view = replace_between(
    list_view,
    "  Future<void> _editarPedido(PedidoResumen pedido) async {\n",
    "  Future<void> _mostrarCotizacionPedido(\n",
    edit_flow,
    "navegación real de edición",
)

# ---------------------------------------------------------------------------
# Mejoras visuales y semánticas, manteniendo los chips actuales.
# ---------------------------------------------------------------------------
order_card = replace_once(
    order_card,
    "          child: Text('Editar pedido'),",
    "          child: Text('Editar productos del pedido'),",
    "nombre explícito de edición",
)

header = replace_once(
    header,
    "                          _SyncPill(),",
    "                          const _LocalPill(),",
    "indicador local honesto",
)
sync_start = header.index("class _SyncPill extends StatelessWidget {")
header = header[:sync_start] + """class _LocalPill extends StatelessWidget {
  const _LocalPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC500).withValues(alpha: .16),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFFFC500).withValues(alpha: .45),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.storage_rounded,
          size: 12,
          color: Color(0xFFFFC500),
        ),
        const SizedBox(width: 4),
        Text(
          'Operación local',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFFFFC500),
          ),
        ),
      ],
    ),
  );
}
"""

consolidated_card = replace_once(
    consolidated_card,
    """                    : 'Registrar preparación',
""",
    """                    : 'Registrar avance',
""",
    "acción del consolidado",
)

prep_state = replace_once(
    prep_state,
    """  int get pedidosCargados => pedidos.where((pedido) => pedido.cargado).length;

  int get unidadesPendientes =>
""",
    """  int get pedidosCargados => pedidos.where((pedido) => pedido.cargado).length;

  int get paquetesCargados => pedidos
      .where((pedido) => pedido.cargado)
      .fold(0, (sum, pedido) => sum + pedido.paquetes);

  int get unidadesPendientes =>
""",
    "total de paquetes cargados",
)

prep_view = replace_once(
    prep_view,
    """          PreparacionModoChips(
            selected: state.modoAgrupacion,
            onChanged: (modo) => context.read<PreparacionCargaBloc>().add(
              PreparacionCargaModoAgrupacionCambiado(modo),
            ),
          ),
          Expanded(child: _construirVistaAgrupada(context, state)),
""",
    """          PreparacionModoChips(
            selected: state.modoAgrupacion,
            onChanged: (modo) => context.read<PreparacionCargaBloc>().add(
              PreparacionCargaModoAgrupacionCambiado(modo),
            ),
          ),
          _OperationalSummary(state: state),
          Expanded(child: _construirVistaAgrupada(context, state)),
""",
    "resumen operativo manteniendo chips",
)

summary_widget = """class _OperationalSummary extends StatelessWidget {
  const _OperationalSummary({required this.state});

  final PreparacionCargaState state;

  @override
  Widget build(BuildContext context) {
    final metrics = state.subTab == 0
        ? [
            (
              'Pendientes',
              state.pedidosPendientesPreparacion,
              Icons.pending_actions_outlined,
            ),
            (
              'En preparación',
              state.pedidosEnPreparacion,
              Icons.inventory_2_outlined,
            ),
            (
              'Listos',
              state.pedidosListosCarga,
              Icons.check_circle_outline,
            ),
          ]
        : [
            (
              'Por cargar',
              state.pedidosListosCarga,
              Icons.local_shipping_outlined,
            ),
            (
              'Cargados',
              state.pedidosCargados,
              Icons.task_alt_rounded,
            ),
            (
              'Paquetes',
              state.paquetesCargados,
              Icons.inventory_outlined,
            ),
          ];
    return Container(
      color: const Color(0xFFF7F8FA),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          for (var index = 0; index < metrics.length; index++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      metrics[index].$3,
                      size: 18,
                      color: const Color(0xFF1F1F1F),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${metrics[index].$2}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            metrics[index].$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < metrics.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

"""
prep_view = replace_once(
    prep_view,
    "class _SubTabs extends StatelessWidget {\n",
    summary_widget + "class _SubTabs extends StatelessWidget {\n",
    "componente de resumen operativo",
)

prep_header_old = """                    if (pedido.paquetes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${pedido.paquetes} paq.',
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                      ),
"""
prep_header_new = """                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _EstadoPreparacionChip(pedido: pedido),
                        if (pedido.paquetes > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${pedido.paquetes} paq.',
                              style: GoogleFonts.inter(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
"""
prep_card = replace_once(
    prep_card,
    prep_header_old,
    prep_header_new,
    "estado visible en tarjeta de preparación",
)
prep_card = replace_once(
    prep_card,
    """                label: const Text('Ver productos'),
""",
    """                label: Text(
                  pedido.cargado
                      ? 'Ver carga'
                      : pedido.presentacionesPreparadas > 0
                      ? 'Continuar preparación'
                      : 'Preparar pedido',
                ),
""",
    "acción contextual de preparación",
)

status_chip = """class _EstadoPreparacionChip extends StatelessWidget {
  const _EstadoPreparacionChip({required this.pedido});

  final PedidoPreparacion pedido;

  @override
  Widget build(BuildContext context) {
    final color = switch (pedido.estadoPreparacion) {
      'cargado' => const Color(0xFF2E7D32),
      'listo_cargar' => const Color(0xFF00796B),
      'en_preparacion' => const Color(0xFF1976D2),
      _ => const Color(0xFFF57C00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        pedido.estadoPreparacionLabel,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

"""
prep_card = replace_once(
    prep_card,
    "class PreparacionPedidoCard extends StatelessWidget {\n",
    "class PreparacionPedidoCard extends StatelessWidget {\n",
    "validación base de tarjeta",
)
prep_card = prep_card.rstrip() + "\n\n" + status_chip

prep_dialog = replace_once(
    prep_dialog,
    """    _items = widget.pedido.productos
        .map(
          (producto) => _ItemPreparacion(
            producto: producto,
            cantidadAhora: producto.pendiente,
          ),
        )
        .toList();
""",
    """    _items = widget.pedido.productos
        .map(
          (producto) => _ItemPreparacion(
            producto: producto,
            cantidadAhora: producto.pendiente,
          ),
        )
        .toList()
      ..sort((a, b) {
        if (a.producto.completado == b.producto.completado) {
          return a.producto.nombre.compareTo(b.producto.nombre);
        }
        return a.producto.completado ? 1 : -1;
      });
""",
    "pendientes primero en preparación",
)
prep_dialog = replace_once(
    prep_dialog,
    "label: const Text('Marcar todos'),",
    "label: const Text('Preparar todo lo pendiente'),",
    "acción rápida clara",
)

load_redundant = """                    if (widget.pedido.tienePendientes) ...[
                      const SizedBox(height: 18),
                      _advertencia(),
                    ],
"""
load_dialog = replace_once(
    load_dialog,
    load_redundant,
    "",
    "advertencia redundante de carga",
)

# ---------------------------------------------------------------------------
# Pruebas del flujo de edición.
# ---------------------------------------------------------------------------
test_import_anchor = (
    "import 'package:app_catalogo/features/pedidos/presentation/bloc/"
    "pedidos_event.dart';\n"
)
# No import adicional requerido; el ancla valida el archivo actual.
if test_import_anchor not in test:
    fail("No se encontró el bloque de imports esperado en pedidos_bloc_test.dart.")

edit_test = """  test('carga y actualiza el mismo pedido desde el carrito', () async {
    final pedidosRepository = _PedidosRepositoryFake()
      ..detalle = PedidoDetalle(
        id: 'pedido-edit',
        codigo: 'PED-2026-0042',
        fecha: DateTime(2026, 8, 2),
        estado: 'En proceso',
        sincronizado: false,
        guardadoLocal: true,
        clienteId: 'cliente-1',
        clienteNombre: 'Ferretería Central',
        telefono: '999888777',
        direccion: 'Av. Principal 123',
        referencia: 'Puerta azul',
        productos: const [
          PedidoDetalleProducto(
            id: 'item-1',
            productoId: 'precio',
            codigo: 'P-1',
            nombre: 'Perno',
            presentacion: 'Ciento',
            equivalencia: '100 UND',
            cantidad: 2,
            precioUnitario: 18.5,
            precioPedido: 18.5,
            subtotal: 37,
          ),
        ],
        subtotalConocido: 37,
        productosSinPrecio: 0,
        hoja: 'HP-2026-001',
        vendedor: 'Alfonzo Esteban',
        estadoPreparacion: 'parcial',
        estadoCarga: 'pendiente',
        historial: const [],
      );
    final bloc = PedidosBloc(
      _CatalogoRepositoryFake(),
      pedidosRepository,
    );
    addTearDown(bloc.close);

    bloc.add(const PedidosStarted(pedidoId: 'pedido-edit'));
    await bloc.stream.firstWhere(
      (state) => !state.loading && state.modoEdicion,
    );

    expect(bloc.state.pedidoCodigoEditando, 'PED-2026-0042');
    expect(bloc.state.carrito.single.pedidoItemId, 'item-1');
    expect(bloc.state.cliente?.nombre, 'Ferretería Central');

    bloc.add(const PedidoItemCantidadCambiada(0, 3));
    await bloc.stream.firstWhere(
      (state) => state.carrito.single.cantidad == 3,
    );
    bloc.add(const PedidoConfirmado());
    await bloc.stream.firstWhere((state) => state.resultado != null);

    expect(pedidosRepository.pedidoIdActualizado, 'pedido-edit');
    expect(pedidosRepository.itemsActualizados.single.cantidad, 3);
    expect(bloc.state.resultado?.codigo, 'PED-2026-0042');
  });

"""
test = replace_once(
    test,
    "  test('no confirma un pedido sin dirección de cliente', () async {\n",
    edit_test + "  test('no confirma un pedido sin dirección de cliente', () async {\n",
    "prueba de edición de pedido",
)
test = replace_once(
    test,
    """  HojaPedidoActiva? hojaGuardada;
  int _consultasHoja = 0;
""",
    """  HojaPedidoActiva? hojaGuardada;
  PedidoDetalle? detalle;
  String? pedidoIdActualizado;
  List<PedidoItem> itemsActualizados = [];
  int _consultasHoja = 0;
""",
    "estado del repositorio falso",
)
test = replace_once(
    test,
    """  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) async => null;
""",
    """  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) async => detalle;
""",
    "detalle editable en fake",
)
fake_update = """  @override
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async {
    pedidoIdActualizado = pedidoId;
    itemsActualizados = items;
    return PedidoRegistrado(
      id: pedidoId,
      codigo: detalle?.codigo ?? 'PED-2026-0042',
      cliente: cliente.nombre,
      hojaCodigo: detalle?.hoja ?? 'HP-2026-001',
      estado: 'Pendiente',
    );
  }

"""
test = replace_once(
    test,
    """  @override
  Future<PedidoRegistrado> guardarPedido({
""",
    fake_update + """  @override
  Future<PedidoRegistrado> guardarPedido({
""",
    "actualizarPedido en repositorio falso",
)

updates = {
    DB: db,
    PEDIDO: pedido,
    DETALLE: detalle,
    REPOSITORY: repository,
    REPOSITORY_IMPL: repository_impl,
    DATASOURCE: datasource,
    EVENT: event,
    STATE: state,
    BLOC: bloc,
    NEW_ORDER_PAGE: new_order_page,
    CONFIRM_DIALOG: confirm_dialog,
    LIST_VIEW: list_view,
    ORDER_CARD: order_card,
    HEADER: header,
    CONSOLIDATED_CARD: consolidated_card,
    PREP_STATE: prep_state,
    PREP_VIEW: prep_view,
    PREP_CARD: prep_card,
    PREP_DIALOG: prep_dialog,
    LOAD_DIALOG: load_dialog,
    TEST: test,
}

# Validaciones finales antes de escribir.
for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado de {path.relative_to(ROOT)} está vacío.")

required_results = {
    DB: ["version: 22,", "_asegurarIdentidadPedidoItems"],
    PEDIDO: ["final String pedidoItemId;"],
    DETALLE: ["final String varianteId;", "final double? precioPedido;"],
    REPOSITORY: ["Future<PedidoRegistrado> actualizarPedido({"],
    DATASOURCE: [
        "Future<PedidoRegistrado> actualizarPedido({",
        "'activo': 0",
        "'atributos_variante_json': jsonEncode",
    ],
    STATE: ["bool get modoEdicion", "int get lineasLegadas"],
    BLOC: ["_reconstruirItemEdicion", "actualizarPedido("],
    NEW_ORDER_PAGE: ["Editar pedido", "_EdicionPedidoBanner"],
    LIST_VIEW: ["NuevoPedidoPage(pedidoId: pedido.id)"],
    PREP_VIEW: ["_OperationalSummary"],
    TEST: ["carga y actualiza el mismo pedido desde el carrito"],
}
for path, markers in required_results.items():
    for marker in markers:
        if marker not in updates[path]:
            fail(
                f"El resultado de {path.relative_to(ROOT)} no contiene: {marker}"
            )

for content in updates.values():
    if "La edición de productos se aplicará en la siguiente fase" in content:
        fail("Permanece el aviso provisional de edición.")

backup_dir = ROOT / (
    ".backup_edicion_pedido_gestion_operativa_v2_"
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
print("\nAplicada la edición integral del pedido y las mejoras operativas (v2).")
print("Los chips de Consolidado y Preparación y carga se conservaron.")
print("La migración SQLite es aditiva; no se tocó app_catalogo.db.")
print("\nEjecuta después de confirmar esta salida:")
print("  dart format lib test")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter test test/cotizacion_flujo_test.dart")
print("  flutter test test/cotizacion_edicion_test.dart")
print("  flutter test test/pedido_card_reactivar_test.dart")
print("  flutter test test/agregar_producto_dialog_test.dart")
print("  flutter analyze")