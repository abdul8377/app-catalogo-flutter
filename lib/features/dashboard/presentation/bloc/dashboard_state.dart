import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_data.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.loading,
    required this.actualizando,
    required this.procesando,
    required this.filtro,
    required this.data,
    required this.ultimaActualizacion,
    this.error,
    this.message,
  });

  factory DashboardState.initial() => DashboardState(
    loading: true,
    actualizando: false,
    procesando: false,
    filtro: const DashboardFiltro(),
    data: const DashboardData.empty(),
    ultimaActualizacion: DateTime.now(),
  );

  final bool loading;
  final bool actualizando;
  final bool procesando;
  final DashboardFiltro filtro;
  final DashboardData data;
  final DateTime ultimaActualizacion;
  final String? error;
  final String? message;

  DashboardState copyWith({
    bool? loading,
    bool? actualizando,
    bool? procesando,
    DashboardFiltro? filtro,
    DashboardData? data,
    DateTime? ultimaActualizacion,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => DashboardState(
    loading: loading ?? this.loading,
    actualizando: actualizando ?? this.actualizando,
    procesando: procesando ?? this.procesando,
    filtro: filtro ?? this.filtro,
    data: data ?? this.data,
    ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    loading,
    actualizando,
    procesando,
    filtro,
    data,
    ultimaActualizacion,
    error,
    message,
  ];
}
