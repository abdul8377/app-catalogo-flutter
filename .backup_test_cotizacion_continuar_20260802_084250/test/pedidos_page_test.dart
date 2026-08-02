import 'package:app_catalogo/features/pedidos/domain/entities/pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_detalle.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_preparacion.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_resumen.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/producto_consolidado.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/resumen_hoy.dart';
import 'package:app_catalogo/features/pedidos/domain/repositories/pedidos_repository.dart';
import 'package:app_catalogo/features/pedidos/presentation/dialogs/generar_cotizacion_dialog.dart';
import 'package:app_catalogo/features/pedidos/presentation/pages/pedidos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('guardar borrador persiste la cotización sin generar PDF', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _PedidosListadoRepositoryFake(cotizacionCompleta: true);
    await tester.pumpWidget(
      RepositoryProvider<PedidosRepository>.value(
        value: repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => GenerarCotizacionDialog.show(
                    context,
                    pedidoId: 'pedido-48',
                  ),
                  child: const Text('Abrir cotización'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir cotización'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar borrador'));
    await tester.pumpAndSettle();

    expect(repository.ultimaCotizacion?.estado, 'Borrador');
    expect(repository.pdfRegistrados, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra pedidos reales del repositorio y cambia de pestañas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = _PedidosListadoRepositoryFake();
    await tester.pumpWidget(
      RepositoryProvider<PedidosRepository>.value(
        value: repository,
        child: const MaterialApp(home: PedidosPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gestión de pedidos'), findsOneWidget);
    expect(find.text('1 pedidos registrados'), findsOneWidget);
    expect(find.text('PED-2026-0048'), findsOneWidget);
    expect(find.text('PED-2026-0099'), findsNothing);
    expect(find.text('Comercial San José'), findsOneWidget);
    expect(find.textContaining('Subtotal conocido: S/ 185.00'), findsOneWidget);
    expect(find.textContaining('pendiente(s) de valorización'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'llanta');
    await tester.pumpAndSettle();
    expect(find.text('PED-2026-0048'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Ver pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Entrega'), findsOneWidget);
    expect(find.text('Subtotal conocido'), findsOneWidget);
    await tester.tap(find.text('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('Llanta 11R22.5'), findsOneWidget);
    expect(find.text('Variante'), findsNothing);
    expect(find.text('300 unidades'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pedidos_tab_1')));
    await tester.pumpAndSettle();
    expect(find.text('Llanta 11R22.5'), findsOneWidget);
    expect(find.textContaining('2 cientos'), findsWidgets);
    expect(find.textContaining('200 unidades'), findsWidgets);
    expect(find.text('Mostrando hoja activa HP-2026-001'), findsOneWidget);

    final verDistribucion = find.widgetWithText(
      OutlinedButton,
      'Ver distribución',
    );
    await tester.ensureVisible(verDistribucion);
    await tester.pumpAndSettle();
    await tester.tap(verDistribucion);
    await tester.pumpAndSettle();
    expect(find.text('PED-2026-0048'), findsOneWidget);
    expect(find.text('PED-2026-0099'), findsNothing);
    expect(find.textContaining('2 cientos'), findsWidgets);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar'));
    await tester.pumpAndSettle();

    final registrarButton = find.widgetWithText(
      ElevatedButton,
      'Registrar avance',
    );
    await tester.scrollUntilVisible(
      registrarButton,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(registrarButton);
    await tester.pumpAndSettle();
    expect(find.text('Registrar ahora'), findsOneWidget);
    expect(find.textContaining('Pendiente: 2 cientos'), findsOneWidget);
    final pedidoCheckbox = find.byType(Checkbox).last;
    await tester.ensureVisible(pedidoCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(pedidoCheckbox);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Confirmar preparación'),
    );
    await tester.pumpAndSettle();
    expect(repository.ultimaPreparacion?.totalPreparado, 2);
    expect(
      repository.ultimaPreparacion?.asignaciones.single.presentacion,
      'Ciento',
    );

    await tester.tap(find.byKey(const Key('pedidos_tab_2')));
    await tester.pumpAndSettle();
    expect(find.text('Preparación de pedidos'), findsOneWidget);
    expect(find.text('PED-2026-0048'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _PedidosListadoRepositoryFake implements PedidosRepository {
  _PedidosListadoRepositoryFake({this.cotizacionCompleta = false});

  final bool cotizacionCompleta;
  PreparacionProductoDraft? ultimaPreparacion;
  CotizacionPedidoDraft? ultimaCotizacion;
  int pdfRegistrados = 0;

  @override
  Future<ResumenHoy> obtenerResumenHoy() async => const ResumenHoy(
    vendedorNombre: 'Prueba',
    pedidosPendientes: 0,
    pedidosEnProceso: 0,
    pedidosListos: 0,
    pedidosEntregados: 0,
    productosSinPrecio: 0,
    cambiosSinSincronizar: 0,
  );

  @override
  Future<void> reintentarSincronizacionPedido(String pedidoId) async {}

  @override
  Future<List<PedidoResumen>> obtenerPedidosResumen() async => [
    PedidoResumen(
      id: 'pedido-48',
      codigo: 'PED-2026-0048',
      fecha: DateTime(2026, 7, 20, 15, 30),
      estado: 'Pendiente',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'cliente-1',
      clienteNombre: 'Comercial San José',
      telefono: '987654321',
      dni: '',
      ruc: '20601234567',
      direccion: 'Av. Industrial 123',
      referencia: 'Puerta azul',
      cantidadProductos: 2,
      cantidadPresentaciones: 2,
      productosResumen: const ['Llanta 11R22.5', 'Aceite 15W40'],
      subtotalConocido: 185,
      productosSinPrecio: 1,
      hojaCodigo: 'HP-2026-001',
      vendedor: 'Abdul',
    ),
    PedidoResumen(
      id: 'pedido-99',
      codigo: 'PED-2026-0099',
      fecha: DateTime(2026, 7, 19, 15, 30),
      estado: 'Pendiente',
      sincronizado: false,
      guardadoLocal: true,
      clienteId: 'cliente-2',
      clienteNombre: 'Cliente hoja anterior',
      telefono: '900000000',
      dni: '',
      ruc: '',
      direccion: 'Av. Anterior 1',
      referencia: '',
      cantidadProductos: 1,
      cantidadPresentaciones: 1,
      productosResumen: const ['Llanta 11R22.5'],
      subtotalConocido: 50,
      productosSinPrecio: 0,
      hojaCodigo: 'HP-2026-000',
      vendedor: 'Abdul',
    ),
  ];

  @override
  Future<PedidoDetalle?> obtenerPedidoDetalle(String id) async => PedidoDetalle(
    id: 'pedido-48',
    codigo: 'PED-2026-0048',
    fecha: DateTime(2026, 7, 20, 15, 30),
    estado: 'Pendiente',
    sincronizado: false,
    guardadoLocal: true,
    clienteId: 'cliente-1',
    clienteNombre: 'Comercial San José',
    telefono: '987654321',
    clienteDni: '',
    clienteRuc: '20601234567',
    direccion: 'Av. Industrial 123',
    referencia: 'Puerta azul',
    observacionesEntrega: 'Llamar antes de llegar',
    productos: [
      const PedidoDetalleProducto(
        id: 'item-1',
        productoId: 'producto-1',
        codigo: 'LLA-001',
        nombre: 'Llanta 11R22.5',
        presentacion: 'Ciento',
        equivalencia: '100 UND',
        cantidad: 3,
        precioUnitario: 185,
        subtotal: 185,
        marca: 'DINA',
      ),
      PedidoDetalleProducto(
        id: 'item-2',
        productoId: 'producto-2',
        codigo: 'ACE-001',
        nombre: 'Aceite 15W40',
        presentacion: 'Caja',
        equivalencia: '12 UND',
        cantidad: 1,
        precioUnitario: cotizacionCompleta ? 50 : null,
        subtotal: cotizacionCompleta ? 50 : null,
        marca: 'Garibaldi',
      ),
    ],
    subtotalConocido: 185,
    productosSinPrecio: 1,
    hoja: 'HP-2026-001',
    vendedor: 'Abdul',
    estadoPreparacion: 'pendiente',
    estadoCarga: 'pendiente',
    historial: [
      PedidoHistorialEntrada(
        fecha: DateTime(2026, 7, 20, 15, 30),
        evento: 'Pedido registrado',
        responsable: 'Abdul',
      ),
    ],
  );

  @override
  Future<CotizacionPedidoGuardada?> obtenerCotizacion(String id) async => null;

  @override
  Future<CotizacionPedidoGuardada> actualizarCotizacion({
    required String cotizacionId,
    required CotizacionPedidoDraft cotizacion,
  }) => guardarCotizacion(cotizacion);

  @override
  Future<CotizacionPedidoGuardada> guardarCotizacion(
    CotizacionPedidoDraft cotizacion,
  ) async {
    ultimaCotizacion = cotizacion;
    return CotizacionPedidoGuardada(
      id: 'cotizacion-1',
      pedidoId: cotizacion.pedidoId,
      codigo: 'COT-2026-0001',
      total: cotizacion.total,
      creadoEn: DateTime(2026, 7, 20),
      estado: cotizacion.estado,
    );
  }

  @override
  Future<void> registrarPdfCotizacion({
    required String cotizacionId,
    required String pdfPath,
  }) async {
    pdfRegistrados++;
  }

  @override
  Future<List<ProductoConsolidado>> obtenerProductosConsolidados() async => [
    ProductoConsolidado(
      key: 'producto-1',
      productoId: 'producto-1',
      codigo: 'LLA-001',
      nombre: 'Llanta 11R22.5',
      variante: '11R22.5',
      presentacion: 'UND',
      equivalencia: '1 UND',
      unidadBase: 'UND',
      totalRequerido: 250,
      totalPreparado: 0,
      distribucion: [
        DistribucionPedido(
          pedidoItemId: 'item-1',
          pedidoId: 'pedido-48',
          codigoPedido: 'PED-2026-0048',
          cliente: 'Comercial San José',
          telefono: '987654321',
          cantidadSolicitada: 200,
          cantidadPreparada: 0,
          fecha: DateTime(2026, 7, 20),
          estadoPedido: 'Pendiente',
          hojaCodigo: 'HP-2026-001',
          clienteId: 'cliente-1',
          presentacion: 'Ciento',
          equivalencia: '1 Ciento = 100 UND',
          cantidadOriginal: 2,
          unidadBase: 'UND',
        ),
        DistribucionPedido(
          pedidoItemId: 'item-99',
          pedidoId: 'pedido-99',
          codigoPedido: 'PED-2026-0099',
          cliente: 'Cliente hoja anterior',
          telefono: '900000000',
          cantidadSolicitada: 50,
          cantidadPreparada: 0,
          fecha: DateTime(2026, 7, 19),
          estadoPedido: 'Pendiente',
          hojaCodigo: 'HP-2026-000',
          clienteId: 'cliente-2',
          presentacion: 'Caja',
          equivalencia: '1 Caja = 50 UND',
          cantidadOriginal: 1,
          unidadBase: 'UND',
        ),
      ],
    ),
  ];

  @override
  Future<void> registrarPreparacionProducto(
    PreparacionProductoDraft preparacion,
  ) async {
    ultimaPreparacion = preparacion;
  }

  @override
  Future<List<PedidoPreparacion>> obtenerPedidosPreparacion() async => [
    PedidoPreparacion(
      id: 'pedido-48',
      codigo: 'PED-2026-0048',
      cliente: 'Comercial San José',
      telefono: '987654321',
      direccion: 'Av. Industrial 123',
      referencia: 'Puerta azul',
      fecha: DateTime(2026, 7, 20, 15, 30),
      estadoPedido: 'Pendiente',
      estadoCarga: 'pendiente_carga',
      paquetes: 0,
      productos: [
        ProductoPreparacion(
          pedidoItemId: 'item-1',
          productoId: 'producto-1',
          nombre: 'Llanta 11R22.5',
          codigo: 'LLA-001',
          presentacion: 'Unidad',
          equivalencia: '1 UND',
          cantidadSolicitada: 1,
          cantidadPreparada: 0,
        ),
      ],
    ),
  ];

  @override
  Future<void> cambiarEstadoPedido({
    required String pedidoId,
    required String nuevoEstado,
    String observacion = '',
  }) async {}

  @override
  Future<void> cancelarPedido({
    required String pedidoId,
    required String motivo,
  }) async {}

  @override
  Future<void> reactivarPedido({
    required String pedidoId,
    String observacion = '',
  }) async {}

  @override
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) async {}

  @override
  Future<List<ClientePedido>> buscarClientes(String query) async => const [];

  @override
  Future<HojaPedidoActiva> crearHojaActiva() async => const HojaPedidoActiva(
    id: 'hoja-1',
    codigo: 'HP-2026-001',
    estado: 'Abierta',
  );

  @override
  Future<HojaPedidoActiva?> obtenerHojaActiva() async => const HojaPedidoActiva(
    id: 'hoja-1',
    codigo: 'HP-2026-001',
    estado: 'Abierta',
  );

  @override
  Future<PedidoRegistrado> actualizarPedido({
    required String pedidoId,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async => PedidoRegistrado(
    id: pedidoId,
    codigo: 'PED-2026-0048',
    cliente: cliente.nombre,
    hojaCodigo: 'HP-2026-001',
    estado: 'Pendiente',
  );

  @override
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async => PedidoRegistrado(
    id: 'pedido-guardado',
    codigo: 'PED-2026-0049',
    cliente: cliente.nombre,
    hojaCodigo: hoja.codigo,
    estado: 'Pendiente',
  );
}
