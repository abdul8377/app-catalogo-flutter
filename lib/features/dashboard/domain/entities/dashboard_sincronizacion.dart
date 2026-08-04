import 'package:equatable/equatable.dart';

import 'dashboard_sync_pendiente.dart';

class DashboardSincronizacion extends Equatable {
  const DashboardSincronizacion({
    this.pedidosPendientes = 0,
    this.hojasPendientes = 0,
    this.operacionesEnCola = 0,
    this.errores = 0,
    this.ultimaSincronizacion,
    this.pendientes = const [],
  });

  final int pedidosPendientes;
  final int hojasPendientes;
  final int operacionesEnCola;
  final int errores;
  final DateTime? ultimaSincronizacion;
  final List<DashboardSyncPendiente> pendientes;

  int get totalPendiente =>
      pedidosPendientes + hojasPendientes + operacionesEnCola;

  bool get sincronizado => totalPendiente == 0 && errores == 0;

  @override
  List<Object?> get props => [
    pedidosPendientes,
    hojasPendientes,
    operacionesEnCola,
    errores,
    ultimaSincronizacion,
    pendientes,
  ];
}
