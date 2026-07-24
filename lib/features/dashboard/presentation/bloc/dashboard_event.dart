import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_data.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

class DashboardPeriodoCambiado extends DashboardEvent {
  const DashboardPeriodoCambiado(this.filtro);

  final DashboardFiltro filtro;

  @override
  List<Object?> get props => [filtro];
}

class DashboardPedidoCargado extends DashboardEvent {
  const DashboardPedidoCargado({
    required this.pedidoId,
    required this.paquetes,
    this.observacion = '',
  });

  final String pedidoId;
  final int paquetes;
  final String observacion;

  @override
  List<Object?> get props => [pedidoId, paquetes, observacion];
}
