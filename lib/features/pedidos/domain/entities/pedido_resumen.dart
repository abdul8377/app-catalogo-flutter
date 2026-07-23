import 'package:equatable/equatable.dart';

class PedidoResumen extends Equatable {
  const PedidoResumen({
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
    required this.cantidadProductos,
    required this.cantidadPresentaciones,
    required this.productosResumen,
    required this.subtotalConocido,
    required this.productosSinPrecio,
    required this.hojaCodigo,
    required this.vendedor,
    this.dni = '',
    this.ruc = '',
    this.fotoUbicacionPath,
    this.empresas = const [],
    this.marcas = const [],
    this.categorias = const [],
    this.cotizacionesGeneradas = 0,
    this.cotizacionVigente = false,
    this.subtotalProductos = 0,
    this.descuentoCotizado = 0,
    this.totalSinIgv = 0,
    this.igv = 0,
    this.totalCotizado = 0,
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
  final String dni;
  final String ruc;
  final String direccion;
  final String referencia;
  final String? fotoUbicacionPath;
  final int cantidadProductos;
  final int cantidadPresentaciones;
  final List<String> productosResumen;
  final double subtotalConocido;
  final int productosSinPrecio;
  final String hojaCodigo;
  final String vendedor;
  final List<String> empresas;
  final List<String> marcas;
  final List<String> categorias;
  final int cotizacionesGeneradas;
  final bool cotizacionVigente;
  final double subtotalProductos;
  final double descuentoCotizado;
  final double totalSinIgv;
  final double igv;
  final double totalCotizado;
  final String? syncError;

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

  bool get totalParcial => !cotizacionVigente && productosSinPrecio > 0;

  String get productosTexto {
    if (productosResumen.isEmpty) return 'Sin productos registrados';
    final visibles = productosResumen.take(3).toList();
    final extra = cantidadProductos - visibles.length;
    return '${visibles.join(', ')}${extra > 0 ? ' y $extra más' : ''}';
  }

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
    dni,
    ruc,
    direccion,
    referencia,
    fotoUbicacionPath,
    cantidadProductos,
    cantidadPresentaciones,
    productosResumen,
    subtotalConocido,
    productosSinPrecio,
    hojaCodigo,
    vendedor,
    empresas,
    marcas,
    categorias,
    cotizacionesGeneradas,
    cotizacionVigente,
    subtotalProductos,
    descuentoCotizado,
    totalSinIgv,
    igv,
    totalCotizado,
    syncError,
  ];
}
