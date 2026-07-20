import 'package:equatable/equatable.dart';

import '../../domain/entities/cliente.dart';

class ClientesState extends Equatable {
  const ClientesState({
    required this.loading,
    required this.actualizando,
    required this.clientes,
    required this.busqueda,
    required this.filtrosRapidos,
    required this.orden,
    required this.vistaGrilla,
    this.error,
  });

  factory ClientesState.initial() => const ClientesState(
    loading: true,
    actualizando: false,
    clientes: [],
    busqueda: '',
    filtrosRapidos: {'Todos'},
    orden: 'Nombre A-Z',
    vistaGrilla: true,
  );

  final bool loading;
  final bool actualizando;
  final List<Cliente> clientes;
  final String busqueda;
  final Set<String> filtrosRapidos;
  final String orden;
  final bool vistaGrilla;
  final String? error;

  List<Cliente> get clientesFiltrados {
    final query = busqueda.trim().toLowerCase();
    final result = clientes.where((cliente) {
      final coincideTexto =
          query.isEmpty ||
          cliente.nombre.toLowerCase().contains(query) ||
          cliente.telefono.contains(query) ||
          (cliente.dni?.contains(query) ?? false) ||
          (cliente.ruc?.contains(query) ?? false) ||
          (cliente.direccion?.toLowerCase().contains(query) ?? false) ||
          (cliente.referencia?.toLowerCase().contains(query) ?? false);
      final coincideRapidos =
          filtrosRapidos.contains('Todos') ||
          ((!filtrosRapidos.contains('Activos') || cliente.activo) &&
              (!filtrosRapidos.contains('Inactivos') || !cliente.activo) &&
              (!filtrosRapidos.contains('Con pedidos') ||
                  cliente.pedidosCount > 0) &&
              (!filtrosRapidos.contains('Sin pedidos') ||
                  cliente.pedidosCount == 0));
      return coincideTexto && coincideRapidos;
    }).toList();

    switch (orden) {
      case 'Nombre Z-A':
        result.sort((a, b) => b.nombre.compareTo(a.nombre));
      case 'Más recientes':
        result.sort((a, b) {
          final aDate = a.ultimoPedido ?? a.fechaRegistro;
          final bDate = b.ultimoPedido ?? b.fechaRegistro;
          return bDate.compareTo(aDate);
        });
      case 'Mayor cantidad de pedidos':
        result.sort((a, b) => b.pedidosCount.compareTo(a.pedidosCount));
      default:
        result.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    return result;
  }

  ClientesState copyWith({
    bool? loading,
    bool? actualizando,
    List<Cliente>? clientes,
    String? busqueda,
    Set<String>? filtrosRapidos,
    String? orden,
    bool? vistaGrilla,
    String? error,
    bool limpiarError = false,
  }) => ClientesState(
    loading: loading ?? this.loading,
    actualizando: actualizando ?? this.actualizando,
    clientes: clientes ?? this.clientes,
    busqueda: busqueda ?? this.busqueda,
    filtrosRapidos: filtrosRapidos ?? this.filtrosRapidos,
    orden: orden ?? this.orden,
    vistaGrilla: vistaGrilla ?? this.vistaGrilla,
    error: limpiarError ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [
    loading,
    actualizando,
    clientes,
    busqueda,
    filtrosRapidos,
    orden,
    vistaGrilla,
    error,
  ];
}
