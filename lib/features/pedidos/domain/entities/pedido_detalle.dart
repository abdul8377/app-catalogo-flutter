import 'package:equatable/equatable.dart';

import 'cotizacion_pedido.dart';

class PedidoDetalle extends Equatable {
  const PedidoDetalle({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.estado,
    required this.sincronizado,
    required this.guardadoLocal,
    required this.clienteId,
    required this.clienteNombre,
    required this.telefono,
    required this.direccion,
    required this.referencia,
    required this.productos,
    required this.subtotalConocido,
    required this.productosSinPrecio,
    required this.hoja,
    required this.vendedor,
    required this.estadoPreparacion,
    required this.estadoCarga,
    required this.historial,
    this.clienteDni = '',
    this.clienteRuc = '',
    this.fotoUbicacionPath,
    this.observacionesEntrega = '',
    this.descuentoGeneral = 0,
    this.cotizacionCodigo,
    this.cotizacionTotal,
    this.cotizaciones = const [],
    this.cotizacionVigente = false,
    this.subtotalProductos = 0,
    this.descuentosProductos = 0,
    this.descuentoGlobalCotizacion = 0,
    this.descuentoGlobalPorcentaje = 0,
    this.descuentoGlobalMonto = 0,
    this.totalSinIgv = 0,
    this.igv = 0,
    this.observacionesCotizacion = '',
    this.syncError,
  });

  final String id;
  final String codigo;
  final DateTime fecha;
  final String estado;
  final bool sincronizado;
  final bool guardadoLocal;
  final String clienteId;
  final String clienteNombre;
  final String telefono;
  final String clienteDni;
  final String clienteRuc;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final String observacionesEntrega;
  final List<PedidoDetalleProducto> productos;
  final double subtotalConocido;
  final double descuentoGeneral;
  final int productosSinPrecio;
  final String hoja;
  final String vendedor;
  final String? cotizacionCodigo;
  final double? cotizacionTotal;
  final List<CotizacionPedidoGuardada> cotizaciones;
  final bool cotizacionVigente;
  final double subtotalProductos;
  final double descuentosProductos;
  final double descuentoGlobalCotizacion;
  final double descuentoGlobalPorcentaje;
  final double descuentoGlobalMonto;
  final double totalSinIgv;
  final double igv;
  final String observacionesCotizacion;
  final String? syncError;
  final String estadoPreparacion;
  final String estadoCarga;
  final List<PedidoHistorialEntrada> historial;

  int get cantidadProductos => productos.length;

  int get cantidadPresentaciones =>
      {for (final producto in productos) producto.presentacion}.length;

  bool get totalParcial => !cotizacionVigente && productosSinPrecio > 0;

  double get totalFinal => cotizacionVigente
      ? (cotizacionTotal ?? 0)
      : subtotalConocido - descuentoGeneral;

  double get descuentoCotizado =>
      descuentosProductos + descuentoGlobalCotizacion;

  String get estadoNormalizado {
    final value = estado.trim().toLowerCase();
    if (value.contains('proceso')) return 'en_proceso';
    if (value.contains('listo')) return 'listo';
    if (value.contains('entregado')) return 'entregado';
    if (value.contains('cancelado')) return 'cancelado';
    return 'pendiente';
  }

  String get estadoLabel {
    switch (estadoNormalizado) {
      case 'en_proceso':
        return 'En proceso';
      case 'listo':
        return 'Listo para entregar';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }

  String get estadoPreparacionLabel {
    switch (estadoPreparacion) {
      case 'completa':
        return 'Completa';
      case 'parcial':
        return 'Parcial';
      default:
        return 'Pendiente';
    }
  }

  String get estadoCargaLabel =>
      estadoCarga == 'cargado' ? 'Cargado' : 'Pendiente';

  @override
  List<Object?> get props => [
    id,
    codigo,
    fecha,
    estado,
    sincronizado,
    guardadoLocal,
    clienteId,
    clienteNombre,
    telefono,
    clienteDni,
    clienteRuc,
    direccion,
    referencia,
    fotoUbicacionPath,
    observacionesEntrega,
    productos,
    subtotalConocido,
    descuentoGeneral,
    productosSinPrecio,
    hoja,
    vendedor,
    cotizacionCodigo,
    cotizacionTotal,
    cotizaciones,
    cotizacionVigente,
    subtotalProductos,
    descuentosProductos,
    descuentoGlobalCotizacion,
    descuentoGlobalPorcentaje,
    descuentoGlobalMonto,
    totalSinIgv,
    igv,
    observacionesCotizacion,
    syncError,
    estadoPreparacion,
    estadoCarga,
    historial,
  ];
}

class PedidoDetalleProducto extends Equatable {
  const PedidoDetalleProducto({
    required this.id,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.equivalencia,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.marca,
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
    this.tipoDescuentoCotizado = 'monto',
  });

  final String id;
  final String productoId;
  final String codigo;
  final String nombre;
  final String presentacion;
  final String equivalencia;
  final int cantidad;
  final double? precioUnitario;
  final double? subtotal;
  final String? marca;
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
  final String tipoDescuentoCotizado;

  bool get tienePrecio => precioUnitario != null;

  String get variante =>
      equivalencia.trim().isEmpty ? 'Estándar' : equivalencia;

  String get equivalenciaTotal {
    final matches = RegExp(r'(\d+(?:[.,]\d+)?)').allMatches(equivalencia);
    if (matches.isEmpty) return equivalencia;
    final factor = double.tryParse(matches.last.group(1)!.replaceAll(',', '.'));
    if (factor == null) return equivalencia;
    final total = factor * cantidad;
    final totalTexto = total == total.roundToDouble()
        ? total.toInt().toString()
        : total.toStringAsFixed(2);
    final upper = equivalencia.toUpperCase();
    final unidad = upper.contains('KG')
        ? 'kg'
        : upper.contains('LT') || upper.contains('LITRO')
        ? 'litros'
        : upper.contains('MT') || upper.contains('METRO')
        ? 'metros'
        : 'unidades';
    return '$totalTexto $unidad';
  }

  @override
  List<Object?> get props => [
    id,
    productoId,
    codigo,
    nombre,
    presentacion,
    equivalencia,
    cantidad,
    precioUnitario,
    subtotal,
    marca,
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
    tipoDescuentoCotizado,
  ];
}

class PedidoHistorialEntrada extends Equatable {
  const PedidoHistorialEntrada({
    required this.fecha,
    required this.evento,
    this.responsable,
  });

  final DateTime fecha;
  final String evento;
  final String? responsable;

  @override
  List<Object?> get props => [fecha, evento, responsable];
}
