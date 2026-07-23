import 'package:app_catalogo/features/hojas_pedido/domain/entities/hoja_pedido.dart';
import 'package:app_catalogo/features/hojas_pedido/domain/repositories/hojas_pedido_repository.dart';
import 'package:app_catalogo/features/hojas_pedido/presentation/pages/hojas_pedido_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la hoja activa y su detalle sin desbordar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _HojasPedidoRepositoryFake();
    await tester.pumpWidget(
      RepositoryProvider<HojasPedidoRepository>.value(
        value: repository,
        child: const MaterialApp(home: HojasPedidoPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HP-2026-001'), findsOneWidget);
    expect(find.text('Ferretería El Sol'), findsOneWidget);
    expect(find.text('Perno hexagonal'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'vista de hoja activa');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ver detalle'));
    await tester.pumpAndSettle();

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Pedidos'), findsWidgets);
    expect(tester.takeException(), isNull, reason: 'resumen del diálogo');
    await tester.drag(find.byType(TabBar), const Offset(-260, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Clientes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Av. Principal 123'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'clientes del diálogo');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('HP-2026-000'), findsOneWidget);
    expect(find.text('Ver consolidado'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'tarjeta del historial');
  });
}

class _HojasPedidoRepositoryFake implements HojasPedidoRepository {
  final hoja = HojaPedido(
    id: 'hoja-1',
    codigo: 'HP-2026-001',
    estado: 'Abierta',
    vendedor: 'Alfonzo Esteban',
    fechaApertura: DateTime(2026, 7, 21, 8, 30),
    sincronizado: false,
    totalPedidos: 1,
    totalClientes: 1,
    totalProductosDiferentes: 1,
    totalUnidades: 10,
    subtotalConocido: 120,
    pedidosPendientesPrecio: 0,
    pedidosPendientes: 1,
    pedidosEnProceso: 0,
    pedidosListos: 0,
    pedidosEntregados: 0,
    pedidosCancelados: 0,
    progresoPreparacion: 0.5,
    progresoCarga: 0,
    pedidos: [
      PedidoEnHoja(
        id: 'pedido-1',
        codigo: 'PED-2026-0001',
        clienteId: 'cliente-1',
        cliente: 'Ferretería El Sol',
        cantidadProductos: 1,
        total: 120,
        productosSinPrecio: 0,
        estado: 'Pendiente',
        progresoPreparacion: 0.5,
        cargado: false,
        fecha: DateTime(2026, 7, 21, 9),
      ),
    ],
    productos: const [
      ProductoEnHoja(
        key: 'producto-1|Unidad|1 UND',
        productoId: 'producto-1',
        codigo: 'PER-001',
        nombre: 'Perno hexagonal',
        presentacion: 'Unidad',
        equivalencia: '1 UND',
        cantidadTotal: 10,
        cantidadPreparada: 5,
        pedidosQueLoIncluyen: 1,
      ),
    ],
    clientes: const [
      ClienteEnHoja(
        id: 'cliente-1',
        nombre: 'Ferretería El Sol',
        telefono: '999999999',
        direccion: 'Av. Principal 123',
        cantidadPedidos: 1,
        cantidadProductos: 1,
        subtotalConocido: 120,
      ),
    ],
    historial: [
      HistorialHojaEntrada(
        fecha: DateTime(2026, 7, 21, 8, 30),
        evento: 'Hoja HP-2026-001 creada',
        responsable: 'Alfonzo Esteban',
      ),
    ],
  );

  late final hojaAnterior = HojaPedido(
    id: 'hoja-0',
    codigo: 'HP-2026-000',
    estado: 'Completada',
    vendedor: 'Alfonzo Esteban',
    fechaApertura: DateTime(2026, 7, 20, 8),
    fechaCierre: DateTime(2026, 7, 20, 18),
    referencia: 'Ruta norte',
    sincronizado: false,
    usuarioCierre: 'Alfonzo Esteban',
    totalPedidos: 1,
    totalClientes: 1,
    totalProductosDiferentes: 1,
    totalUnidades: 10,
    subtotalConocido: 120,
    pedidosPendientesPrecio: 1,
    pedidosPendientes: 0,
    pedidosEnProceso: 0,
    pedidosListos: 0,
    pedidosEntregados: 1,
    pedidosCancelados: 0,
    progresoPreparacion: 1,
    progresoCarga: 1,
    pedidos: hoja.pedidos,
    productos: hoja.productos,
    clientes: hoja.clientes,
    historial: hoja.historial,
  );

  @override
  Future<List<HojaPedido>> obtenerHojas() async => [hoja, hojaAnterior];

  @override
  Future<HojaPedido?> obtenerHoja(String id) async => hoja;

  @override
  Future<HojaPedido> crearHoja({
    required String vendedor,
    String referencia = '',
    String observacion = '',
  }) async => hoja;

  @override
  Future<void> completarHoja({
    required String hojaId,
    required String usuario,
    String observacion = '',
  }) async {}
}
