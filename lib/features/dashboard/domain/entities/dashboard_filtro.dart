import 'package:equatable/equatable.dart';

enum DashboardPeriodoTipo { hojaActiva, hoy, semana, mes, personalizado }

class DashboardFiltro extends Equatable {
  const DashboardFiltro({
    this.periodo = DashboardPeriodoTipo.hojaActiva,
    this.fechaInicio,
    this.fechaFin,
  });

  final DashboardPeriodoTipo periodo;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  String get etiqueta {
    switch (periodo) {
      case DashboardPeriodoTipo.hojaActiva:
        return 'Hoja activa';
      case DashboardPeriodoTipo.hoy:
        return 'Hoy';
      case DashboardPeriodoTipo.semana:
        return 'Esta semana';
      case DashboardPeriodoTipo.mes:
        return 'Este mes';
      case DashboardPeriodoTipo.personalizado:
        return 'Personalizado';
    }
  }

  @override
  List<Object?> get props => [periodo, fechaInicio, fechaFin];
}
