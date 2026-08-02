import 'package:equatable/equatable.dart';

import '../../domain/entities/pedido_preparacion.dart';

enum PreparacionModoAgrupacion {
  estado('estado', 'Por estado'),
  empresa('empresa', 'Por empresa'),
  categoria('categoria', 'Por categoría'),
  almacen('almacen', 'Por zona almacén'),
  cliente('cliente', 'Por cliente'),
  zonaEntrega('zona_entrega', 'Por zona entrega'),
  faltantes('faltantes', 'Faltantes');

  const PreparacionModoAgrupacion(this.key, this.label);

  final String key;
  final String label;
}

class PreparacionCargaState extends Equatable {
  const PreparacionCargaState({
    required this.loading,
    required this.saving,
    required this.subTab,
    required this.modoAgrupacion,
    required this.pedidos,
    this.hojaActivaCodigo,
    this.error,
    this.message,
  });

  factory PreparacionCargaState.initial() => const PreparacionCargaState(
    loading: true,
    saving: false,
    subTab: 0,
    modoAgrupacion: PreparacionModoAgrupacion.estado,
    pedidos: [],
  );

  final bool loading;
  final bool saving;
  final int subTab;
  final PreparacionModoAgrupacion modoAgrupacion;
  final List<PedidoPreparacion> pedidos;
  final String? hojaActivaCodigo;
  bool get sinHojaActiva =>
      hojaActivaCodigo == null || hojaActivaCodigo!.trim().isEmpty;
  final String? error;
  final String? message;

  List<PedidoPreparacion> get pedidosFiltrados {
    if (subTab == 0) {
      return pedidos.where((pedido) => !pedido.cargado).toList();
    }
    return pedidos
        .where((pedido) => pedido.listoParaCargar || pedido.cargado)
        .toList();
  }

  int get pedidosPendientesPreparacion =>
      pedidos.where((pedido) => pedido.estadoPreparacion == 'pendiente').length;

  int get pedidosEnPreparacion => pedidos
      .where((pedido) => pedido.estadoPreparacion == 'en_preparacion')
      .length;

  int get pedidosListosCarga =>
      pedidos.where((pedido) => pedido.listoParaCargar).length;

  int get pedidosCargados => pedidos.where((pedido) => pedido.cargado).length;

  int get unidadesPendientes =>
      pedidos.fold(0, (sum, pedido) => sum + pedido.unidadesPendientes);

  PreparacionCargaState copyWith({
    bool? loading,
    bool? saving,
    int? subTab,
    PreparacionModoAgrupacion? modoAgrupacion,
    List<PedidoPreparacion>? pedidos,
    String? hojaActivaCodigo,
    bool clearHojaActiva = false,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => PreparacionCargaState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    subTab: subTab ?? this.subTab,
    modoAgrupacion: modoAgrupacion ?? this.modoAgrupacion,
    pedidos: pedidos ?? this.pedidos,
    hojaActivaCodigo: clearHojaActiva
        ? null
        : hojaActivaCodigo ?? this.hojaActivaCodigo,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    saving,
    subTab,
    modoAgrupacion,
    pedidos,
    hojaActivaCodigo,
    error,
    message,
  ];
}
