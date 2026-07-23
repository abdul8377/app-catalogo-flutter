import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/hoja_pedido.dart';
import '../../domain/repositories/hojas_pedido_repository.dart';

sealed class HojaDetalleEvent extends Equatable {
  const HojaDetalleEvent();

  @override
  List<Object?> get props => [];
}

class HojaDetalleStarted extends HojaDetalleEvent {
  const HojaDetalleStarted(this.hojaId);

  final String hojaId;

  @override
  List<Object?> get props => [hojaId];
}

class HojaDetalleState extends Equatable {
  const HojaDetalleState({required this.loading, this.hoja, this.error});

  const HojaDetalleState.initial() : this(loading: true);

  final bool loading;
  final HojaPedido? hoja;
  final String? error;

  @override
  List<Object?> get props => [loading, hoja, error];
}

class HojaDetalleBloc extends Bloc<HojaDetalleEvent, HojaDetalleState> {
  HojaDetalleBloc(this._repository) : super(const HojaDetalleState.initial()) {
    on<HojaDetalleStarted>(_iniciar);
  }

  final HojasPedidoRepository _repository;

  Future<void> _iniciar(
    HojaDetalleStarted event,
    Emitter<HojaDetalleState> emit,
  ) async {
    emit(const HojaDetalleState(loading: true));
    try {
      final hoja = await _repository.obtenerHoja(event.hojaId);
      if (hoja == null) {
        emit(
          const HojaDetalleState(
            loading: false,
            error: 'La hoja seleccionada ya no existe.',
          ),
        );
        return;
      }
      emit(HojaDetalleState(loading: false, hoja: hoja));
    } catch (_) {
      emit(
        const HojaDetalleState(
          loading: false,
          error: 'No se pudo cargar el detalle de la hoja.',
        ),
      );
    }
  }
}
