class ClienteLocalModel {
  const ClienteLocalModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.telefono,
    required this.dni,
    required this.ruc,
    required this.direccion,
    required this.referencia,
    required this.fotoUbicacionPath,
    required this.activo,
    required this.pedidosCount,
    required this.ultimoPedido,
    required this.observaciones,
    required this.fechaRegistro,
    required this.ultimaActualizacion,
  });

  factory ClienteLocalModel.fromRow(Map<String, Object?> row) {
    final creado = DateTime.tryParse(row['creado_en'] as String? ?? '');
    final actualizado = DateTime.tryParse(
      row['actualizado_en'] as String? ?? '',
    );
    final ultimoPedido = DateTime.tryParse(
      row['ultimo_pedido'] as String? ?? '',
    );
    final ruc = row['ruc'] as String? ?? '';

    return ClienteLocalModel(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      tipo: row['tipo'] as String? ?? (ruc.isEmpty ? 'Persona' : 'Empresa'),
      telefono: row['telefono'] as String,
      dni: row['dni'] as String? ?? '',
      ruc: ruc,
      direccion: row['direccion'] as String? ?? '',
      referencia: row['referencia'] as String? ?? '',
      fotoUbicacionPath: row['foto_ubicacion_path'] as String?,
      activo: (row['activo'] as int? ?? 1) == 1,
      pedidosCount: row['pedidos_count'] as int? ?? 0,
      ultimoPedido: ultimoPedido,
      observaciones: row['observaciones'] as String? ?? '',
      fechaRegistro: creado ?? DateTime.now(),
      ultimaActualizacion: actualizado,
    );
  }

  final String id;
  final String nombre;
  final String tipo;
  final String telefono;
  final String dni;
  final String ruc;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final bool activo;
  final int pedidosCount;
  final DateTime? ultimoPedido;
  final String observaciones;
  final DateTime fechaRegistro;
  final DateTime? ultimaActualizacion;
}
