import 'package:app_catalogo/features/pedidos/domain/entities/cotizacion_pedido.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_detalle.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido_resumen.dart';
import 'package:app_catalogo/features/pedidos/presentation/bloc/pedidos_listado/pedidos_listado_state.dart';
import 'package:app_catalogo/features/pedidos/presentation/widgets/cotizacion_producto_item.dart';
import 'package:app_catalogo/features/pedidos/presentation/widgets/pedido_card.dart';
import 'package:app_catalogo/features/clientes/domain/entities/cliente.dart';
import 'package:app_catalogo/features/clientes/presentation/widgets/cliente_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el resumen cuenta solo la hoja activa o la seleccionada', () {
    final activa = _pedido(
      id: 'activo',
      hoja: 'HP-2026-002',
      estado: 'En proceso',
    );
    final anterior = _pedido(
      id: 'anterior',
      hoja: 'HP-2026-001',
      estado: 'En proceso',
    );
    final state = PedidosListadoState.initial().copyWith(
      loading: false,
      pedidos: [activa, anterior],
      hojaActivaCodigo: 'HP-2026-002',
      hoja: 'HP-2026-002',
    );

    expect(state.countEstado('en_proceso'), 1);
    expect(state.pedidosHojaResumen, [activa]);

    final historica = state.copyWith(hoja: 'HP-2026-001');
    expect(historica.countEstado('en_proceso'), 1);
    expect(historica.pedidosHojaResumen, [anterior]);
  });

  test('la equivalencia representa toda la cantidad solicitada', () {
    const producto = PedidoDetalleProducto(
      id: 'item-1',
      productoId: 'producto-1',
      codigo: 'PER-001',
      nombre: 'Perno',
      presentacion: 'Ciento',
      equivalencia: '1 Ciento = 100 UND',
      cantidad: 3,
      precioUnitario: 100,
      subtotal: 300,
    );

    expect(producto.equivalenciaTotal, '300 unidades');
  });

  test('el descuento en soles se aplica una vez al subtotal de la línea', () {
    final item = CotizacionProductoFormItem(
      producto: const PedidoDetalleProducto(
        id: 'item-1',
        productoId: 'producto-1',
        codigo: 'PER-001',
        nombre: 'Perno',
        presentacion: 'Ciento',
        equivalencia: '100 UND',
        cantidad: 3,
        precioUnitario: 100,
        subtotal: 300,
      ),
      precioCotizacion: 100,
      descuento: 10,
    );

    expect(item.subtotalSinDescuento, 300);
    expect(item.descuentoAplicado, 10);
    expect(item.subtotalCotizacion, 290);
  });

  test('el descuento porcentual se calcula sobre el subtotal completo', () {
    final item = CotizacionProductoFormItem(
      producto: const PedidoDetalleProducto(
        id: 'item-1',
        productoId: 'producto-1',
        codigo: 'PER-001',
        nombre: 'Perno',
        presentacion: 'Ciento',
        equivalencia: '100 UND',
        cantidad: 3,
        precioUnitario: 100,
        subtotal: 300,
      ),
      precioCotizacion: 100,
      descuento: 10,
      tipoDescuento: 'porcentaje',
    );

    expect(item.descuentoAplicado, 30);
    expect(item.subtotalCotizacion, 270);
  });

  test('desglosa correctamente el IGV incluido en el total', () {
    expect(CotizacionIgv.totalSinIgv(420), closeTo(355.93, 0.01));
    expect(CotizacionIgv.igvIncluido(420), closeTo(64.07, 0.01));
    expect(
      CotizacionIgv.totalSinIgv(420) + CotizacionIgv.igvIncluido(420),
      closeTo(420, 0.001),
    );
  });

  test('calcula el total restando todos los descuentos antes del IGV', () {
    final total = CotizacionCalculo.totalConDescuentos(
      subtotalProductos: 450,
      descuentosProductos: 20,
      descuentoGeneral: 10,
    );

    expect(total, 420);
    expect(CotizacionIgv.totalSinIgv(total), closeTo(355.93, 0.01));
    expect(CotizacionIgv.igvIncluido(total), closeTo(64.07, 0.01));
  });

  test(
    'la numeración usa el mayor código y no la cantidad de cotizaciones',
    () {
      final codigo = CotizacionCodigo.siguiente(
        year: 2026,
        codigosExistentes: const [
          'COT-2026-0001',
          'COT-2026-0001-V2',
          'COT-2026-0005',
          'COT-2026-0005-V3',
        ],
      );

      expect(codigo, 'COT-2026-0006');
    },
  );

  testWidgets(
    'la tarjeta usa la cotización vigente y muestra solo acciones funcionales',
    (tester) async {
      final pedido = PedidoResumen(
        id: 'pedido-1',
        codigo: 'PED-2026-0001',
        fecha: DateTime(2026, 7, 23),
        estado: 'Pendiente',
        sincronizado: false,
        guardadoLocal: true,
        clienteId: 'cliente-1',
        clienteNombre: 'Ferretería Central',
        telefono: '999999999',
        direccion: 'Av. Principal 100',
        referencia: '',
        cantidadProductos: 1,
        cantidadPresentaciones: 1,
        productosResumen: const ['Perno'],
        subtotalConocido: 100,
        productosSinPrecio: 1,
        hojaCodigo: 'HP-2026-001',
        vendedor: 'Vendedor',
        cotizacionVigente: true,
        subtotalProductos: 590,
        descuentoCotizado: 0,
        totalSinIgv: 500,
        igv: 90,
        totalCotizado: 590,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 420, child: PedidoCard(pedido: pedido)),
          ),
        ),
      );

      expect(find.text('Subtotal sin IGV'), findsOneWidget);
      expect(find.text('IGV (18 %)'), findsOneWidget);
      expect(find.text('S/ 590.00'), findsOneWidget);
      expect(find.textContaining('pendiente(s) de valorización'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text('Editar precio'), findsOneWidget);
      expect(find.text('Reintentar sincronización'), findsOneWidget);
      expect(find.text('Exportar resumen'), findsNothing);
      expect(find.text('Editar pedido'), findsNothing);
    },
    tags: const ['baseline-known-failure'],
  );

  testWidgets('la tarjeta de cliente no incluye el botón Pedido', (
    tester,
  ) async {
    final cliente = Cliente(
      id: 'cliente-1',
      nombre: 'Ferretería Central',
      tipo: 'Empresa',
      telefono: '999999999',
      ruc: '20600000001',
      direccion: 'Av. Principal 100',
      activo: true,
      pedidosCount: 2,
      observaciones: '',
      fechaRegistro: DateTime(2026, 7, 23),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 340,
            child: ClienteCard(cliente: cliente),
          ),
        ),
      ),
    );

    expect(find.widgetWithText(ElevatedButton, 'Pedido'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Ver'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Editar'), findsOneWidget);
  });
}

PedidoResumen _pedido({
  required String id,
  required String hoja,
  required String estado,
}) => PedidoResumen(
  id: id,
  codigo: 'PED-$id',
  fecha: DateTime(2026, 7, 22),
  estado: estado,
  sincronizado: false,
  guardadoLocal: true,
  clienteId: 'cliente-$id',
  clienteNombre: 'Cliente $id',
  telefono: '999999999',
  direccion: 'Dirección',
  referencia: '',
  cantidadProductos: 1,
  cantidadPresentaciones: 1,
  productosResumen: const ['Perno'],
  subtotalConocido: 100,
  productosSinPrecio: 0,
  hojaCodigo: hoja,
  vendedor: 'Vendedor',
);
