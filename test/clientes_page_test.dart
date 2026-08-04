import 'package:app_catalogo/features/clientes/domain/entities/cliente.dart';
import 'package:app_catalogo/features/clientes/domain/entities/cliente_pedido_resumen.dart';
import 'package:app_catalogo/features/clientes/domain/entities/nuevo_cliente.dart';
import 'package:app_catalogo/features/clientes/domain/repositories/clientes_repository.dart';
import 'package:app_catalogo/features/clientes/presentation/pages/clientes_page.dart';
import 'package:app_catalogo/features/clientes/presentation/dialogs/cliente_detalle_dialog.dart';
import 'package:app_catalogo/features/clientes/presentation/forms/cliente_formulario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lista clientes y filtra sin desbordar en pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ClientesRepository>.value(
        value: _ClientesRepositoryFake(),
        child: const MaterialApp(home: ClientesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Comercial San José'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Carlos');
    await tester.pumpAndSettle();

    expect(find.text('Carlos López'), findsOneWidget);
    expect(find.text('Comercial San José'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('la foto del formulario tiene mayor altura', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ClienteFormulario())),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('cliente_form_foto')));
    expect(size.height, 210);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la foto del detalle tiene mayor altura', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<ClientesRepository>.value(
        value: _ClientesRepositoryFake(),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () =>
                    ClienteDetalleDialog.show(context, clienteId: '1'),
                child: const Text('Abrir detalle'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubicación'));
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byKey(const Key('cliente_detalle_foto')));
    expect(size.height, 280);
    expect(tester.takeException(), isNull);
  });
}

class _ClientesRepositoryFake implements ClientesRepository {
  final List<Cliente> _clientes = [
    Cliente(
      id: '1',
      nombre: 'Comercial San José',
      tipo: 'Empresa',
      telefono: '987654321',
      ruc: '20123456789',
      direccion: 'Av. Principal 123',
      referencia: 'Frente al grifo',
      activo: true,
      pedidosCount: 5,
      fechaRegistro: DateTime(2025, 1, 10),
      ultimoPedido: DateTime(2026, 7, 15),
    ),
    Cliente(
      id: '2',
      nombre: 'Carlos López',
      tipo: 'Persona',
      telefono: '987123456',
      dni: '11223344',
      direccion: 'Jr. Los Olivos 456',
      activo: false,
      pedidosCount: 0,
      fechaRegistro: DateTime(2026, 7, 1),
    ),
  ];

  @override
  Future<void> actualizarCliente(String id, NuevoCliente cliente) async {}

  @override
  Future<void> cambiarEstadoCliente(String id, {required bool activo}) async {}

  @override
  Future<void> guardarCliente(NuevoCliente cliente) async {}

  @override
  Future<Cliente?> obtenerCliente(String id) async {
    for (final cliente in _clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  @override
  Future<List<Cliente>> obtenerClientes() async => _clientes;

  @override
  Future<List<ClientePedidoResumen>> obtenerPedidosCliente(
    String clienteId,
  ) async => const [];
}
