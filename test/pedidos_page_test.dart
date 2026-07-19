import 'package:app_catalogo/features/catalogo/domain/entities/catalogo_form_data.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/nuevo_producto.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_detalle.dart';
import 'package:app_catalogo/features/catalogo/domain/entities/producto_resumen.dart';
import 'package:app_catalogo/features/catalogo/domain/repositories/catalogo_repository.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/repositories/pedidos_repository.dart';
import 'package:app_catalogo/features/pedidos/presentation/pages/pedidos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('agrega un producto y abre el carrito en pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CatalogoRepository>.value(value: _CatalogoFake()),
          RepositoryProvider<PedidosRepository>.value(value: _PedidosFake()),
        ],
        child: const MaterialApp(home: PedidosPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nuevo pedido'), findsOneWidget);
    expect(find.text('Producto activo'), findsOneWidget);
    expect(find.text('Producto inactivo'), findsNothing);

    await tester.tap(find.byKey(const Key('agregar_activo')));
    await tester.pumpAndSettle();
    expect(find.text('Agregar al pedido'), findsWidgets);
    await tester.tap(find.byKey(const Key('confirmar_agregar_producto')));
    await tester.pumpAndSettle();

    expect(find.text('1 producto(s)'), findsOneWidget);
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar pedido'), findsOneWidget);
    expect(find.text('Subtotal conocido: S/ 10.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PedidosFake implements PedidosRepository {
  @override
  Future<List<ClientePedido>> buscarClientes(String query) async => const [];
  @override
  Future<HojaPedidoActiva> crearHojaActiva() async =>
      const HojaPedidoActiva(id: 'h', codigo: 'HP-2026-001', estado: 'Abierta');
  @override
  Future<HojaPedidoActiva?> obtenerHojaActiva() async =>
      const HojaPedidoActiva(id: 'h', codigo: 'HP-2026-001', estado: 'Abierta');
  @override
  Future<PedidoRegistrado> guardarPedido({
    required HojaPedidoActiva hoja,
    required ClientePedido cliente,
    required List<PedidoItem> items,
    required String vendedor,
  }) async => PedidoRegistrado(
    id: 'p',
    codigo: 'PED-2026-0001',
    cliente: cliente.nombre,
    hojaCodigo: hoja.codigo,
    estado: 'Pendiente',
  );
}

class _CatalogoFake implements CatalogoRepository {
  @override
  Future<List<ProductoResumen>> obtenerProductos() async => const [
    ProductoResumen(
      id: 'activo',
      codigo: 'ACT-1',
      nombre: 'Producto activo',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      unidadVenta: 'Unidad',
      precio: 10,
      sinPrecio: false,
      activo: true,
      tipoRegistro: 'unico',
      atributosClave: ['Rosca: RF'],
    ),
    ProductoResumen(
      id: 'inactivo',
      codigo: 'INA-1',
      nombre: 'Producto inactivo',
      empresa: 'DINA',
      marca: 'DINA',
      categoria: 'Pernería',
      unidadVenta: 'Unidad',
      precio: 10,
      sinPrecio: false,
      activo: false,
      tipoRegistro: 'unico',
      atributosClave: [],
    ),
  ];

  @override
  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async =>
      ProductoDetalle(
        id: id,
        codigo: 'ACT-1',
        nombre: 'Producto activo',
        descripcion: 'Descripción',
        empresa: 'DINA',
        marca: 'DINA',
        categoria: 'Pernería',
        subcategoria: 'Pernos',
        tipoRegistro: 'unico',
        atributos: const {'Rosca': 'RF'},
        presentaciones: const [
          PresentacionProducto(nombre: 'Unidad', unidad: '1 UND'),
        ],
        precios: const [PrecioProducto(presentacion: 'Unidad', valor: 10)],
        activo: true,
        creadoEn: DateTime(2026),
      );

  @override
  Future<List<ProductoResumen>> buscarProductos(String query) async => [];
  @override
  Future<CatalogoFormData> obtenerDatosFormulario() async =>
      const CatalogoFormData(
        empresas: [],
        marcas: [],
        subcategorias: {},
        atributos: {},
      );
  @override
  Future<void> guardarProducto(NuevoProducto producto) async {}
  @override
  Future<void> actualizarProducto(String id, NuevoProducto producto) async {}
  @override
  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {}
}
