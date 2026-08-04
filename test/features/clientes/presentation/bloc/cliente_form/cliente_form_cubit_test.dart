import 'dart:async';

import 'package:app_catalogo/features/clientes/domain/entities/cliente.dart';
import 'package:app_catalogo/features/clientes/domain/entities/cliente_pedido_resumen.dart';
import 'package:app_catalogo/features/clientes/domain/entities/nuevo_cliente.dart';
import 'package:app_catalogo/features/clientes/domain/repositories/clientes_repository.dart';
import 'package:app_catalogo/features/clientes/presentation/bloc/cliente_form/cliente_form_cubit.dart';
import 'package:app_catalogo/features/clientes/presentation/bloc/cliente_form/cliente_form_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteFormCubit', () {
    test('nuevo inicia listo y load no consulta el repositorio', () async {
      final repository = _ClientesRepositoryFake();
      final cubit = ClienteFormCubit(repository);
      addTearDown(cubit.close);

      expect(cubit.isEditing, isFalse);
      expect(cubit.state, ClienteFormState.initial(isEditing: false));

      await cubit.load();

      expect(repository.obtenerClienteIds, isEmpty);
      expect(cubit.state, ClienteFormState.initial(isEditing: false));
    });

    test('edición carga el cliente solicitado', () async {
      final cliente = _cliente();
      final repository = _ClientesRepositoryFake(cliente: cliente);
      final cubit = ClienteFormCubit(repository, clienteId: cliente.id);
      addTearDown(cubit.close);

      expect(cubit.isEditing, isTrue);
      expect(cubit.state.loading, isTrue);

      await cubit.load();

      expect(repository.obtenerClienteIds, [cliente.id]);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.cliente, cliente);
      expect(cubit.state.notFound, isFalse);
      expect(cubit.state.error, isNull);
    });

    test('edición informa y marca un cliente no encontrado', () async {
      final repository = _ClientesRepositoryFake();
      final cubit = ClienteFormCubit(repository, clienteId: 'inexistente');
      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.obtenerClienteIds, ['inexistente']);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.notFound, isTrue);
      expect(cubit.state.error, 'No se encontró el cliente seleccionado.');
    });

    test('edición conserva el mensaje previo cuando falla la carga', () async {
      final repository = _ClientesRepositoryFake(
        obtenerClienteError: StateError('fallo de lectura'),
      );
      final cubit = ClienteFormCubit(repository, clienteId: 'cliente-1');
      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.obtenerClienteIds, ['cliente-1']);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.notFound, isFalse);
      expect(cubit.state.error, 'No se pudo cargar el cliente.');
    });

    test(
      'nuevo guarda una sola vez y marca el formulario como guardado',
      () async {
        final repository = _ClientesRepositoryFake();
        final cubit = ClienteFormCubit(repository);
        addTearDown(cubit.close);

        final states = await _recordStates(
          cubit,
          () => cubit.save(_nuevoCliente),
        );

        expect(states.map((state) => state.saving), [true, false]);
        expect(repository.clientesGuardados, [_nuevoCliente]);
        expect(repository.clientesActualizados, isEmpty);
        expect(cubit.state.saved, isTrue);
        expect(cubit.state.error, isNull);
      },
    );

    test('edición actualiza el id correcto sin crear otro cliente', () async {
      final cliente = _cliente();
      final repository = _ClientesRepositoryFake(cliente: cliente);
      final cubit = ClienteFormCubit(repository, clienteId: cliente.id);
      addTearDown(cubit.close);
      await cubit.load();

      final states = await _recordStates(
        cubit,
        () => cubit.save(_nuevoCliente),
      );

      expect(states.map((state) => state.saving), [true, false]);
      expect(repository.clientesGuardados, isEmpty);
      expect(repository.clientesActualizados, hasLength(1));
      expect(repository.clientesActualizados.single.id, cliente.id);
      expect(repository.clientesActualizados.single.cliente, _nuevoCliente);
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.error, isNull);
    });

    test('nuevo conserva el mensaje previo cuando falla guardar', () async {
      final repository = _ClientesRepositoryFake(
        guardarError: StateError('fallo de escritura'),
      );
      final cubit = ClienteFormCubit(repository);
      addTearDown(cubit.close);

      final states = await _recordStates(
        cubit,
        () => cubit.save(_nuevoCliente),
      );

      expect(states.map((state) => state.saving), [true, false]);
      expect(repository.clientesGuardados, [_nuevoCliente]);
      expect(repository.clientesActualizados, isEmpty);
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.error, 'No se pudo guardar el cliente.');
    });

    test(
      'edición conserva el mensaje previo cuando falla actualizar',
      () async {
        final cliente = _cliente();
        final repository = _ClientesRepositoryFake(
          cliente: cliente,
          actualizarError: StateError('fallo de escritura'),
        );
        final cubit = ClienteFormCubit(repository, clienteId: cliente.id);
        addTearDown(cubit.close);
        await cubit.load();

        final states = await _recordStates(
          cubit,
          () => cubit.save(_nuevoCliente),
        );

        expect(states.map((state) => state.saving), [true, false]);
        expect(repository.clientesGuardados, isEmpty);
        expect(repository.clientesActualizados, hasLength(1));
        expect(repository.clientesActualizados.single.id, cliente.id);
        expect(repository.clientesActualizados.single.cliente, _nuevoCliente);
        expect(cubit.state.saved, isFalse);
        expect(cubit.state.error, 'No se pudo actualizar el cliente.');
      },
    );

    test(
      'cerrar durante una carga pendiente no emite sobre el Cubit',
      () async {
        final completer = Completer<Cliente?>();
        final repository = _ClientesRepositoryFake(
          obtenerClienteCompleter: completer,
        );
        final cubit = ClienteFormCubit(repository, clienteId: 'cliente-1');

        final operation = cubit.load();
        await Future<void>.delayed(Duration.zero);
        await cubit.close();
        completer.complete(_cliente());

        await expectLater(operation, completes);
      },
    );

    test(
      'cerrar durante un guardado pendiente no emite sobre el Cubit',
      () async {
        final completer = Completer<void>();
        final repository = _ClientesRepositoryFake(guardarCompleter: completer);
        final cubit = ClienteFormCubit(repository);

        final operation = cubit.save(_nuevoCliente);
        await Future<void>.delayed(Duration.zero);
        await cubit.close();
        completer.complete();

        await expectLater(operation, completes);
      },
    );
  });
}

Future<List<ClienteFormState>> _recordStates(
  ClienteFormCubit cubit,
  Future<void> Function() action,
) async {
  final states = <ClienteFormState>[];
  final subscription = cubit.stream.listen(states.add);
  await action();
  await Future<void>.delayed(Duration.zero);
  await subscription.cancel();
  return states;
}

Cliente _cliente() => Cliente(
  id: 'cliente-1',
  nombre: 'Comercial Central',
  tipo: 'Empresa',
  telefono: '999888777',
  ruc: '20123456789',
  direccion: 'Av. Principal 123',
  activo: true,
  pedidosCount: 3,
  fechaRegistro: DateTime(2026, 1, 10),
);

const _nuevoCliente = NuevoCliente(
  nombre: 'Comercial Central',
  tipo: 'Empresa',
  telefono: '999888777',
  ruc: '20123456789',
  direccion: 'Av. Principal 123',
  referencia: 'Frente al parque',
  activo: true,
  observaciones: 'Cliente frecuente',
);

class _ClientesRepositoryFake implements ClientesRepository {
  _ClientesRepositoryFake({
    this.cliente,
    this.obtenerClienteError,
    this.guardarError,
    this.actualizarError,
    this.obtenerClienteCompleter,
    this.guardarCompleter,
  });

  final Cliente? cliente;
  final Object? obtenerClienteError;
  final Object? guardarError;
  final Object? actualizarError;
  final Completer<Cliente?>? obtenerClienteCompleter;
  final Completer<void>? guardarCompleter;

  final List<String> obtenerClienteIds = [];
  final List<NuevoCliente> clientesGuardados = [];
  final List<({String id, NuevoCliente cliente})> clientesActualizados = [];

  @override
  Future<Cliente?> obtenerCliente(String id) async {
    obtenerClienteIds.add(id);
    if (obtenerClienteError case final error?) throw error;
    if (obtenerClienteCompleter case final completer?) {
      return completer.future;
    }
    return cliente;
  }

  @override
  Future<void> guardarCliente(NuevoCliente cliente) async {
    clientesGuardados.add(cliente);
    if (guardarError case final error?) throw error;
    if (guardarCompleter case final completer?) {
      await completer.future;
    }
  }

  @override
  Future<void> actualizarCliente(String id, NuevoCliente cliente) async {
    clientesActualizados.add((id: id, cliente: cliente));
    if (actualizarError case final error?) throw error;
  }

  @override
  Future<List<Cliente>> obtenerClientes() async => [];

  @override
  Future<List<ClientePedidoResumen>> obtenerPedidosCliente(
    String clienteId,
  ) async => [];

  @override
  Future<void> cambiarEstadoCliente(String id, {required bool activo}) async {}
}
