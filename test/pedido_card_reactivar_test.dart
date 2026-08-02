import 'package:app_catalogo/features/pedidos/domain/entities/pedido_resumen.dart';
import 'package:app_catalogo/features/pedidos/presentation/widgets/pedido_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un pedido cancelado ofrece reactivación', (tester) async {
    var called = false;
    final order = PedidoResumen(
      id: 'order',
      codigo: 'PED-2026-0001',
      fecha: DateTime(2026, 8, 1),
      estado: 'Cancelado',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'client',
      clienteNombre: 'Cliente de prueba',
      telefono: '999999999',
      direccion: 'Dirección',
      referencia: '',
      cantidadProductos: 1,
      cantidadPresentaciones: 1,
      productosResumen: const ['Producto'],
      subtotalConocido: 10,
      productosSinPrecio: 0,
      hojaCodigo: 'HP-2026-001',
      vendedor: 'Vendedor',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PedidoCard(
              pedido: order,
              onVerPedido: () {},
              onCambiarEstado: () => called = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Reactivar pedido'), findsOneWidget);
    await tester.tap(find.text('Reactivar pedido'));
    expect(called, isTrue);
    expect(tester.takeException(), isNull);
  });
}
