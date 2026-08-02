from __future__ import annotations

from datetime import datetime
from pathlib import Path
import subprocess
import shutil

ROOT = Path.cwd()
EXPECTED_HEAD = "43c6b44d227e9ca2d3d11eddd95ecd2eedec19b0"

CARD = ROOT / "lib/features/catalogo/presentation/widgets/producto_card.dart"
CATALOG_PAGE = ROOT / "lib/features/catalogo/presentation/pages/catalogo_page.dart"
NEW_ORDER_PAGE = ROOT / "lib/features/pedidos/presentation/pages/nuevo_pedido_page.dart"
QUOTE_ENTITY = ROOT / "lib/features/pedidos/domain/entities/cotizacion_pedido.dart"
REPOSITORY = ROOT / "lib/features/pedidos/domain/repositories/pedidos_repository.dart"
REPOSITORY_IMPL = ROOT / "lib/features/pedidos/data/repositories/pedidos_repository_impl.dart"
DATASOURCE = ROOT / "lib/features/pedidos/data/datasources/pedidos_local_datasource.dart"
QUOTE_DIALOG = ROOT / "lib/features/pedidos/presentation/dialogs/generar_cotizacion_dialog.dart"
DETAIL_DIALOG = ROOT / "lib/features/pedidos/presentation/dialogs/pedido_detalle_dialog.dart"
LIST_VIEW = ROOT / "lib/features/pedidos/presentation/views/pedidos_listado_view.dart"
ORDER_CARD = ROOT / "lib/features/pedidos/presentation/widgets/pedido_card.dart"
LIST_EVENTS = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_listado_event.dart"
LIST_BLOC = ROOT / "lib/features/pedidos/presentation/bloc/pedidos_listado_bloc.dart"
CARD_TEST = ROOT / "test/producto_card_layout_test.dart"
QUOTE_TEST = ROOT / "test/cotizacion_edicion_test.dart"
REACTIVATE_TEST = ROOT / "test/pedido_card_reactivar_test.dart"


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

required_paths = [
    CARD,
    CATALOG_PAGE,
    NEW_ORDER_PAGE,
    QUOTE_ENTITY,
    REPOSITORY,
    REPOSITORY_IMPL,
    DATASOURCE,
    QUOTE_DIALOG,
    DETAIL_DIALOG,
    LIST_VIEW,
    ORDER_CARD,
    LIST_EVENTS,
    LIST_BLOC,
    CARD_TEST,
]
for path in required_paths:
    if not path.exists():
        fail(f"No se encontró {path.relative_to(ROOT)}")

for path in (QUOTE_TEST, REACTIVATE_TEST):
    if path.exists():
        fail(f"Ya existe {path.relative_to(ROOT)}")

sources = {path: path.read_text(encoding="utf-8") for path in required_paths}

markers = {
    CARD: [
        "_imagen(height: compacto ? 142 : 176)",
        "children: [_imagen(height: 172), contenido]",
        "SizedBox(width: 220, child: _imagen(height: 220))",
        "SizedBox(height: expandido ? 12 : 14)",
    ],
    CATALOG_PAGE: ["mainAxisExtent: constraints.maxWidth < 500 ? 500 : 480"],
    NEW_ORDER_PAGE: ["mainAxisExtent: constraints.maxWidth < 500 ? 500 : 480"],
    QUOTE_ENTITY: ["class CotizacionPedidoGuardada extends Equatable"],
    REPOSITORY: ["Future<CotizacionPedidoGuardada> guardarCotizacion("],
    REPOSITORY_IMPL: ["class PedidosRepositoryImpl implements PedidosRepository"],
    DATASOURCE: [
        "Future<CotizacionPedidoGuardada> guardarCotizacion(",
        "Total de cotización — incluye IGV:",
        "LOWER(co.estado) <> 'borrador'",
    ],
    QUOTE_DIALOG: [
        "this.modoEdicion = false,",
        "void _ensureInitialized(PedidoDetalle pedido)",
        "estado: exportarPdf || widget.modoEdicion ? 'Generada' : 'Borrador'",
        "final esBorrador = !exportarPdf && !widget.modoEdicion;",
    ],
    DETAIL_DIALOG: [
        "enum PedidoDetalleDialogAction { editar, cotizacion, cambiarEstado, verCliente }",
        "class _CotizacionTab extends StatelessWidget",
        "class _ActionsBar extends StatelessWidget",
    ],
    LIST_VIEW: [
        "case PedidoDetalleDialogAction.editar:",
        "await _mostrarCotizacionPedido(pedido, modoEdicion: true);",
    ],
    ORDER_CARD: [
        "pedido.estadoNormalizado == 'cancelado'",
        "const PopupMenuItem(value: 'editar_precio', child: Text('Editar precio'))",
    ],
    LIST_EVENTS: ["class PedidosListadoPedidoCancelado extends PedidosListadoEvent"],
    LIST_BLOC: ["on<PedidosListadoPedidoCancelado>(_cancelarPedido);"],
    CARD_TEST: ["height: 480,", "expect(find.text('+3 más'), findsOneWidget);"],
}
for path, expected in markers.items():
    for marker in expected:
        if marker not in sources[path]:
            fail(
                f"{path.relative_to(ROOT)} no contiene el marcador esperado: "
                f"{marker}"
            )

card = sources[CARD]
catalog_page = sources[CATALOG_PAGE]
new_order_page = sources[NEW_ORDER_PAGE]
repo_impl = sources[REPOSITORY_IMPL]
datasource = sources[DATASOURCE]
quote_dialog = sources[QUOTE_DIALOG]
detail_dialog = sources[DETAIL_DIALOG]
list_view = sources[LIST_VIEW]
order_card = sources[ORDER_CARD]
list_events = sources[LIST_EVENTS]
list_bloc = sources[LIST_BLOC]
card_test = sources[CARD_TEST]

# Tarjetas: imagen +20 % y acciones ancladas al borde inferior.
card = replace_once(
    card,
    "_imagen(height: compacto ? 142 : 176)",
    "_imagen(height: compacto ? 170 : 212)",
    "altura de imagen en grilla",
)
card = replace_once(
    card,
    "children: [_imagen(height: 172), contenido]",
    "children: [_imagen(height: 206), contenido]",
    "altura de imagen en lista angosta",
)
card = replace_once(
    card,
    "SizedBox(width: 220, child: _imagen(height: 220))",
    "SizedBox(width: 264, child: _imagen(height: 264))",
    "altura de imagen en lista amplia",
)
card = replace_once(
    card,
    "        SizedBox(height: expandido ? 12 : 14),\n"
    "        _precio(fontSize: 14),",
    "        if (expandido) const Spacer() else const SizedBox(height: 14),\n"
    "        _precio(fontSize: 14),",
    "acciones al final de la tarjeta",
)
catalog_page = replace_once(
    catalog_page,
    "mainAxisExtent: constraints.maxWidth < 500 ? 500 : 480",
    "mainAxisExtent: constraints.maxWidth < 500 ? 550 : 520",
    "altura de tarjeta en Catálogo",
)
new_order_page = replace_once(
    new_order_page,
    "mainAxisExtent: constraints.maxWidth < 500 ? 500 : 480",
    "mainAxisExtent: constraints.maxWidth < 500 ? 550 : 520",
    "altura de tarjeta en Nuevo pedido",
)
card_test = replace_once(
    card_test,
    "height: 480,",
    "height: 520,",
    "altura real de la prueba de tarjeta",
)
card_test = replace_once(
    card_test,
    "      expect(find.text('+3 más'), findsOneWidget);\n"
    "      expect(find.text('Agregar'), findsOneWidget);",
    "      expect(find.text('+3 más'), findsOneWidget);\n"
    "      expect(\n"
    "        tester.getSize(find.byKey(const Key('producto_imagen_product-1'))).height,\n"
    "        212,\n"
    "      );\n"
    "      final cardBottom = tester.getBottomRight(find.byType(ProductoCard)).dy;\n"
    "      final buttonBottom = tester.getBottomRight(find.text('Agregar')).dy;\n"
    "      expect(cardBottom - buttonBottom, lessThan(34));\n"
    "      expect(find.text('Agregar'), findsOneWidget);",
    "prueba de imagen y acciones inferiores",
)

# Repositorio e implementación.
repo_impl = replace_once(
    repo_impl,
    "  @override\n"
    "  Future<CotizacionPedidoGuardada> guardarCotizacion(\n"
    "    CotizacionPedidoDraft cotizacion,\n"
    "  ) => localDatasource.guardarCotizacion(cotizacion);\n",
    "  @override\n"
    "  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) =>\n"
    "      localDatasource.obtenerCotizacion(id);\n\n"
    "  @override\n"
    "  Future<CotizacionPedidoGuardada> guardarCotizacion(\n"
    "    CotizacionPedidoDraft cotizacion,\n"
    "  ) => localDatasource.guardarCotizacion(cotizacion);\n\n"
    "  @override\n"
    "  Future<CotizacionPedidoGuardada> actualizarCotizacion({\n"
    "    required String cotizacionId,\n"
    "    required CotizacionPedidoDraft cotizacion,\n"
    "  }) => localDatasource.actualizarCotizacion(\n"
    "    cotizacionId: cotizacionId,\n"
    "    cotizacion: cotizacion,\n"
    "  );\n",
    "lectura y actualización de cotizaciones",
)
repo_impl = replace_once(
    repo_impl,
    "  @override\n"
    "  Future<void> reintentarSincronizacionPedido(String pedidoId) =>",
    "  @override\n"
    "  Future<void> reactivarPedido({\n"
    "    required String pedidoId,\n"
    "    String observacion = '',\n"
    "  }) => localDatasource.reactivarPedido(\n"
    "    pedidoId: pedidoId,\n"
    "    observacion: observacion,\n"
    "  );\n\n"
    "  @override\n"
    "  Future<void> reintentarSincronizacionPedido(String pedidoId) =>",
    "reactivación en repositorio",
)

# Solo una cotización Generada es vigente. Las Archivadas siguen en historial.
datasource = datasource.replace(
    "LOWER(co.estado) <> 'borrador'",
    "LOWER(co.estado) = 'generada'",
)

quote_loader = r'''  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async {
    final db = await _db;
    final rows = await db.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'cotizacion_items',
      where: 'cotizacion_id = ?',
      whereArgs: [id],
      orderBy: 'nombre ASC',
    );
    return _cotizacionGuardadaFromMap(rows.first, itemRows);
  }

  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) async {
    if (cotizacion.items.isEmpty) {
      throw StateError('La cotización no tiene productos.');
    }
    final db = await _db;
    final selected = await db.query(
      'cotizaciones',
      where: 'id = ?',
      whereArgs: [cotizacionId],
      limit: 1,
    );
    if (selected.isEmpty) {
      throw StateError('La cotización seleccionada ya no existe.');
    }
    final selectedState =
        (selected.first['estado'] as String? ?? '').trim().toLowerCase();

    // Las versiones ya generadas son documentos históricos inmutables.
    // Editarlas crea una nueva versión; solo el borrador se actualiza.
    if (selectedState != 'borrador') {
      return guardarCotizacion(cotizacion);
    }

    final generated = cotizacion.estado.trim().toLowerCase() != 'borrador';
    if (generated &&
        cotizacion.items.any((item) => item.precioCotizacion <= 0)) {
      throw StateError(
        'Todos los productos deben tener un precio válido antes de generar la cotización.',
      );
    }

    await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      if (generated) {
        await txn.update(
          'cotizaciones',
          {'estado': 'Archivada', 'actualizado_en': now},
          where:
              "pedido_id = ? AND id <> ? AND LOWER(estado) = 'generada'",
          whereArgs: [cotizacion.pedidoId, cotizacionId],
        );
      }
      await txn.update(
        'cotizaciones',
        {
          'subtotal': cotizacion.subtotal,
          'descuento_global': cotizacion.descuentoGlobal,
          'tipo_descuento_global': cotizacion.tipoDescuentoGlobal,
          'descuento_global_porcentaje':
              cotizacion.descuentoGlobalPorcentaje,
          'descuento_global_monto': cotizacion.descuentoGlobalMonto,
          'total': cotizacion.total,
          'vigencia_dias': cotizacion.vigenciaDias,
          'condiciones': cotizacion.condiciones,
          'observaciones': cotizacion.observaciones,
          'estado': cotizacion.estado,
          'actualizado_en': now,
        },
        where: 'id = ?',
        whereArgs: [cotizacionId],
      );
      await txn.delete(
        'cotizacion_items',
        where: 'cotizacion_id = ?',
        whereArgs: [cotizacionId],
      );
      await _insertarItemsCotizacion(
        txn,
        cotizacionId: cotizacionId,
        items: cotizacion.items,
      );
      if (generated) {
        await txn.update(
          'pedidos',
          {
            'subtotal_conocido': cotizacion.total,
            'total_parcial': 0,
            'sincronizado': 0,
            'sync_error': null,
          },
          where: 'id = ?',
          whereArgs: [cotizacion.pedidoId],
        );
        final version = selected.first['version'] as int? ?? 1;
        final code = selected.first['codigo'] as String? ?? '';
        await _registrarHistorialPedido(
          txn,
          pedidoId: cotizacion.pedidoId,
          evento: 'Cotización $code vigente • versión $version',
          observacion:
              'Total de cotización: S/ ${cotizacion.total.toStringAsFixed(2)}',
          responsable: null,
          creadoEn: now,
        );
      }
    });
    final updated = await obtenerCotizacion(cotizacionId);
    if (updated == null) {
      throw StateError('No se pudo volver a leer la cotización.');
    }
    return updated;
  }

'''
datasource = replace_once(
    datasource,
    "  Future<CotizacionPedidoGuardada> guardarCotizacion(\n",
    quote_loader + "  Future<CotizacionPedidoGuardada> guardarCotizacion(\n",
    "lectura y edición de cotización",
)

# Archivar la vigente anterior al generar una nueva versión.
datasource = replace_once(
    datasource,
    "      final cotizacionId = const Uuid().v4();\n"
    "      final nowIso = now.toIso8601String();\n"
    "      await txn.insert('cotizaciones', {",
    "      final cotizacionId = const Uuid().v4();\n"
    "      final nowIso = now.toIso8601String();\n"
    "      if (esGenerada) {\n"
    "        await txn.update(\n"
    "          'cotizaciones',\n"
    "          {'estado': 'Archivada', 'actualizado_en': nowIso},\n"
    "          where: \"pedido_id = ? AND LOWER(estado) = 'generada'\",\n"
    "          whereArgs: [cotizacion.pedidoId],\n"
    "        );\n"
    "      }\n"
    "      await txn.insert('cotizaciones', {",
    "archivar versión vigente anterior",
)

old_item_loop = r'''      for (final item in cotizacion.items) {
        await txn.insert('cotizacion_items', {
          'id': const Uuid().v4(),
          'cotizacion_id': cotizacionId,
          'pedido_item_id': item.pedidoItemId,
          'producto_id': item.productoId,
          'codigo': item.codigo,
          'nombre': item.nombre,
          'presentacion': item.presentacion,
          'cantidad': item.cantidad,
          'precio_cotizacion': item.precioCotizacion,
          'descuento': item.descuento,
          'tipo_descuento': item.tipoDescuento,
          'precio_final': item.precioFinal,
          'subtotal': item.subtotal,
        });
      }
'''
datasource = replace_once(
    datasource,
    old_item_loop,
    "      await _insertarItemsCotizacion(\n"
    "        txn,\n"
    "        cotizacionId: cotizacionId,\n"
    "        items: cotizacion.items,\n"
    "      );\n",
    "helper de productos cotizados",
)
datasource = replace_once(
    datasource,
    "'Total de cotización — incluye IGV: S/ ${cotizacion.total.toStringAsFixed(2)}'",
    "'Total de cotización: S/ ${cotizacion.total.toStringAsFixed(2)}'",
    "texto del historial sin frase redundante",
)

reactivate_method = r'''  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) async {
    final db = await _db;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'pedidos',
        columns: ['id', 'estado', 'vendedor'],
        where: 'id = ?',
        whereArgs: [pedidoId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('El pedido seleccionado ya no existe.');
      }
      final current = _normalizarEstadoPedido(
        rows.first['estado'] as String? ?? '',
      );
      if (current != 'cancelado') {
        throw StateError('Solo se puede reactivar un pedido cancelado.');
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
        'pedidos',
        {
          'estado': 'Pendiente',
          'sincronizado': 0,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [pedidoId],
      );
      await _registrarHistorialPedido(
        txn,
        pedidoId: pedidoId,
        evento: 'Pedido reactivado • estado Pendiente',
        observacion: observacion.trim(),
        responsable: rows.first['vendedor'] as String?,
        creadoEn: now,
      );
    });
  }

'''
datasource = replace_once(
    datasource,
    "  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async {",
    reactivate_method
    + "  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async {",
    "reactivación de pedido",
)

helpers = r'''  Future<void> _insertarItemsCotizacion(
    Transaction txn, {
    required String cotizacionId,
    required List<CotizacionPedidoItemDraft> items,
  }) async {
    for (final item in items) {
      await txn.insert('cotizacion_items', {
        'id': const Uuid().v4(),
        'cotizacion_id': cotizacionId,
        'pedido_item_id': item.pedidoItemId,
        'producto_id': item.productoId,
        'codigo': item.codigo,
        'nombre': item.nombre,
        'presentacion': item.presentacion,
        'cantidad': item.cantidad,
        'precio_cotizacion': item.precioCotizacion,
        'descuento': item.descuento,
        'tipo_descuento': item.tipoDescuento,
        'precio_final': item.precioFinal,
        'subtotal': item.subtotal,
      });
    }
  }

  CotizacionPedidoGuardada _cotizacionGuardadaFromMap(
    Map<String, Object?> row,
    List<Map<String, Object?>> itemRows,
  ) {
    final total = (row['total'] as num? ?? 0).toDouble();
    final subtotal = (row['subtotal'] as num? ?? 0).toDouble();
    final global = (row['descuento_global'] as num? ?? 0).toDouble();
    final items = itemRows
        .map(
          (item) => CotizacionPedidoItemGuardado(
            id: item['id'] as String,
            pedidoItemId: item['pedido_item_id'] as String,
            productoId: item['producto_id'] as String,
            codigo: item['codigo'] as String? ?? '',
            nombre: item['nombre'] as String? ?? '',
            presentacion: item['presentacion'] as String? ?? '',
            cantidad: item['cantidad'] as int? ?? 0,
            precioCotizacion:
                (item['precio_cotizacion'] as num? ?? 0).toDouble(),
            descuento: (item['descuento'] as num? ?? 0).toDouble(),
            tipoDescuento: item['tipo_descuento'] as String? ?? 'monto',
            precioFinal: (item['precio_final'] as num? ?? 0).toDouble(),
            subtotal: (item['subtotal'] as num? ?? 0).toDouble(),
          ),
        )
        .toList();
    final itemDiscounts = items.fold<double>(
      0,
      (sum, item) =>
          sum +
          (item.precioCotizacion * item.cantidad - item.subtotal)
              .clamp(0, double.infinity)
              .toDouble(),
    );
    return CotizacionPedidoGuardada(
      id: row['id'] as String,
      pedidoId: row['pedido_id'] as String,
      codigo: (row['codigo_base'] as String? ?? '').trim().isEmpty
          ? row['codigo'] as String
          : row['codigo_base'] as String,
      total: total,
      creadoEn:
          DateTime.tryParse(row['creado_en'] as String? ?? '') ??
          DateTime.now(),
      pdfPath: row['pdf_path'] as String?,
      version: row['version'] as int? ?? 1,
      estado: row['estado'] as String? ?? 'Generada',
      subtotalProductos: subtotal,
      descuento: itemDiscounts + global,
      totalSinIgv: CotizacionIgv.totalSinIgv(total),
      igv: CotizacionIgv.igvIncluido(total),
      vigenciaDias: row['vigencia_dias'] as int? ?? 7,
      condiciones: row['condiciones'] as String? ?? '',
      observaciones: row['observaciones'] as String? ?? '',
      descuentoGlobalPorcentaje:
          (row['descuento_global_porcentaje'] as num? ?? 0).toDouble(),
      descuentoGlobalMonto:
          (row['descuento_global_monto'] as num? ?? 0).toDouble(),
      items: items,
    );
  }

'''
datasource = replace_once(
    datasource,
    "  PedidoDetalle _pedidoDetalleFromMaps(\n",
    helpers + "  PedidoDetalle _pedidoDetalleFromMaps(\n",
    "helpers de cotización persistida",
)

old_quote_map_start = """    final cotizaciones = cotizacionesRows
        .map(
          (row) => CotizacionPedidoGuardada(
"""
old_quote_map_end = """        )
        .toList();
    final historial = [
"""
if old_quote_map_start not in datasource or old_quote_map_end not in datasource:
    fail("No se pudo delimitar el mapeo de cotizaciones del detalle.")
start = datasource.index(old_quote_map_start)
end = datasource.index(old_quote_map_end, start) + len("        )\n        .toList();")
datasource = (
    datasource[:start]
    + "    final cotizaciones = cotizacionesRows\n"
      "        .map((quote) => _cotizacionGuardadaFromMap(quote, const []))\n"
      "        .toList();"
    + datasource[end:]
)

# Ocultar la frase antigua aunque exista en registros previos.
datasource = replace_once(
    datasource,
    "        final observacion = entrada['observacion'] as String? ?? '';\n"
    "        final evento = entrada['evento'] as String? ?? '';\n"
    "        return PedidoHistorialEntrada(\n"
    "          fecha: entradaFecha,\n"
    "          evento: observacion.trim().isEmpty ? evento : '$evento\\n$observacion',",
    "        final observacion = (entrada['observacion'] as String? ?? '')\n"
    "            .replaceAll(' — incluye IGV', '')\n"
    "            .replaceAll(' - incluye IGV', '');\n"
    "        final evento = (entrada['evento'] as String? ?? '')\n"
    "            .replaceAll(' — incluye IGV', '')\n"
    "            .replaceAll(' - incluye IGV', '');\n"
    "        return PedidoHistorialEntrada(\n"
    "          fecha: entradaFecha,\n"
    "          evento: observacion.trim().isEmpty ? evento : '$evento\\n$observacion',",
    "limpieza de historial legado",
)

# Diálogo de cotización: cargar la versión seleccionada y actualizar borradores.
quote_dialog = replace_once(
    quote_dialog,
    "    this.modoEdicion = false,\n"
    "    super.key,",
    "    this.modoEdicion = false,\n"
    "    this.cotizacionId,\n"
    "    super.key,",
    "identificador de cotización seleccionada",
)
quote_dialog = replace_once(
    quote_dialog,
    "  final String pedidoId;\n"
    "  final bool modoEdicion;\n",
    "  final String pedidoId;\n"
    "  final bool modoEdicion;\n"
    "  final String? cotizacionId;\n",
    "campo de cotización seleccionada",
)
quote_dialog = replace_once(
    quote_dialog,
    "    bool modoEdicion = false,\n"
    "  }) => showDialog<CotizacionPedidoGuardada>(\n",
    "    bool modoEdicion = false,\n"
    "    String? cotizacionId,\n"
    "  }) => showDialog<CotizacionPedidoGuardada>(\n",
    "parámetro al abrir cotización",
)
quote_dialog = replace_once(
    quote_dialog,
    "    builder: (_) =>\n"
    "        GenerarCotizacionDialog(pedidoId: pedidoId, modoEdicion: modoEdicion),",
    "    builder: (_) => GenerarCotizacionDialog(\n"
    "      pedidoId: pedidoId,\n"
    "      modoEdicion: modoEdicion,\n"
    "      cotizacionId: cotizacionId,\n"
    "    ),",
    "construcción del editor de cotización",
)
quote_dialog = replace_once(
    quote_dialog,
    "  late final Future<PedidoDetalle?> _pedidoFuture;\n",
    "  late final Future<PedidoDetalle?> _pedidoFuture;\n"
    "  late final Future<CotizacionPedidoGuardada?> _cotizacionFuture;\n",
    "future de cotización",
)
quote_dialog = replace_once(
    quote_dialog,
    "  List<CotizacionProductoFormItem> _productos = [];\n",
    "  List<CotizacionProductoFormItem> _productos = [];\n"
    "  CotizacionPedidoGuardada? _cotizacionSeleccionada;\n",
    "estado de cotización seleccionada",
)
quote_dialog = replace_once(
    quote_dialog,
    "    _pedidoFuture = context.read<PedidosRepository>().obtenerPedidoDetalle(\n"
    "      widget.pedidoId,\n"
    "    );\n",
    "    final repository = context.read<PedidosRepository>();\n"
    "    _pedidoFuture = repository.obtenerPedidoDetalle(widget.pedidoId);\n"
    "    _cotizacionFuture = widget.cotizacionId == null\n"
    "        ? Future.value(null)\n"
    "        : repository.obtenerCotizacion(widget.cotizacionId!);\n",
    "carga inicial de cotización",
)

old_return = """              _ensureInitialized(pedido);
              return Column(
                children: [
                  _Header(pedido: pedido),
                  _StepHeader(currentStep: _currentStep),
                  Expanded(child: _buildStep(pedido)),
                  _BottomBar(
                    currentStep: _currentStep,
                    saving: _saving,
                    canContinue: _todosConPrecio,
                    onBack: _currentStep > 0
                        ? () => setState(() => _currentStep--)
                        : null,
                    onClose: () => Navigator.of(context).pop(),
                    onContinue: () => _continuar(),
                    onSaveDraft: () => _guardar(pedido, exportarPdf: false),
                    onExport: () => _guardar(pedido, exportarPdf: true),
                    modoEdicion: widget.modoEdicion,
                  ),
                ],
              );
"""
new_return = """              return FutureBuilder<CotizacionPedidoGuardada?>(
                future: _cotizacionFuture,
                builder: (context, quoteSnapshot) {
                  if (quoteSnapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }
                  if (quoteSnapshot.hasError) {
                    return _DialogError(
                      title: 'No se pudo cargar la cotización',
                      message:
                          'La versión seleccionada no pudo leerse desde la base local.',
                      onClose: () => Navigator.of(context).pop(),
                    );
                  }
                  if (widget.cotizacionId != null &&
                      quoteSnapshot.data == null) {
                    return _DialogError(
                      title: 'Cotización no encontrada',
                      message:
                          'La versión seleccionada ya no existe en la base local.',
                      onClose: () => Navigator.of(context).pop(),
                    );
                  }
                  _ensureInitialized(pedido, quoteSnapshot.data);
                  return Column(
                    children: [
                      _Header(
                        pedido: pedido,
                        cotizacion: quoteSnapshot.data,
                      ),
                      _StepHeader(currentStep: _currentStep),
                      Expanded(child: _buildStep(pedido)),
                      _BottomBar(
                        currentStep: _currentStep,
                        saving: _saving,
                        canContinue: _todosConPrecio,
                        onBack: _currentStep > 0
                            ? () => setState(() => _currentStep--)
                            : null,
                        onClose: () => Navigator.of(context).pop(),
                        onContinue: () => _continuar(),
                        onSaveDraft: () =>
                            _guardar(pedido, exportarPdf: false),
                        onExport: () =>
                            _guardar(pedido, exportarPdf: true),
                        modoEdicion: widget.cotizacionId != null,
                      ),
                    ],
                  );
                },
              );
"""
quote_dialog = replace_once(
    quote_dialog,
    old_return,
    new_return,
    "cuerpo del editor de cotización",
)

new_initialize = r'''  void _ensureInitialized(
    PedidoDetalle pedido,
    CotizacionPedidoGuardada? selected,
  ) {
    if (_initialized) return;
    _cotizacionSeleccionada = selected;
    final savedByItem = {
      for (final item in selected?.items ?? const [])
        item.pedidoItemId: item,
    };
    _productos = pedido.productos.map((producto) {
      final saved = savedByItem[producto.id];
      return CotizacionProductoFormItem(
        producto: producto,
        precioCotizacion:
            saved?.precioCotizacion ?? producto.precioUnitario ?? 0,
        descuento: saved?.descuento ?? producto.descuentoCotizado,
        tipoDescuento:
            saved?.tipoDescuento ?? producto.tipoDescuentoCotizado,
      );
    }).toList();

    if (selected != null) {
      _totalesValue = CotizacionTotalesValue(
        descuentoGlobalPorcentaje: selected.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: selected.descuentoGlobalMonto,
        observaciones: selected.observaciones,
        vigenciaDias: selected.vigenciaDias,
        condiciones: selected.condiciones,
      );
    } else if (pedido.cotizacionVigente) {
      _totalesValue = CotizacionTotalesValue(
        descuentoGlobalPorcentaje: pedido.descuentoGlobalPorcentaje,
        descuentoGlobalMonto: pedido.descuentoGlobalMonto,
        observaciones: pedido.observacionesCotizacion,
        vigenciaDias: 7,
        condiciones: '',
      );
    }
    _initialized = true;
  }'''
quote_dialog = replace_between(
    quote_dialog,
    "  void _ensureInitialized(PedidoDetalle pedido) {",
    "  Widget _buildStep(PedidoDetalle pedido) {",
    new_initialize,
    "inicialización desde versión guardada",
)
quote_dialog = replace_once(
    quote_dialog,
    "    final esBorrador = !exportarPdf && !widget.modoEdicion;\n",
    "    final esBorrador = !exportarPdf;\n",
    "validación coherente del borrador reabierto",
)
quote_dialog = replace_once(
    quote_dialog,
    "        estado: exportarPdf || widget.modoEdicion ? 'Generada' : 'Borrador',\n"
    "      );\n"
    "      final guardada = await repository.guardarCotizacion(draft);",
    "        estado: exportarPdf ? 'Generada' : 'Borrador',\n"
    "      );\n"
    "      final selected = _cotizacionSeleccionada;\n"
    "      final guardada = selected != null && selected.esBorrador\n"
    "          ? await repository.actualizarCotizacion(\n"
    "              cotizacionId: selected.id,\n"
    "              cotizacion: draft,\n"
    "            )\n"
    "          : await repository.guardarCotizacion(draft);",
    "guardado de borrador o nueva versión",
)

new_header = r'''class _Header extends StatelessWidget {
  const _Header({required this.pedido, this.cotizacion});

  final PedidoDetalle pedido;
  final CotizacionPedidoGuardada? cotizacion;

  @override
  Widget build(BuildContext context) {
    final selected = cotizacion;
    final title = selected == null
        ? 'Nueva cotización'
        : selected.esBorrador
        ? 'Editar borrador'
        : 'Editar como nueva versión';
    final subtitle = selected == null
        ? '${pedido.codigo} · ${pedido.clienteNombre}'
        : '${selected.codigoVersion} · ${selected.estado} · ${pedido.clienteNombre}';

    return Container(
      color: _GenerarCotizacionDialogState.darkColor,
      padding: const EdgeInsets.fromLTRB(20, 15, 12, 15),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: _GenerarCotizacionDialogState.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.request_quote_outlined,
              color: _GenerarCotizacionDialogState.darkColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFB7BAC1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}'''
quote_dialog = replace_between(
    quote_dialog,
    "class _Header extends StatelessWidget {",
    "class _StepHeader extends StatelessWidget {",
    new_header,
    "encabezado contextual de cotización",
)
quote_dialog = replace_once(
    quote_dialog,
    "          if (!modoEdicion)\n"
    "            OutlinedButton.icon(",
    "          OutlinedButton.icon(",
    "permitir guardar borrador durante edición",
)
quote_dialog = replace_once(
    quote_dialog,
    "              label: const Text('Guardar borrador'),",
    "              label: Text(modoEdicion ? 'Guardar como borrador' : 'Guardar borrador'),",
    "etiqueta de borrador",
)

# Detalle de pedido: el diálogo permanece abierto durante cotización.
detail_state = r'''class _PedidoDetalleDialogState extends State<PedidoDetalleDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<PedidoDetalle?> _pedidoFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _pedidoFuture = _obtenerPedido();
  }

  Future<PedidoDetalle?> _obtenerPedido() =>
      context.read<PedidosRepository>().obtenerPedidoDetalle(widget.pedidoId);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirCotizacion(String? cotizacionId) async {
    final result = await GenerarCotizacionDialog.show(
      context,
      pedidoId: widget.pedidoId,
      cotizacionId: cotizacionId,
      modoEdicion: cotizacionId != null,
    );
    if (!mounted || result == null) return;
    setState(() {
      _pedidoFuture = _obtenerPedido();
      _tabController.index = 3;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 1120
            ? 1120.0
            : constraints.maxWidth;
        final height = constraints.maxHeight > 900
            ? 900.0
            : constraints.maxHeight;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: FutureBuilder<PedidoDetalle?>(
            future: _pedidoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PedidoDetalleLoading();
              }
              if (snapshot.hasError) {
                return _PedidoDetalleError(
                  title: 'No se pudo cargar el pedido',
                  message:
                      'Ocurrió un problema leyendo el detalle desde la base local.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              final pedido = snapshot.data;
              if (pedido == null) {
                return _PedidoDetalleError(
                  title: 'Pedido no encontrado',
                  message:
                      'El pedido seleccionado ya no existe en la base local.',
                  onClose: () => Navigator.of(context).pop(),
                );
              }
              return _PedidoDetalleContent(
                pedido: pedido,
                tabController: _tabController,
                onEditar: () => Navigator.of(
                  context,
                ).pop(PedidoDetalleDialogAction.editar),
                onVerCliente: () => Navigator.of(
                  context,
                ).pop(PedidoDetalleDialogAction.verCliente),
                onAbrirCotizacion: _abrirCotizacion,
                onClose: () => Navigator.of(context).pop(),
              );
            },
          ),
        );
      },
    ),
  );
}'''
detail_dialog = replace_once(
    detail_dialog,
    "import '../widgets/pedido_estado_badge.dart';",
    "import 'generar_cotizacion_dialog.dart';\n"
    "import '../widgets/pedido_estado_badge.dart';",
    "import del editor de cotización",
)
detail_dialog = replace_once(
    detail_dialog,
    "enum PedidoDetalleDialogAction { editar, cotizacion, cambiarEstado, verCliente }",
    "enum PedidoDetalleDialogAction { editar, verCliente }",
    "acciones públicas del detalle",
)
detail_dialog = replace_between(
    detail_dialog,
    "class _PedidoDetalleDialogState extends State<PedidoDetalleDialog>",
    "class _PedidoDetalleContent extends StatelessWidget {",
    detail_state,
    "estado del detalle de pedido",
)

detail_content = r'''class _PedidoDetalleContent extends StatelessWidget {
  const _PedidoDetalleContent({
    required this.pedido,
    required this.tabController,
    required this.onEditar,
    required this.onVerCliente,
    required this.onAbrirCotizacion,
    required this.onClose,
  });

  static const primaryColor = Color(0xFFFFC500);
  static const darkColor = Color(0xFF1F1F1F);

  final PedidoDetalle pedido;
  final TabController tabController;
  final VoidCallback onEditar;
  final VoidCallback onVerCliente;
  final ValueChanged<String?> onAbrirCotizacion;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Header(pedido: pedido, onClose: onClose),
      TabBar(
        controller: tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Resumen'),
          Tab(text: 'Productos'),
          Tab(text: 'Entrega'),
          Tab(text: 'Cotización'),
          Tab(text: 'Historial'),
        ],
        labelColor: darkColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: tabController,
          children: [
            _ResumenTab(pedido: pedido, onVerCliente: onVerCliente),
            _ProductosTab(pedido: pedido),
            _EntregaTab(pedido: pedido),
            _CotizacionTab(
              pedido: pedido,
              onAbrirCotizacion: onAbrirCotizacion,
            ),
            _HistorialTab(historial: pedido.historial),
          ],
        ),
      ),
      _ActionsBar(
        onClose: onClose,
        onEditar: onEditar,
        puedeEditar:
            pedido.estadoNormalizado != 'cancelado' &&
            pedido.estadoNormalizado != 'entregado',
      ),
    ],
  );
}'''
detail_dialog = replace_between(
    detail_dialog,
    "class _PedidoDetalleContent extends StatelessWidget {",
    "class _Header extends StatelessWidget {",
    detail_content,
    "contenido del detalle de pedido",
)

quote_tab = r'''class _CotizacionTab extends StatelessWidget {
  const _CotizacionTab({
    required this.pedido,
    required this.onAbrirCotizacion,
  });

  final PedidoDetalle pedido;
  final ValueChanged<String?> onAbrirCotizacion;

  @override
  Widget build(BuildContext context) {
    final cotizaciones = pedido.cotizaciones;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cotizaciones del pedido',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pulsa una versión para abrirla. Las generadas crean '
                      'una nueva versión al guardar.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF757575),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => onAbrirCotizacion(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva cotización'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC500),
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: cotizaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay cotizaciones guardadas',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  itemCount: cotizaciones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final quote = cotizaciones[index];
                    final path = quote.pdfPath;
                    final hasPdf =
                        path != null &&
                        path.isNotEmpty &&
                        File(path).existsSync();
                    return _CotizacionHistorialCard(
                      cotizacion: quote,
                      onTap: () => onAbrirCotizacion(quote.id),
                      onOpenPdf: hasPdf
                          ? () => _runFileAction(
                              context,
                              () => FileActionsService.openPdf(path),
                            )
                          : null,
                      onSharePdf: hasPdf
                          ? () => _runFileAction(
                              context,
                              () => FileActionsService.sharePdf(path),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _runFileAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      AppNotice.error(context, 'No se pudo abrir el PDF: $error');
    }
  }
}'''
detail_dialog = replace_between(
    detail_dialog,
    "class _CotizacionTab extends StatelessWidget {",
    "class _CotizacionHistorialCard extends StatelessWidget {",
    quote_tab,
    "pestaña de cotizaciones",
)

quote_card = r'''class _CotizacionHistorialCard extends StatelessWidget {
  const _CotizacionHistorialCard({
    required this.cotizacion,
    required this.onTap,
    this.onOpenPdf,
    this.onSharePdf,
  });

  final CotizacionPedidoGuardada cotizacion;
  final VoidCallback onTap;
  final VoidCallback? onOpenPdf;
  final VoidCallback? onSharePdf;

  @override
  Widget build(BuildContext context) {
    final statusColor = cotizacion.esBorrador
        ? Colors.orange
        : cotizacion.esGenerada
        ? Colors.green
        : Colors.blueGrey;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('abrir_cotizacion_${cotizacion.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3E3E3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC500).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cotizacion.esBorrador
                      ? Icons.edit_note_outlined
                      : Icons.description_outlined,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cotizacion.codigoVersion,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatFecha(cotizacion.creadoEn)} • '
                      'S/ ${cotizacion.total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF757575),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpenPdf != null)
                IconButton(
                  tooltip: 'Ver PDF',
                  onPressed: onOpenPdf,
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                ),
              if (onSharePdf != null)
                IconButton(
                  tooltip: 'Compartir PDF',
                  onPressed: onSharePdf,
                  icon: const Icon(Icons.share_outlined, size: 20),
                ),
              _Badge(label: cotizacion.estado, color: statusColor),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}'''
detail_dialog = replace_between(
    detail_dialog,
    "class _CotizacionHistorialCard extends StatelessWidget {",
    "class _HistorialTab extends StatelessWidget {",
    quote_card,
    "tarjeta de cotización",
)

actions_bar = r'''class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.onClose,
    required this.onEditar,
    required this.puedeEditar,
  });

  static const primaryColor = Color(0xFFFFC500);

  final VoidCallback onClose;
  final VoidCallback onEditar;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(24),
      ),
      border: const Border(top: BorderSide(color: Color(0xFFE1E5EA))),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClose,
              child: const Text('Cerrar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const Key('editar_pedido_desde_detalle'),
              onPressed: puedeEditar ? onEditar : null,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                puedeEditar
                    ? 'Editar pedido'
                    : 'Pedido no editable',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 46),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}'''
detail_dialog = replace_between(
    detail_dialog,
    "class _ActionsBar extends StatelessWidget {",
    "class _DialogActionButton extends StatelessWidget {",
    actions_bar,
    "barra inferior del detalle",
)

# Listado: edición se reserva para el pedido; cotización se maneja dentro del modal.
old_switch = r'''    switch (action) {
      case PedidoDetalleDialogAction.editar:
        await _mostrarCotizacionPedido(pedido, modoEdicion: true);
      case PedidoDetalleDialogAction.cotizacion:
        await _mostrarCotizacionPedido(pedido);
      case PedidoDetalleDialogAction.cambiarEstado:
        await _mostrarCambiarEstado(pedido);
      case PedidoDetalleDialogAction.verCliente:
        widget.onOpenCliente?.call(pedido.clienteId);
    }
'''
new_switch = r'''    switch (action) {
      case PedidoDetalleDialogAction.editar:
        await _editarPedido(pedido);
      case PedidoDetalleDialogAction.verCliente:
        widget.onOpenCliente?.call(pedido.clienteId);
    }
'''
list_view = replace_once(
    list_view,
    old_switch,
    new_switch,
    "acciones del detalle de pedido",
)
edit_method = r'''  Future<void> _editarPedido(PedidoResumen pedido) async {
    if (pedido.estadoNormalizado == 'cancelado') {
      AppNotice.warning(
        context,
        'Reactiva el pedido antes de editar sus productos.',
      );
      return;
    }
    if (pedido.estadoNormalizado == 'entregado') {
      AppNotice.warning(
        context,
        'Un pedido entregado no puede modificarse.',
      );
      return;
    }
    AppNotice.info(
      context,
      'La edición de productos se aplicará en la siguiente fase de esta corrección.',
    );
  }

'''
list_view = replace_once(
    list_view,
    "  Future<void> _mostrarCotizacionPedido(\n",
    edit_method + "  Future<void> _mostrarCotizacionPedido(\n",
    "navegación de edición de pedido",
)
list_view = replace_once(
    list_view,
    "          onCambiarEstado: () => _mostrarCambiarEstado(pedido),",
    "          onCambiarEstado: () => pedido.estadoNormalizado == 'cancelado'\n"
    "              ? _mostrarReactivarPedido(pedido)\n"
    "              : _mostrarCambiarEstado(pedido),",
    "acción contextual de estado",
)
list_view = replace_once(
    list_view,
    "            if (value == 'editar_precio') {\n"
    "              _mostrarCotizacionPedido(pedido, modoEdicion: true);\n"
    "              return;\n"
    "            }\n",
    "            if (value == 'editar_pedido') {\n"
    "              _editarPedido(pedido);\n"
    "              return;\n"
    "            }\n"
    "            if (value == 'reactivar') {\n"
    "              _mostrarReactivarPedido(pedido);\n"
    "              return;\n"
    "            }\n",
    "menú de edición y reactivación",
)
reactivate_ui = r'''  Future<void> _mostrarReactivarPedido(PedidoResumen pedido) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.restart_alt_rounded,
          color: Color(0xFF2E7D32),
        ),
        title: const Text('Reactivar pedido'),
        content: const Text(
          'El pedido volverá a Pendiente. Se conservarán sus productos, '
          'cotizaciones e historial, pero se limpiarán avances de '
          'preparación y carga.',
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
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.read<PedidosListadoBloc>().add(
      PedidosListadoPedidoReactivado(pedidoId: pedido.id),
    );
  }

'''
list_view = replace_once(
    list_view,
    "  Future<void> _mostrarCancelarPedido(PedidoResumen pedido) async {",
    reactivate_ui
    + "  Future<void> _mostrarCancelarPedido(PedidoResumen pedido) async {",
    "confirmación de reactivación",
)

# Tarjeta de pedido.
order_card = replace_once(
    order_card,
    "                        onPressed: pedido.estadoNormalizado == 'cancelado'\n"
    "                            ? null\n"
    "                            : onCambiarEstado,",
    "                        onPressed: onCambiarEstado,",
    "habilitar acción para cancelados",
)
order_card = replace_once(
    order_card,
    "                        style: OutlinedButton.styleFrom(\n"
    "                          foregroundColor: const Color(0xFF1F1F1F),",
    "                        style: OutlinedButton.styleFrom(\n"
    "                          foregroundColor:\n"
    "                              pedido.estadoNormalizado == 'cancelado'\n"
    "                              ? const Color(0xFF2E7D32)\n"
    "                              : const Color(0xFF1F1F1F),",
    "color de reactivación",
)
order_card = replace_once(
    order_card,
    "                        child: const Text('Cambiar estado'),",
    "                        child: Text(\n"
    "                          pedido.estadoNormalizado == 'cancelado'\n"
    "                              ? 'Reactivar pedido'\n"
    "                              : 'Cambiar estado',\n"
    "                        ),",
    "etiqueta de reactivación",
)
order_card = replace_once(
    order_card,
    "      const PopupMenuItem(value: 'editar_precio', child: Text('Editar precio')),",
    "      if (pedido.estadoNormalizado != 'cancelado' &&\n"
    "          pedido.estadoNormalizado != 'entregado')\n"
    "        const PopupMenuItem(\n"
    "          value: 'editar_pedido',\n"
    "          child: Text('Editar pedido'),\n"
    "        ),\n"
    "      if (pedido.estadoNormalizado == 'cancelado')\n"
    "        const PopupMenuItem(\n"
    "          value: 'reactivar',\n"
    "          child: Text('Reactivar pedido'),\n"
    "        ),",
    "menú contextual del pedido",
)

# Evento y BLoC de reactivación.
reactivate_event = r'''class PedidosListadoPedidoReactivado extends PedidosListadoEvent {
  const PedidosListadoPedidoReactivado({
    required this.pedidoId,
    this.observacion = '',
  });

  final String pedidoId;
  final String observacion;

  @override
  List<Object?> get props => [pedidoId, observacion];
}

'''
list_events = replace_once(
    list_events,
    "class PedidosListadoSincronizacionReintentada extends PedidosListadoEvent {",
    reactivate_event
    + "class PedidosListadoSincronizacionReintentada extends PedidosListadoEvent {",
    "evento de reactivación",
)
list_bloc = replace_once(
    list_bloc,
    "    on<PedidosListadoPedidoCancelado>(_cancelarPedido);\n",
    "    on<PedidosListadoPedidoCancelado>(_cancelarPedido);\n"
    "    on<PedidosListadoPedidoReactivado>(_reactivarPedido);\n",
    "handler de reactivación",
)
reactivate_bloc = r'''  Future<void> _reactivarPedido(
    PedidosListadoPedidoReactivado event,
    Emitter<PedidosListadoState> emit,
  ) async {
    emit(
      state.copyWith(
        actualizando: true,
        limpiarError: true,
        limpiarMessage: true,
      ),
    );
    try {
      await _repository.reactivarPedido(
        pedidoId: event.pedidoId,
        observacion: event.observacion,
      );
      final pedidos = await _repository.obtenerPedidosResumen();
      emit(
        state.copyWith(
          actualizando: false,
          pedidos: pedidos,
          message: 'Pedido reactivado correctamente.',
          limpiarError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          actualizando: false,
          error: 'No se pudo reactivar el pedido: $error',
          limpiarMessage: true,
        ),
      );
    }
  }

'''
list_bloc = replace_once(
    list_bloc,
    "  void _cambiarFiltroRapido(\n",
    reactivate_bloc + "  void _cambiarFiltroRapido(\n",
    "lógica de reactivación",
)

quote_test = r'''import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('distingue borrador, generada y archivada', () {
    final base = DateTime(2026, 8, 1);
    final draft = CotizacionPedidoGuardada(
      id: 'draft',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 100,
      creadoEn: base,
      estado: 'Borrador',
      vigenciaDias: 15,
      condiciones: 'Pago a 15 días',
      observaciones: 'Entrega coordinada',
      items: const [
        CotizacionPedidoItemGuardado(
          id: 'line',
          pedidoItemId: 'order-line',
          productoId: 'product',
          codigo: 'SKU',
          nombre: 'Producto',
          presentacion: 'Caja',
          cantidad: 2,
          precioCotizacion: 50,
          descuento: 0,
          tipoDescuento: 'monto',
          precioFinal: 50,
          subtotal: 100,
        ),
      ],
    );

    expect(draft.esBorrador, isTrue);
    expect(draft.esGenerada, isFalse);
    expect(draft.items.single.toDraft().pedidoItemId, 'order-line');
    expect(draft.vigenciaDias, 15);
    expect(draft.condiciones, 'Pago a 15 días');

    final generated = draft.copyWith(estado: 'Generada');
    expect(generated.esGenerada, isTrue);

    final archived = draft.copyWith(estado: 'Archivada');
    expect(archived.esArchivada, isTrue);
  });

  test('el código de versión se presenta sin duplicar el sufijo', () {
    final date = DateTime(2026);
    final first = CotizacionPedidoGuardada(
      id: '1',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 10,
      creadoEn: date,
    );
    final second = CotizacionPedidoGuardada(
      id: '2',
      pedidoId: 'order',
      codigo: 'COT-2026-0001',
      total: 10,
      creadoEn: date,
      version: 2,
    );

    expect(first.codigoVersion, 'COT-2026-0001');
    expect(second.codigoVersion, 'COT-2026-0001-V2');
  });
}
'''

reactivate_test = r'''import 'package:app_catalogo/features/pedidos/domain/entities/pedido_resumen.dart';
import 'package:app_catalogo/features/pedidos/presentation/widgets/pedido_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un pedido cancelado ofrece reactivación', (tester) async {
    var called = false;
    final order = PedidoResumen(
      id: 'order',
      codigo: 'PED-2026-0001',
      fecha: DateTime(2026, 8, 1),
      estado: 'Cancelado',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'client',
      clienteNombre: 'Cliente de prueba',
      telefono: '999999999',
      direccion: 'Dirección',
      cantidadProductos: 1,
      cantidadPresentaciones: 1,
      productosResumen: const ['Producto'],
      subtotalConocido: 10,
      productosSinPrecio: 0,
      hojaCodigo: 'HP-2026-001',
      vendedor: 'Vendedor',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PedidoCard(
              pedido: order,
              onVerPedido: () {},
              onCambiarEstado: () => called = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Reactivar pedido'), findsOneWidget);
    await tester.tap(find.text('Reactivar pedido'));
    expect(called, isTrue);
    expect(tester.takeException(), isNull);
  });
}
'''

updates = {
    CARD: card,
    CATALOG_PAGE: catalog_page,
    NEW_ORDER_PAGE: new_order_page,
    QUOTE_ENTITY: "import 'package:equatable/equatable.dart';\n\nclass CotizacionIgv {\n  const CotizacionIgv._();\n\n  static const double tasa = 0.18;\n\n  static double totalSinIgv(double totalConIgv) {\n    if (totalConIgv <= 0) return 0;\n    return totalConIgv / (1 + tasa);\n  }\n\n  static double igvIncluido(double totalConIgv) =>\n      totalConIgv <= 0 ? 0 : totalConIgv - totalSinIgv(totalConIgv);\n}\n\nclass CotizacionCalculo {\n  const CotizacionCalculo._();\n\n  static double totalConDescuentos({\n    required double subtotalProductos,\n    required double descuentosProductos,\n    required double descuentoGeneral,\n  }) {\n    final subtotal = subtotalProductos < 0 ? 0 : subtotalProductos;\n    final descuentos = descuentosProductos < 0 ? 0 : descuentosProductos;\n    final general = descuentoGeneral < 0 ? 0 : descuentoGeneral;\n    return (subtotal - descuentos - general)\n        .clamp(0, double.infinity)\n        .toDouble();\n  }\n}\n\nclass CotizacionCodigo {\n  const CotizacionCodigo._();\n\n  static String siguiente({\n    required int year,\n    required Iterable<String?> codigosExistentes,\n  }) {\n    final pattern = RegExp('^COT-$year-(\\\\d+)');\n    var mayor = 0;\n    for (final codigo in codigosExistentes) {\n      if (codigo == null) continue;\n      final match = pattern.firstMatch(codigo.trim().toUpperCase());\n      final numero = int.tryParse(match?.group(1) ?? '');\n      if (numero != null && numero > mayor) mayor = numero;\n    }\n    return 'COT-$year-${(mayor + 1).toString().padLeft(4, '0')}';\n  }\n}\n\nclass CotizacionPedidoDraft extends Equatable {\n  const CotizacionPedidoDraft({\n    required this.pedidoId,\n    required this.items,\n    required this.subtotal,\n    required this.descuentoGlobal,\n    required this.tipoDescuentoGlobal,\n    required this.total,\n    required this.vigenciaDias,\n    required this.condiciones,\n    required this.observaciones,\n    this.descuentoGlobalPorcentaje = 0,\n    this.descuentoGlobalMonto = 0,\n    this.estado = 'Generada',\n  });\n\n  final String pedidoId;\n  final List<CotizacionPedidoItemDraft> items;\n  final double subtotal;\n  final double descuentoGlobal;\n  final String tipoDescuentoGlobal;\n  final double total;\n  final int vigenciaDias;\n  final String condiciones;\n  final String observaciones;\n  final double descuentoGlobalPorcentaje;\n  final double descuentoGlobalMonto;\n  final String estado;\n\n  @override\n  List<Object?> get props => [\n    pedidoId,\n    items,\n    subtotal,\n    descuentoGlobal,\n    tipoDescuentoGlobal,\n    total,\n    vigenciaDias,\n    condiciones,\n    observaciones,\n    descuentoGlobalPorcentaje,\n    descuentoGlobalMonto,\n    estado,\n  ];\n}\n\nclass CotizacionPedidoItemDraft extends Equatable {\n  const CotizacionPedidoItemDraft({\n    required this.pedidoItemId,\n    required this.productoId,\n    required this.codigo,\n    required this.nombre,\n    required this.presentacion,\n    required this.cantidad,\n    required this.precioCotizacion,\n    required this.descuento,\n    required this.tipoDescuento,\n    required this.precioFinal,\n    required this.subtotal,\n  });\n\n  final String pedidoItemId;\n  final String productoId;\n  final String codigo;\n  final String nombre;\n  final String presentacion;\n  final int cantidad;\n  final double precioCotizacion;\n  final double descuento;\n  final String tipoDescuento;\n  final double precioFinal;\n  final double subtotal;\n\n  @override\n  List<Object?> get props => [\n    pedidoItemId,\n    productoId,\n    codigo,\n    nombre,\n    presentacion,\n    cantidad,\n    precioCotizacion,\n    descuento,\n    tipoDescuento,\n    precioFinal,\n    subtotal,\n  ];\n}\n\nclass CotizacionPedidoItemGuardado extends Equatable {\n  const CotizacionPedidoItemGuardado({\n    required this.id,\n    required this.pedidoItemId,\n    required this.productoId,\n    required this.codigo,\n    required this.nombre,\n    required this.presentacion,\n    required this.cantidad,\n    required this.precioCotizacion,\n    required this.descuento,\n    required this.tipoDescuento,\n    required this.precioFinal,\n    required this.subtotal,\n  });\n\n  final String id;\n  final String pedidoItemId;\n  final String productoId;\n  final String codigo;\n  final String nombre;\n  final String presentacion;\n  final int cantidad;\n  final double precioCotizacion;\n  final double descuento;\n  final String tipoDescuento;\n  final double precioFinal;\n  final double subtotal;\n\n  CotizacionPedidoItemDraft toDraft() => CotizacionPedidoItemDraft(\n    pedidoItemId: pedidoItemId,\n    productoId: productoId,\n    codigo: codigo,\n    nombre: nombre,\n    presentacion: presentacion,\n    cantidad: cantidad,\n    precioCotizacion: precioCotizacion,\n    descuento: descuento,\n    tipoDescuento: tipoDescuento,\n    precioFinal: precioFinal,\n    subtotal: subtotal,\n  );\n\n  @override\n  List<Object?> get props => [\n    id,\n    pedidoItemId,\n    productoId,\n    codigo,\n    nombre,\n    presentacion,\n    cantidad,\n    precioCotizacion,\n    descuento,\n    tipoDescuento,\n    precioFinal,\n    subtotal,\n  ];\n}\n\nclass CotizacionPedidoGuardada extends Equatable {\n  const CotizacionPedidoGuardada({\n    required this.id,\n    required this.pedidoId,\n    required this.codigo,\n    required this.total,\n    required this.creadoEn,\n    this.pdfPath,\n    this.version = 1,\n    this.estado = 'Generada',\n    this.subtotalProductos = 0,\n    this.descuento = 0,\n    this.totalSinIgv = 0,\n    this.igv = 0,\n    this.vigenciaDias = 7,\n    this.condiciones = '',\n    this.observaciones = '',\n    this.descuentoGlobalPorcentaje = 0,\n    this.descuentoGlobalMonto = 0,\n    this.items = const [],\n  });\n\n  final String id;\n  final String pedidoId;\n  final String codigo;\n  final double total;\n  final DateTime creadoEn;\n  final String? pdfPath;\n  final int version;\n  final String estado;\n  final double subtotalProductos;\n  final double descuento;\n  final double totalSinIgv;\n  final double igv;\n  final int vigenciaDias;\n  final String condiciones;\n  final String observaciones;\n  final double descuentoGlobalPorcentaje;\n  final double descuentoGlobalMonto;\n  final List<CotizacionPedidoItemGuardado> items;\n\n  bool get esBorrador => estado.trim().toLowerCase() == 'borrador';\n  bool get esGenerada => estado.trim().toLowerCase() == 'generada';\n  bool get esArchivada => estado.trim().toLowerCase() == 'archivada';\n\n  String get codigoVersion =>\n      version <= 1 || codigo.toUpperCase().endsWith('-V$version')\n      ? codigo\n      : '$codigo-V$version';\n\n  CotizacionPedidoGuardada copyWith({\n    String? pdfPath,\n    String? estado,\n    List<CotizacionPedidoItemGuardado>? items,\n  }) => CotizacionPedidoGuardada(\n    id: id,\n    pedidoId: pedidoId,\n    codigo: codigo,\n    total: total,\n    creadoEn: creadoEn,\n    pdfPath: pdfPath ?? this.pdfPath,\n    version: version,\n    estado: estado ?? this.estado,\n    subtotalProductos: subtotalProductos,\n    descuento: descuento,\n    totalSinIgv: totalSinIgv,\n    igv: igv,\n    vigenciaDias: vigenciaDias,\n    condiciones: condiciones,\n    observaciones: observaciones,\n    descuentoGlobalPorcentaje: descuentoGlobalPorcentaje,\n    descuentoGlobalMonto: descuentoGlobalMonto,\n    items: items ?? this.items,\n  );\n\n  @override\n  List<Object?> get props => [\n    id,\n    pedidoId,\n    codigo,\n    total,\n    creadoEn,\n    pdfPath,\n    version,\n    estado,\n    subtotalProductos,\n    descuento,\n    totalSinIgv,\n    igv,\n    vigenciaDias,\n    condiciones,\n    observaciones,\n    descuentoGlobalPorcentaje,\n    descuentoGlobalMonto,\n    items,\n  ];\n}\n",
    REPOSITORY: "import '../entities/cotizacion_pedido.dart';\nimport '../entities/pedido.dart';\nimport '../entities/pedido_detalle.dart';\nimport '../entities/pedido_preparacion.dart';\nimport '../entities/pedido_resumen.dart';\nimport '../entities/producto_consolidado.dart';\nimport '../entities/resumen_hoy.dart';\n\nabstract class PedidosRepository {\n  Future<HojaPedidoActiva?> obtenerHojaActiva();\n  Future<ResumenHoy> obtenerResumenHoy() async => const ResumenHoy(\n    vendedorNombre: 'Usuario',\n    pedidosPendientes: 0,\n    pedidosEnProceso: 0,\n    pedidosListos: 0,\n    pedidosEntregados: 0,\n    productosSinPrecio: 0,\n    cambiosSinSincronizar: 0,\n  );\n  Future<HojaPedidoActiva> crearHojaActiva();\n  Future<List<PedidoResumen>> obtenerPedidosResumen();\n  Future<PedidoDetalle?> obtenerPedidoDetalle(String id);\n  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async => null;\n  Future<CotizacionPedidoGuardada> guardarCotizacion(\n    CotizacionPedidoDraft cotizacion,\n  );\n  Future<CotizacionPedidoGuardada> actualizarCotizacion({\n    required String cotizacionId,\n    required CotizacionPedidoDraft cotizacion,\n  }) => guardarCotizacion(cotizacion);\n  Future<void> registrarPdfCotizacion({\n    required String cotizacionId,\n    required String pdfPath,\n  });\n  Future<List<ProductoConsolidado>> obtenerProductosConsolidados();\n  Future<void> registrarPreparacionProducto(\n    PreparacionProductoDraft preparacion,\n  );\n  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion();\n  Future<void> cambiarEstadoPedido({\n    required String pedidoId,\n    required String nuevoEstado,\n    String observacion = '',\n  });\n  Future<void> cancelarPedido({\n    required String pedidoId,\n    required String motivo,\n  });\n  Future<void> reactivarPedido({\n    required String pedidoId,\n    String observacion = '',\n  }) => cambiarEstadoPedido(\n    pedidoId: pedidoId,\n    nuevoEstado: 'Pendiente',\n    observacion: observacion,\n  );\n  Future<void> reintentarSincronizacionPedido(String pedidoId);\n  Future<void> marcarPedidoCargado({\n    required String pedidoId,\n    required int paquetes,\n    String observacion = '',\n  });\n  Future<List<ClientePedido>> buscarClientes(String query);\n  Future<PedidoRegistrado> guardarPedido({\n    required HojaPedidoActiva hoja,\n    required ClientePedido cliente,\n    required List<PedidoItem> items,\n    required String vendedor,\n  });\n}\n",
    REPOSITORY_IMPL: repo_impl,
    DATASOURCE: datasource,
    QUOTE_DIALOG: quote_dialog,
    DETAIL_DIALOG: detail_dialog,
    LIST_VIEW: list_view,
    ORDER_CARD: order_card,
    LIST_EVENTS: list_events,
    LIST_BLOC: list_bloc,
    CARD_TEST: card_test,
    QUOTE_TEST: quote_test,
    REACTIVATE_TEST: reactivate_test,
}

for path, content in updates.items():
    if not content.strip():
        fail(f"El resultado de {path.relative_to(ROOT)} está vacío.")
    if "Total de cotización — incluye IGV" in content:
        fail(
            f"La frase redundante permanece en {path.relative_to(ROOT)}."
        )

backup_dir = ROOT / (
    ".backup_cotizaciones_detalle_reactivacion_v2_"
    + datetime.now().strftime("%Y%m%d_%H%M%S")
)
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    if path.exists():
        target = backup_dir / path.relative_to(ROOT)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)

for path, content in updates.items():
    existed = path.exists()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(
        f"{'Modificado' if existed else 'Creado'}: "
        f"{path.relative_to(ROOT)}"
    )

print(f"\nRespaldo: {backup_dir}")
print("\nAplicada la fase v2 de tarjetas, cotizaciones, detalle y reactivación.")
print("No se modificó app_catalogo.db ni la versión de SQLite.")
print("\nEjecuta después de confirmar esta salida:")
print("  dart format lib test")
print("  flutter test test/producto_card_layout_test.dart")
print("  flutter test test/cotizacion_edicion_test.dart")
print("  flutter test test/cotizacion_flujo_test.dart")
print("  flutter test test/pedido_card_reactivar_test.dart")
print("  flutter test test/pedidos_bloc_test.dart")
print("  flutter analyze")