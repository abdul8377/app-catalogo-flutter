import 'package:equatable/equatable.dart';

import 'producto_consolidado.dart';

class PedidoPreparacion extends Equatable {
  const PedidoPreparacion({
    required this.id,
    required this.codigo,
    required this.cliente,
    required this.telefono,
    required this.direccion,
    required this.referencia,
    required this.fecha,
    required this.estadoPedido,
    required this.estadoCarga,
    required this.paquetes,
    required this.productos,
    this.empresa = '',
    this.categoria = '',
    this.zonaAlmacen = '',
    this.zonaEntrega = '',
  });

  final String id;
  final String codigo;
  final String cliente;
  final String telefono;
  final String direccion;
  final String referencia;
  final DateTime fecha;
  final String estadoPedido;
  final String estadoCarga;
  final int paquetes;
  final List<ProductoPreparacion> productos;
  final String empresa;
  final String categoria;
  final String zonaAlmacen;
  final String zonaEntrega;

  int get totalProductos => productos.length;

  int get completos =>
      productos.where((producto) => producto.completado).length;

  int get presentacionesSolicitadas =>
      productos.fold(0, (sum, producto) => sum + producto.cantidadSolicitada);

  int get presentacionesPreparadas =>
      productos.fold(0, (sum, producto) => sum + producto.cantidadPreparada);

  int get presentacionesPendientes =>
      presentacionesSolicitadas - presentacionesPreparadas;

  int get unidadesSolicitadas => productos.fold(
    0,
    (sum, producto) => sum + producto.cantidadSolicitadaBase,
  );

  int get unidadesPreparadas => productos.fold(
    0,
    (sum, producto) => sum + producto.cantidadPreparadaBase,
  );

  int get unidadesPendientes => unidadesSolicitadas - unidadesPreparadas;

  double get progreso => presentacionesSolicitadas == 0
      ? 0
      : presentacionesPreparadas / presentacionesSolicitadas;

  bool get listoParaCargar =>
      productos.isNotEmpty &&
      productos.every((producto) => producto.completado) &&
      estadoCarga != 'cargado';

  bool get cargado => estadoCarga == 'cargado';

  String get estadoPreparacion {
    if (cargado) return 'cargado';
    if (presentacionesPreparadas <= 0) return 'pendiente';
    if (presentacionesPendientes > 0) return 'en_preparacion';
    return 'listo_cargar';
  }

  bool get tienePendientes => productos.any((producto) => !producto.completado);

  int get paquetesSugeridos {
    if (paquetes > 0) return paquetes;
    final lineasListas = productos
        .where((producto) => producto.completado)
        .length;
    return lineasListas <= 0 ? 1 : lineasListas;
  }

  List<String> get resumenPresentaciones {
    final totales = <String, int>{};
    for (final producto in productos) {
      final key = producto.presentacion;
      totales[key] = (totales[key] ?? 0) + producto.cantidadPreparada;
    }
    return totales.entries
        .where((entry) => entry.value > 0)
        .map((entry) => cantidadPresentacionTexto(entry.value, entry.key))
        .toList();
  }

  String get estadoPreparacionLabel {
    switch (estadoPreparacion) {
      case 'pendiente':
        return 'Pendiente de preparar';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo_cargar':
        return 'Listo para cargar';
      case 'cargado':
        return 'Cargado';
      default:
        return estadoPreparacion;
    }
  }

  @override
  List<Object?> get props => [
    id,
    codigo,
    cliente,
    telefono,
    direccion,
    referencia,
    fecha,
    estadoPedido,
    estadoCarga,
    paquetes,
    productos,
    empresa,
    categoria,
    zonaAlmacen,
    zonaEntrega,
  ];
}

class ProductoPreparacion extends Equatable {
  const ProductoPreparacion({
    required this.pedidoItemId,
    required this.productoId,
    required this.nombre,
    required this.codigo,
    required this.presentacion,
    required this.equivalencia,
    required this.cantidadSolicitada,
    required this.cantidadPreparada,
    this.marca = '',
    this.empresa = '',
    this.categoria = '',
    this.variante = '',
    this.imagenPath,
    this.factorUnidadBase = 1,
    this.unidadBase = 'UND',
    int? cantidadSolicitadaBase,
    int? cantidadPreparadaBase,
  }) : cantidadSolicitadaBase =
           cantidadSolicitadaBase ?? cantidadSolicitada * factorUnidadBase,
       cantidadPreparadaBase =
           cantidadPreparadaBase ?? cantidadPreparada * factorUnidadBase;

  final String pedidoItemId;
  final String productoId;
  final String nombre;
  final String codigo;
  final String presentacion;
  final String equivalencia;
  final int cantidadSolicitada;
  final int cantidadPreparada;
  final String marca;
  final String empresa;
  final String categoria;
  final String variante;
  final String? imagenPath;
  final int factorUnidadBase;
  final String unidadBase;
  final int cantidadSolicitadaBase;
  final int cantidadPreparadaBase;

  int get pendiente => cantidadSolicitada - cantidadPreparada;

  bool get completado =>
      cantidadSolicitada > 0 && cantidadPreparada >= cantidadSolicitada;

  String get solicitadoTexto =>
      cantidadPresentacionTexto(cantidadSolicitada, presentacion);

  String get preparadoTexto =>
      cantidadPresentacionTexto(cantidadPreparada, presentacion);

  String get pendienteTexto =>
      cantidadPresentacionTexto(pendiente, presentacion);

  String get equivalenciaTexto =>
      '$cantidadSolicitadaBase '
      '${unidadBaseTexto(cantidadSolicitadaBase, unidadBase)}';

  @override
  List<Object?> get props => [
    pedidoItemId,
    productoId,
    nombre,
    codigo,
    presentacion,
    equivalencia,
    cantidadSolicitada,
    cantidadPreparada,
    marca,
    empresa,
    categoria,
    variante,
    imagenPath,
    factorUnidadBase,
    unidadBase,
    cantidadSolicitadaBase,
    cantidadPreparadaBase,
  ];
}
