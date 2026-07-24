import 'package:app_catalogo/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:app_catalogo/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:app_catalogo/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra datos reales, cambia periodo y navega sin desbordar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardRepositoryFake(_dashboardData());
    int? navigationIndex;
    await tester.pumpWidget(
      _TestApp(
        repository: repository,
        child: DashboardPage(onNavigate: (value) => navigationIndex = value),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard operativo'), findsOneWidget);
    expect(find.text('HP-2026-007'), findsOneWidget);
    expect(find.text('Total conocido'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Esta semana'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Esta semana'));
    await tester.pumpAndSettle();

    expect(repository.filtros.last.periodo, DashboardPeriodoTipo.semana);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const ValueKey('dashboard-kpi-clientes')),
    );
    await tester.tap(find.byKey(const ValueKey('dashboard-kpi-clientes')));
    expect(navigationIndex, 2);
  });

  testWidgets('registra una carga desde un pedido completamente preparado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DashboardRepositoryFake(_dashboardData());
    await tester.pumpWidget(
      _TestApp(repository: repository, child: const DashboardPage()),
    );
    await tester.pumpAndSettle();

    final loadButton = find.byKey(
      const ValueKey('dashboard-load-pedido-listo'),
    );
    tester.widget<FilledButton>(loadButton).onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Registrar carga'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad de paquetes *'),
      '4',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Observación'),
      'Carga verificada',
    );
    await tester.tap(find.text('Confirmar carga'));
    await tester.pumpAndSettle();

    expect(repository.pedidoCargadoId, 'pedido-listo');
    expect(repository.paquetes, 4);
    expect(repository.observacion, 'Carga verificada');
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository, required this.child});

  final DashboardRepository repository;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<DashboardRepository>.value(
        value: repository,
        child: MaterialApp(theme: ThemeData(useMaterial3: true), home: child),
      );
}

class _DashboardRepositoryFake implements DashboardRepository {
  _DashboardRepositoryFake(this.data);

  final DashboardData data;
  final List<DashboardFiltro> filtros = [];
  String? pedidoCargadoId;
  int? paquetes;
  String? observacion;

  @override
  Future<DashboardData> obtenerDashboard(DashboardFiltro filtro) async {
    filtros.add(filtro);
    return data;
  }

  @override
  Future<void> marcarPedidoCargado({
    required String pedidoId,
    required int paquetes,
    String observacion = '',
  }) async {
    pedidoCargadoId = pedidoId;
    this.paquetes = paquetes;
    this.observacion = observacion;
  }
}

DashboardData _dashboardData() {
  final now = DateTime(2026, 7, 23, 12);
  return DashboardData(
    totalPedidos: 5,
    subtotalConocido: 1250,
    pedidosPendientesValorizar: 1,
    totalClientes: 4,
    unidadesRequeridas: 500,
    unidadesPreparadas: 350,
    pedidosCargados: 1,
    pedidosEntregados: 1,
    pedidosListosCargar: 1,
    pedidosPreparacionParcial: 1,
    cotizacionesGeneradas: 2,
    cotizacionesBorradores: 1,
    pedidosPorEstado: const {
      'Pendiente': 1,
      'En proceso': 2,
      'Listo para entregar': 1,
      'Entregado': 1,
      'Cancelado': 0,
    },
    hojaActiva: DashboardHojaActiva(
      id: 'hoja-1',
      codigo: 'HP-2026-007',
      estado: 'Abierta',
      vendedor: 'Alfonzo Esteban',
      fecha: now.subtract(const Duration(days: 2)),
      pedidos: 5,
      clientes: 4,
      productos: 8,
      subtotal: 1250,
      pendientesPrecio: 1,
    ),
    productosTop: const [
      DashboardProductoTop(
        productoId: 'producto-1',
        nombre: 'Perno hexagonal DINA',
        codigo: 'PER-001',
        marca: 'DINA',
        unidadBase: 'UND',
        cantidadRequerida: 300,
        cantidadPreparada: 200,
        pedidos: 3,
      ),
    ],
    cotizaciones: [
      DashboardCotizacion(
        id: 'cot-1',
        pedidoId: 'pedido-1',
        codigo: 'COT-2026-0040-V2',
        pedidoCodigo: 'PED-2026-0098',
        cliente: 'Comercial Central',
        total: 430,
        estado: 'Generada',
        fecha: now,
        tienePdf: true,
      ),
    ],
    pedidosRecientes: [
      DashboardPedidoReciente(
        id: 'pedido-1',
        codigo: 'PED-2026-0098',
        cliente: 'Comercial Central',
        productos: 3,
        total: 430,
        productosSinPrecio: 0,
        estado: 'En proceso',
        fecha: now,
        sincronizado: false,
      ),
    ],
    clientes: [
      DashboardCliente(
        id: 'cliente-1',
        nombre: 'Comercial Central',
        pedidos: 2,
        subtotalConocido: 640,
        ultimoPedido: now,
        direccion: 'Av. Principal 123',
      ),
    ],
    actividad: [
      DashboardActividad(
        evento: 'Pedido PED-2026-0098 registrado',
        fecha: now,
        tipo: 'pedido',
      ),
    ],
    principalesFaltantes: const [
      DashboardFaltante(
        productoId: 'producto-1',
        nombre: 'Perno hexagonal DINA',
        codigo: 'PER-001',
        unidadBase: 'UND',
        cantidadPendiente: 100,
        pedidosAfectados: 2,
      ),
    ],
    pedidosListos: const [
      DashboardPedidoListo(
        id: 'pedido-listo',
        codigo: 'PED-2026-0099',
        cliente: 'Ferretería Prueba',
        productos: 2,
        direccion: 'Calle Norte 250',
      ),
    ],
    sincronizacion: const DashboardSincronizacion(
      pedidosPendientes: 1,
      hojasPendientes: 1,
      operacionesEnCola: 2,
    ),
  );
}
