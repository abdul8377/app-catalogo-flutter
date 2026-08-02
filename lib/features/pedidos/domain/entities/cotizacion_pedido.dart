import 'package:equatable/equatable.dart';

class CotizacionIgv {
  const CotizacionIgv._();

  static const double tasa = 0.18;

  static double totalSinIgv(double totalConIgv) {
    if (totalConIgv <= 0) return 0;
    return totalConIgv / (1 + tasa);
  }

  static double igvIncluido(double totalConIgv) =>
      totalConIgv <= 0 ? 0 : totalConIgv - totalSinIgv(totalConIgv);
}

class CotizacionCalculo {
  const CotizacionCalculo._();

  static double totalConDescuentos({
    required double subtotalProductos,
    required double descuentosProductos,
    required double descuentoGeneral,
  }) {
    final subtotal = subtotalProductos < 0 ? 0 : subtotalProductos;
    final descuentos = descuentosProductos < 0 ? 0 : descuentosProductos;
    final general = descuentoGeneral < 0 ? 0 : descuentoGeneral;
    return (subtotal - descuentos - general)
        .clamp(0, double.infinity)
        .toDouble();
  }
}

class CotizacionCodigo {
  const CotizacionCodigo._();

  static String siguiente({
    required int year,
    required Iterable<String?> codigosExistentes,
  }) {
    final pattern = RegExp('^COT-$year-(\\d+)');
    var mayor = 0;
    for (final codigo in codigosExistentes) {
      if (codigo == null) continue;
      final match = pattern.firstMatch(codigo.trim().toUpperCase());
      final numero = int.tryParse(match?.group(1) ?? '');
      if (numero != null && numero > mayor) mayor = numero;
    }
    return 'COT-$year-${(mayor + 1).toString().padLeft(4, '0')}';
  }
}

class CotizacionPedidoDraft extends Equatable {
  const CotizacionPedidoDraft({
    required this.pedidoId,
    required this.items,
    required this.subtotal,
    required this.descuentoGlobal,
    required this.tipoDescuentoGlobal,
    required this.total,
    required this.vigenciaDias,
    required this.condiciones,
    required this.observaciones,
    this.descuentoGlobalPorcentaje = 0,
    this.descuentoGlobalMonto = 0,
    this.estado = 'Generada',
  });

  final String pedidoId;
  final List<CotizacionPedidoItemDraft> items;
  final double subtotal;
  final double descuentoGlobal;
  final String tipoDescuentoGlobal;
  final double total;
  final int vigenciaDias;
  final String condiciones;
  final String observaciones;
  final double descuentoGlobalPorcentaje;
  final double descuentoGlobalMonto;
  final String estado;

  @override
  List<Object?> get props => [
    pedidoId,
    items,
    subtotal,
    descuentoGlobal,
    tipoDescuentoGlobal,
    total,
    vigenciaDias,
    condiciones,
    observaciones,
    descuentoGlobalPorcentaje,
    descuentoGlobalMonto,
    estado,
  ];
}

class CotizacionPedidoItemDraft extends Equatable {
  const CotizacionPedidoItemDraft({
    required this.pedidoItemId,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.cantidad,
    required this.precioCotizacion,
    required this.descuento,
    required this.tipoDescuento,
    required this.precioFinal,
    required this.subtotal,
  });

  final String pedidoItemId;
  final String productoId;
  final String codigo;
  final String nombre;
  final String presentacion;
  final int cantidad;
  final double precioCotizacion;
  final double descuento;
  final String tipoDescuento;
  final double precioFinal;
  final double subtotal;

  @override
  List<Object?> get props => [
    pedidoItemId,
    productoId,
    codigo,
    nombre,
    presentacion,
    cantidad,
    precioCotizacion,
    descuento,
    tipoDescuento,
    precioFinal,
    subtotal,
  ];
}

class CotizacionPedidoItemGuardado extends Equatable {
  const CotizacionPedidoItemGuardado({
    required this.id,
    required this.pedidoItemId,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.cantidad,
    required this.precioCotizacion,
    required this.descuento,
    required this.tipoDescuento,
    required this.precioFinal,
    required this.subtotal,
  });

  final String id;
  final String pedidoItemId;
  final String productoId;
  final String codigo;
  final String nombre;
  final String presentacion;
  final int cantidad;
  final double precioCotizacion;
  final double descuento;
  final String tipoDescuento;
  final double precioFinal;
  final double subtotal;

  CotizacionPedidoItemDraft toDraft() => CotizacionPedidoItemDraft(
    pedidoItemId: pedidoItemId,
    productoId: productoId,
    codigo: codigo,
    nombre: nombre,
    presentacion: presentacion,
    cantidad: cantidad,
    precioCotizacion: precioCotizacion,
    descuento: descuento,
    tipoDescuento: tipoDescuento,
    precioFinal: precioFinal,
    subtotal: subtotal,
  );

  @override
  List<Object?> get props => [
    id,
    pedidoItemId,
    productoId,
    codigo,
    nombre,
    presentacion,
    cantidad,
    precioCotizacion,
    descuento,
    tipoDescuento,
    precioFinal,
    subtotal,
  ];
}

class CotizacionPedidoGuardada extends Equatable {
  const CotizacionPedidoGuardada({
    required this.id,
    required this.pedidoId,
    required this.codigo,
    required this.total,
    required this.creadoEn,
    this.pdfPath,
    this.version = 1,
    this.estado = 'Generada',
    this.subtotalProductos = 0,
    this.descuento = 0,
    this.totalSinIgv = 0,
    this.igv = 0,
    this.vigenciaDias = 7,
    this.condiciones = '',
    this.observaciones = '',
    this.descuentoGlobalPorcentaje = 0,
    this.descuentoGlobalMonto = 0,
    this.items = const [],
  });

  final String id;
  final String pedidoId;
  final String codigo;
  final double total;
  final DateTime creadoEn;
  final String? pdfPath;
  final int version;
  final String estado;
  final double subtotalProductos;
  final double descuento;
  final double totalSinIgv;
  final double igv;
  final int vigenciaDias;
  final String condiciones;
  final String observaciones;
  final double descuentoGlobalPorcentaje;
  final double descuentoGlobalMonto;
  final List<CotizacionPedidoItemGuardado> items;

  bool get esBorrador => estado.trim().toLowerCase() == 'borrador';
  bool get esGenerada => estado.trim().toLowerCase() == 'generada';
  bool get esArchivada => estado.trim().toLowerCase() == 'archivada';

  String get codigoVersion =>
      version <= 1 || codigo.toUpperCase().endsWith('-V$version')
      ? codigo
      : '$codigo-V$version';

  CotizacionPedidoGuardada copyWith({
    String? pdfPath,
    String? estado,
    List<CotizacionPedidoItemGuardado>? items,
  }) => CotizacionPedidoGuardada(
    id: id,
    pedidoId: pedidoId,
    codigo: codigo,
    total: total,
    creadoEn: creadoEn,
    pdfPath: pdfPath ?? this.pdfPath,
    version: version,
    estado: estado ?? this.estado,
    subtotalProductos: subtotalProductos,
    descuento: descuento,
    totalSinIgv: totalSinIgv,
    igv: igv,
    vigenciaDias: vigenciaDias,
    condiciones: condiciones,
    observaciones: observaciones,
    descuentoGlobalPorcentaje: descuentoGlobalPorcentaje,
    descuentoGlobalMonto: descuentoGlobalMonto,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => [
    id,
    pedidoId,
    codigo,
    total,
    creadoEn,
    pdfPath,
    version,
    estado,
    subtotalProductos,
    descuento,
    totalSinIgv,
    igv,
    vigenciaDias,
    condiciones,
    observaciones,
    descuentoGlobalPorcentaje,
    descuentoGlobalMonto,
    items,
  ];
}
