part of '../pedidos_local_datasource.dart';

extension _PreparacionMapping on PedidosLocalDatasource {
  int _clampPreparada(int preparada, int solicitada) {
    if (preparada < 0) return 0;
    if (preparada > solicitada) return solicitada;
    return preparada;
  }

  Future<void> _validarAsignacionesCompletas(
    Transaction txn,
    List<PreparacionProductoAsignacion> asignaciones,
  ) async {
    final grupos = <String, List<PreparacionProductoAsignacion>>{};
    for (final asignacion in asignaciones) {
      final key = '${asignacion.pedidoId}|${asignacion.productoId}';
      grupos.putIfAbsent(key, () => []).add(asignacion);
    }

    for (final grupo in grupos.values) {
      final referencia = grupo.first;
      final rows = await txn.rawQuery(
        '''
        SELECT i.id,
               i.cantidad,
               i.factor_unidad_base,
               COALESCE(SUM(pp.cantidad_base), 0) AS preparada
        FROM pedido_items i
        LEFT JOIN preparacion_productos pp ON pp.pedido_item_id = i.id
        WHERE i.pedido_id = ?
          AND i.producto_id = ?
          AND i.activo = 1
        GROUP BY i.id
        ''',
        [referencia.pedidoId, referencia.productoId],
      );
      final porItem = {
        for (final asignacion in grupo)
          asignacion.pedidoItemId: asignacion.cantidad,
      };
      for (final row in rows) {
        final solicitada = row['cantidad'] as int? ?? 0;
        final factor = row['factor_unidad_base'] as int? ?? 1;
        final preparadaBase = (row['preparada'] as num? ?? 0).toInt();
        final preparadaPresentaciones = factor <= 0
            ? 0
            : (preparadaBase ~/ factor).clamp(0, solicitada);
        final pendiente = solicitada - preparadaPresentaciones;
        if (pendiente <= 0) continue;
        final asignada = porItem[row['id'] as String] ?? 0;
        if (asignada != pendiente) {
          throw StateError(
            'Para clasificar un pedido deben completarse todas las '
            'presentaciones pendientes del producto.',
          );
        }
      }
    }
  }

  Map<String, String> _stringMapFromJson(String? raw) {
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

  String _varianteFromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Producto único';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return 'Producto único';
      final valores = decoded.entries
          .where((entry) => entry.value.toString().trim().isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList();
      return valores.isEmpty ? 'Producto único' : valores.join(' • ');
    } catch (_) {
      return 'Producto único';
    }
  }

  int _factorUnidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toLowerCase();
    final coincidencias = RegExp(r'(\d+)').allMatches(equivalencia).toList();
    final numero = coincidencias.isEmpty ? null : coincidencias.last.group(1);
    final parsed = int.tryParse(numero ?? '');
    if (parsed != null && parsed > 0) return parsed;
    if (texto.contains('millar')) return 1000;
    if (texto.contains('ciento')) return 100;
    if (texto.contains('docena')) return 12;
    if (texto.contains('par')) return 2;
    return 1;
  }

  String _unidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toUpperCase();
    if (texto.contains('KG')) return 'KG';
    if (texto.contains('LT') || texto.contains('LITRO')) return 'LT';
    if (texto.contains('MT') || texto.contains('METRO')) return 'MT';
    return 'UND';
  }
}
