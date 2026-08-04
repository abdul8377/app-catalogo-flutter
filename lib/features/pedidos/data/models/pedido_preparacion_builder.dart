part of '../datasources/pedidos_local_datasource.dart';

class _PedidoPreparacionBuilder {
  _PedidoPreparacionBuilder({
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
  final Set<String> empresas = {};
  final Set<String> categorias = {};
  final List<ProductoPreparacion> productos = [];

  void registrarClasificacion({
    required String empresa,
    required String categoria,
  }) {
    final empresaLimpia = empresa.trim();
    final categoriaLimpia = categoria.trim();
    if (empresaLimpia.isNotEmpty) empresas.add(empresaLimpia);
    if (categoriaLimpia.isNotEmpty) categorias.add(categoriaLimpia);
  }

  PedidoPreparacion build() => PedidoPreparacion(
    id: id,
    codigo: codigo,
    cliente: cliente,
    telefono: telefono,
    direccion: direccion,
    referencia: referencia,
    fecha: fecha,
    estadoPedido: estadoPedido,
    estadoCarga: estadoCarga,
    paquetes: paquetes,
    productos: productos,
    empresa: _resumenValores(empresas, fallback: 'Sin empresa'),
    categoria: _resumenValores(categorias, fallback: 'Sin categoría'),
    zonaAlmacen: _resolverZonaAlmacen(categorias),
    zonaEntrega: _resolverZonaEntrega(direccion, referencia),
  );

  String _resumenValores(Set<String> valores, {required String fallback}) {
    if (valores.isEmpty) return fallback;
    final ordenados = valores.toList()..sort();
    if (ordenados.length == 1) return ordenados.first;
    return '${ordenados.first} +${ordenados.length - 1}';
  }

  String _resolverZonaAlmacen(Set<String> categorias) {
    final texto = categorias.join(' ').toLowerCase();
    if (texto.contains('perner')) return 'Pasillo A • Pernería';
    if (texto.contains('herramientas eléctricas')) {
      return 'Pasillo B • Herramientas eléctricas';
    }
    if (texto.contains('herramientas manuales')) {
      return 'Pasillo C • Herramientas manuales';
    }
    if (texto.contains('purificador')) return 'Pasillo D • Purificadores';
    if (texto.contains('limpieza')) return 'Pasillo E • Limpieza';
    if (categorias.isNotEmpty) return 'Zona ${categorias.first}';
    return 'Sin zona de almacén';
  }

  String _resolverZonaEntrega(String direccion, String referencia) {
    final texto = '$direccion $referencia'.toLowerCase();
    if (texto.contains('norte')) return 'Norte';
    if (texto.contains('sur')) return 'Sur';
    if (texto.contains('este')) return 'Este';
    if (texto.contains('oeste')) return 'Oeste';
    if (texto.contains('centro') || texto.contains('principal')) {
      return 'Centro';
    }
    return 'Zona por asignar';
  }
}
