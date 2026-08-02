import 'package:equatable/equatable.dart';

class HojaPedidoActiva extends Equatable {
  const HojaPedidoActiva({
    required this.id,
    required this.codigo,
    required this.estado,
  });

  final String id;
  final String codigo;
  final String estado;

  @override
  List<Object?> get props => [id, codigo, estado];
}

class ClientePedido extends Equatable {
  const ClientePedido({
    this.id,
    required this.nombre,
    required this.telefono,
    this.dni = '',
    this.ruc = '',
    this.tipoEntrega = 'entrega',
    this.direccion = '',
    this.referencia = '',
    this.fotoUbicacionPath,
    this.observaciones = '',
  });

  final String? id;
  final String nombre;
  final String telefono;
  final String dni;
  final String ruc;
  final String tipoEntrega;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final String observaciones;

  bool get requiereDireccion => true;

  @override
  List<Object?> get props => [
    id,
    nombre,
    telefono,
    dni,
    ruc,
    tipoEntrega,
    direccion,
    referencia,
    fotoUbicacionPath,
    observaciones,
  ];
}

class PedidoPrecioRango extends Equatable {
  const PedidoPrecioRango({
    required this.desde,
    required this.precio,
    this.hasta,
  });

  final double desde;
  final double? hasta;
  final double precio;

  bool aplica(int cantidad) =>
      cantidad >= desde && (hasta == null || cantidad <= hasta!);

  @override
  List<Object?> get props => [desde, hasta, precio];
}

class PresentacionPedidoOpcion extends Equatable {
  const PresentacionPedidoOpcion({
    required this.nombre,
    required this.equivalencia,
    required this.precio,
    this.id = '',
    this.equivalenteA = 1,
    this.unidadBase = 'UND',
    this.pedidoMinimo = 1,
    this.incremento = 1,
    this.listaPrecioId = '',
    this.listaPrecioNombre = '',
    this.configuracionPrecio = 'precio_fijo',
    this.rangos = const [],
  });

  final String id;
  final String nombre;
  final String equivalencia;
  final double equivalenteA;
  final String unidadBase;
  final int pedidoMinimo;
  final int incremento;
  final String listaPrecioId;
  final String listaPrecioNombre;
  final String configuracionPrecio;
  final double? precio;
  final List<PedidoPrecioRango> rangos;

  double? precioPara(int cantidad) {
    if (configuracionPrecio == 'por_cotizar') return null;
    if (configuracionPrecio == 'por_cantidad') {
      for (final rango in rangos) {
        if (rango.aplica(cantidad)) return rango.precio;
      }
      return null;
    }
    return precio;
  }

  bool cantidadValida(int cantidad) {
    if (cantidad < pedidoMinimo) return false;
    final paso = incremento <= 0 ? 1 : incremento;
    return (cantidad - pedidoMinimo) % paso == 0;
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    equivalencia,
    equivalenteA,
    unidadBase,
    pedidoMinimo,
    incremento,
    listaPrecioId,
    listaPrecioNombre,
    configuracionPrecio,
    precio,
    rangos,
  ];
}

class PedidoItem extends Equatable {
  const PedidoItem({
    this.pedidoItemId = '',
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.presentacion,
    required this.equivalencia,
    required this.cantidad,
    required this.precioUnitario,
    this.varianteId = '',
    this.varianteSku = '',
    this.varianteNombre = '',
    this.atributosVariante = const {},
    this.presentacionId = '',
    this.precioListaId = '',
    this.precioListaNombre = '',
    this.precioConfiguracion = 'precio_fijo',
    this.opciones = const [],
    this.imagenPath,
  });

  final String pedidoItemId;
  final String productoId;
  final String codigo;
  final String nombre;
  final String varianteId;
  final String varianteSku;
  final String varianteNombre;
  final Map<String, String> atributosVariante;
  final String presentacionId;
  final String presentacion;
  final String equivalencia;
  final int cantidad;
  final double? precioUnitario;
  final String precioListaId;
  final String precioListaNombre;
  final String precioConfiguracion;
  final List<PresentacionPedidoOpcion> opciones;
  final String? imagenPath;

  double? get subtotal =>
      precioUnitario == null ? null : precioUnitario! * cantidad;

  String get claveCarrito {
    final variante = varianteId.isEmpty ? productoId : varianteId;
    final presentation = presentacionId.isEmpty
        ? presentacion.trim().toLowerCase()
        : presentacionId;
    final list = precioListaId.isEmpty ? 'legacy' : precioListaId;
    return '$productoId::$variante::$presentation::$list';
  }

  String get varianteEtiqueta {
    if (varianteNombre.isNotEmpty) return varianteNombre;
    if (varianteSku.isNotEmpty) return varianteSku;
    return 'Estándar';
  }

  PresentacionPedidoOpcion? get opcionSeleccionada {
    for (final option in opciones) {
      if (presentacionId.isNotEmpty && option.id == presentacionId) {
        return option;
      }
      if (option.nombre == presentacion) return option;
    }
    return null;
  }

  PedidoItem copyWith({
    String? pedidoItemId,
    String? presentacionId,
    String? presentacion,
    String? equivalencia,
    int? cantidad,
    double? precioUnitario,
    bool limpiarPrecio = false,
    String? precioListaId,
    String? precioListaNombre,
    String? precioConfiguracion,
    List<PresentacionPedidoOpcion>? opciones,
  }) => PedidoItem(
    pedidoItemId: pedidoItemId ?? this.pedidoItemId,
    productoId: productoId,
    codigo: codigo,
    nombre: nombre,
    varianteId: varianteId,
    varianteSku: varianteSku,
    varianteNombre: varianteNombre,
    atributosVariante: atributosVariante,
    presentacionId: presentacionId ?? this.presentacionId,
    presentacion: presentacion ?? this.presentacion,
    equivalencia: equivalencia ?? this.equivalencia,
    cantidad: cantidad ?? this.cantidad,
    precioUnitario: limpiarPrecio
        ? null
        : precioUnitario ?? this.precioUnitario,
    precioListaId: precioListaId ?? this.precioListaId,
    precioListaNombre: precioListaNombre ?? this.precioListaNombre,
    precioConfiguracion: precioConfiguracion ?? this.precioConfiguracion,
    opciones: opciones ?? this.opciones,
    imagenPath: imagenPath,
  );

  @override
  List<Object?> get props => [
    pedidoItemId,
    productoId,
    codigo,
    nombre,
    varianteId,
    varianteSku,
    varianteNombre,
    atributosVariante,
    presentacionId,
    presentacion,
    equivalencia,
    cantidad,
    precioUnitario,
    precioListaId,
    precioListaNombre,
    precioConfiguracion,
    opciones,
    imagenPath,
  ];
}

class PedidoRegistrado extends Equatable {
  const PedidoRegistrado({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.hojaCodigo,
    required this.estado,
  });

  final String id;
  final String codigo;
  final String cliente;
  final String hojaCodigo;
  final String estado;

  @override
  List<Object?> get props => [id, codigo, cliente, hojaCodigo, estado];
}
