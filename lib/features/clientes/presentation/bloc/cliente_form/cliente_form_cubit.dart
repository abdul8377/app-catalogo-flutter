import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/nuevo_cliente.dart';
import '../../../domain/repositories/clientes_repository.dart';
import 'cliente_form_state.dart';

class ClienteFormCubit extends Cubit<ClienteFormState> {
  ClienteFormCubit(this._repository, {this.clienteId})
    : super(ClienteFormState.initial(isEditing: clienteId != null));

  final ClientesRepository _repository;
  final String? clienteId;

  bool get isEditing => clienteId != null;

  Future<void> load() async {
    final id = clienteId;
    if (id == null) return;

    emit(state.copyWith(loading: true, clearError: true));
    try {
      final cliente = await _repository.obtenerCliente(id);
      if (isClosed) return;
      if (cliente == null) {
        emit(
          state.copyWith(
            loading: false,
            notFound: true,
            error: 'No se encontró el cliente seleccionado.',
          ),
        );
        return;
      }
      emit(state.copyWith(loading: false, cliente: cliente, clearError: true));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(loading: false, error: 'No se pudo cargar el cliente.'),
      );
    }
  }

  Future<void> save(NuevoCliente cliente) async {
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final id = clienteId;
      if (id == null) {
        await _repository.guardarCliente(cliente);
      } else {
        await _repository.actualizarCliente(id, cliente);
      }
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true, clearError: true));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          saving: false,
          error: isEditing
              ? 'No se pudo actualizar el cliente.'
              : 'No se pudo guardar el cliente.',
        ),
      );
    }
  }
}
