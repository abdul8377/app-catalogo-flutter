import 'package:equatable/equatable.dart';

class ProductoConsolidado extends Equatable {
  const ProductoConsolidado({
    required this.key,
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.variante,
    required this.presentacion,
    required this.equivalencia,
    required this.totalRequerido,
    required this.totalPreparado,
    required this.distribucion,
    this.marca,
    this.empresa,
    this.categoria,
    this.subcategoria,
    this.imagenPath,
    this.unidadBase = 'UND',
    this.pendientePrecio = false,
    this.disponibles = const [],
  });

  final String key;
  final String productoId;
  final String codigo;
  final String nombre;
  final String? marca;
  final String? empresa;
  final String? categoria;
  final String? subcategoria;
  final String variante;
  final String presentacion;
  final String equivalencia;
  final String? imagenPath;
  final String unidadBase;
  final bool pendientePrecio;
  final int totalRequerido;
  final int totalPreparado;
  final List<DistribucionPedido> distribucion;
  final List<PreparacionDisponible> disponibles;

  int get pendiente => totalRequerido - totalPreparado;

  double get progreso =>
      totalRequerido == 0 ? 0 : totalPreparado / totalRequerido;

  int get cantidadPedidos =>
      {for (final item in distribucion) item.pedidoId}.length;

  int get cantidadClientes =>
      {for (final item in distribucion) item.cliente}.length;

  bool get completo => totalRequerido > 0 && totalPreparado >= totalRequerido;

  bool get parcial => totalPreparado > 0 && totalPreparado < totalRequerido;

  List<ResumenPresentacionConsolidada> get presentaciones {
    final grupos = <String, ResumenPresentacionConsolidada>{};
    for (final item in distribucion) {
      final key =
          '${item.presentacion.trim().toLowerCase()}|${item.factorUnidadBase}';
      final actual = grupos[key];
      grupos[key] = ResumenPresentacionConsolidada(
        presentacion: item.presentacion,
        equivalencia: item.equivalencia,
        factorUnidadBase: item.factorUnidadBase,
        solicitada: (actual?.solicitada ?? 0) + item.cantidadOriginal,
        preparada:
            (actual?.preparada ?? 0) + item.cantidadPreparadaPresentaciones,
      );
    }
    final values = grupos.values.toList()
      ..sort((a, b) => a.presentacion.compareTo(b.presentacion));
    return values;
  }

  int disponiblePara(ResumenPresentacionConsolidada presentacion) => disponibles
      .where(
        (item) =>
            item.presentacion.trim().toLowerCase() ==
                presentacion.presentacion.trim().toLowerCase() &&
            item.factorUnidadBase == presentacion.factorUnidadBase,
      )
      .fold(0, (total, item) => total + item.cantidad);

  String get equivalenciaTotalTexto =>
      '$totalRequerido ${unidadBaseTexto(totalRequerido, unidadBase)}';

  ProductoConsolidado conDistribucion(List<DistribucionPedido> items) =>
      ProductoConsolidado(
        key: key,
        productoId: productoId,
        codigo: codigo,
        nombre: nombre,
        marca: marca,
        empresa: empresa,
        categoria: categoria,
        subcategoria: subcategoria,
        variante: variante,
        presentacion: presentacion,
        equivalencia: equivalencia,
        imagenPath: imagenPath,
        unidadBase: unidadBase,
        pendientePrecio: items.any((item) => item.sinPrecio),
        totalRequerido: items.fold(
          0,
          (total, item) => total + item.cantidadSolicitada,
        ),
        totalPreparado: items.fold(
          0,
          (total, item) => total + item.cantidadPreparada,
        ),
        distribucion: items,
        disponibles: disponibles,
      );

  @override
  List<Object?> get props => [
    key,
    productoId,
    codigo,
    nombre,
    marca,
    empresa,
    categoria,
    subcategoria,
    variante,
    presentacion,
    equivalencia,
    imagenPath,
    unidadBase,
    pendientePrecio,
    totalRequerido,
    totalPreparado,
    distribucion,
    disponibles,
  ];
}

class ResumenPresentacionConsolidada extends Equatable {
  const ResumenPresentacionConsolidada({
    required this.presentacion,
    required this.equivalencia,
    required this.factorUnidadBase,
    required this.solicitada,
    required this.preparada,
  });

  final String presentacion;
  final String equivalencia;
  final int factorUnidadBase;
  final int solicitada;
  final int preparada;

  int get pendiente => (solicitada - preparada).clamp(0, solicitada);

  String get solicitadaTexto =>
      cantidadPresentacionTexto(solicitada, presentacion);

  String get preparadaTexto =>
      cantidadPresentacionTexto(preparada, presentacion);

  String get pendienteTexto =>
      cantidadPresentacionTexto(pendiente, presentacion);

  @override
  List<Object?> get props => [
    presentacion,
    equivalencia,
    factorUnidadBase,
    solicitada,
    preparada,
  ];
}

class PreparacionDisponible extends Equatable {
  const PreparacionDisponible({
    required this.presentacion,
    required this.equivalencia,
    required this.factorUnidadBase,
    required this.cantidad,
  });

  final String presentacion;
  final String equivalencia;
  final int factorUnidadBase;
  final int cantidad;

  @override
  List<Object?> get props => [
    presentacion,
    equivalencia,
    factorUnidadBase,
    cantidad,
  ];
}

class DistribucionPedido extends Equatable {
  const DistribucionPedido({
    required this.pedidoItemId,
    required this.pedidoId,
    required this.codigoPedido,
    required this.cliente,
    required this.telefono,
    required this.cantidadSolicitada,
    required this.cantidadPreparada,
    required this.fecha,
    required this.estadoPedido,
    this.hojaCodigo = '',
    this.clienteId = '',
    this.presentacion = 'Unidad',
    this.equivalencia = '1 UND',
    this.cantidadOriginal = 0,
    this.unidadBase = 'UND',
    this.sinPrecio = false,
  });

  final String pedidoItemId;
  final String pedidoId;
  final String codigoPedido;
  final String cliente;
  final String telefono;
  final int cantidadSolicitada;
  final int cantidadPreparada;
  final DateTime fecha;
  final String estadoPedido;
  final String hojaCodigo;
  final String clienteId;
  final String presentacion;
  final String equivalencia;
  final int cantidadOriginal;
  final String unidadBase;
  final bool sinPrecio;

  int get pendiente => cantidadSolicitada - cantidadPreparada;

  int get factorUnidadBase {
    if (cantidadOriginal > 0 && cantidadSolicitada > 0) {
      return (cantidadSolicitada / cantidadOriginal).round().clamp(
        1,
        cantidadSolicitada,
      );
    }
    final matches = RegExp(r'(\d+)').allMatches(equivalencia).toList();
    final ultimoValor = matches.isEmpty ? null : matches.last.group(1);
    return int.tryParse(ultimoValor ?? '') ?? 1;
  }

  int get cantidadPreparadaPresentaciones {
    if (cantidadOriginal <= 0) return 0;
    return (cantidadPreparada ~/ factorUnidadBase).clamp(0, cantidadOriginal);
  }

  int get cantidadPendientePresentaciones =>
      (cantidadOriginal - cantidadPreparadaPresentaciones).clamp(
        0,
        cantidadOriginal,
      );

  bool get completo =>
      cantidadSolicitada > 0 && cantidadPreparada >= cantidadSolicitada;

  String get cantidadOriginalTexto {
    return cantidadPresentacionTexto(cantidadOriginal, presentacion);
  }

  String get cantidadPreparadaTexto =>
      cantidadPresentacionTexto(cantidadPreparadaPresentaciones, presentacion);

  String get cantidadPendienteTexto =>
      cantidadPresentacionTexto(cantidadPendientePresentaciones, presentacion);

  String get equivalenciaSolicitadaTexto =>
      '$cantidadSolicitada ${unidadBaseTexto(cantidadSolicitada, unidadBase)}';

  String get equivalenciaPreparadaTexto =>
      '$cantidadPreparada ${unidadBaseTexto(cantidadPreparada, unidadBase)}';

  @override
  List<Object?> get props => [
    pedidoItemId,
    pedidoId,
    codigoPedido,
    cliente,
    telefono,
    cantidadSolicitada,
    cantidadPreparada,
    fecha,
    estadoPedido,
    hojaCodigo,
    clienteId,
    presentacion,
    equivalencia,
    cantidadOriginal,
    unidadBase,
    sinPrecio,
  ];
}

class PreparacionProductoDraft extends Equatable {
  const PreparacionProductoDraft({
    required this.productoKey,
    required this.asignaciones,
    this.observacion = '',
    this.movimientosDisponibles = const [],
    this.requierePedidosCompletos = false,
  });

  final String productoKey;
  final List<PreparacionProductoAsignacion> asignaciones;
  final String observacion;
  final List<PreparacionDisponibleMovimiento> movimientosDisponibles;
  final bool requierePedidosCompletos;

  int get totalPreparado =>
      asignaciones.fold(0, (sum, item) => sum + item.cantidad);

  @override
  List<Object?> get props => [
    productoKey,
    asignaciones,
    observacion,
    movimientosDisponibles,
    requierePedidosCompletos,
  ];
}

class PreparacionProductoAsignacion extends Equatable {
  const PreparacionProductoAsignacion({
    required this.pedidoItemId,
    required this.pedidoId,
    required this.productoId,
    required this.cantidad,
    this.presentacion = '',
    this.factorUnidadBase = 1,
  });

  final String pedidoItemId;
  final String pedidoId;
  final String productoId;
  final int cantidad;
  final String presentacion;
  final int factorUnidadBase;

  @override
  List<Object?> get props => [
    pedidoItemId,
    pedidoId,
    productoId,
    cantidad,
    presentacion,
    factorUnidadBase,
  ];
}

class PreparacionDisponibleMovimiento extends Equatable {
  const PreparacionDisponibleMovimiento({
    required this.productoId,
    required this.presentacion,
    required this.equivalencia,
    required this.factorUnidadBase,
    required this.cantidadDelta,
  });

  final String productoId;
  final String presentacion;
  final String equivalencia;
  final int factorUnidadBase;
  final int cantidadDelta;

  @override
  List<Object?> get props => [
    productoId,
    presentacion,
    equivalencia,
    factorUnidadBase,
    cantidadDelta,
  ];
}

String cantidadPresentacionTexto(int cantidad, String presentacion) {
  final limpia = presentacion.trim().isEmpty ? 'Unidad' : presentacion.trim();
  final lower = limpia.toLowerCase();
  if (cantidad == 1) return '1 $lower';
  const plurales = {
    'unidad': 'unidades',
    'caja': 'cajas',
    'saco': 'sacos',
    'ciento': 'cientos',
    'docena': 'docenas',
    'millar': 'millares',
    'par': 'pares',
    'paquete': 'paquetes',
    'bolsa': 'bolsas',
    'rollo': 'rollos',
  };
  if (plurales.containsKey(lower)) return '$cantidad ${plurales[lower]}';
  if (lower.endsWith('s')) return '$cantidad $lower';
  return '$cantidad ${lower}s';
}

String unidadBaseTexto(int cantidad, String unidadBase) {
  final unidad = unidadBase.trim().toUpperCase();
  if (unidad == 'KG') return 'kg';
  if (unidad == 'LT') return cantidad == 1 ? 'litro' : 'litros';
  if (unidad == 'MT') return cantidad == 1 ? 'metro' : 'metros';
  return cantidad == 1 ? 'unidad' : 'unidades';
}
