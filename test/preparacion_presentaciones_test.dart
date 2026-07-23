import 'package:app_catalogo/features/pedidos/domain/entities/pedido_preparacion.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/producto_consolidado.dart';
import 'package:app_catalogo/features/pedidos/presentation/dialogs/confirmar_carga_dialog.dart';
import 'package:app_catalogo/features/pedidos/presentation/dialogs/pedido_productos_cargados_dialog.dart';
import 'package:app_catalogo/features/pedidos/presentation/dialogs/registrar_preparacion_dialog.dart';
import 'package:app_catalogo/features/pedidos/presentation/dialogs/registrar_preparacion_producto_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el consolidado conserva cada presentación y suma su equivalencia', () {
    final producto = _productoConsolidado();
    final presentaciones = {
      for (final item in producto.presentaciones) item.presentacion: item,
    };

    expect(producto.totalRequerido, 272);
    expect(producto.equivalenciaTotalTexto, '272 unidades');
    expect(presentaciones['Caja']?.solicitadaTexto, '3 cajas');
    expect(presentaciones['Caja']?.preparadaTexto, '2 cajas');
    expect(presentaciones['Caja']?.pendienteTexto, '1 caja');
    expect(presentaciones['Ciento']?.solicitadaTexto, '2 cientos');
    expect(presentaciones['Ciento']?.preparadaTexto, '1 ciento');
    expect(presentaciones['Docena']?.pendienteTexto, '1 docena');
  });

  test('el pedido calcula progreso usando presentaciones comerciales', () {
    final pedido = _pedidoPreparacion(cargado: false, parcial: true);

    expect(pedido.presentacionesSolicitadas, 5);
    expect(pedido.presentacionesPreparadas, 4);
    expect(pedido.presentacionesPendientes, 1);
    expect(pedido.unidadesSolicitadas, 260);
    expect(pedido.unidadesPreparadas, 240);
    expect(pedido.listoParaCargar, isFalse);
    expect(pedido.resumenPresentaciones, containsAll(['2 cajas', '2 cientos']));
  });

  testWidgets(
    'la preparación por pedido inicia en el pendiente y limita el contador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(760, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      PreparacionProductoDraft? result;
      final pedido = PedidoPreparacion(
        id: 'pedido-1',
        codigo: 'PED-0001',
        cliente: 'Cliente prueba',
        telefono: '999999999',
        direccion: 'Dirección',
        referencia: '',
        fecha: DateTime(2026, 7, 23),
        estadoPedido: 'En proceso',
        estadoCarga: 'pendiente_carga',
        paquetes: 0,
        productos: const [
          ProductoPreparacion(
            pedidoItemId: 'item-1',
            productoId: 'producto-1',
            nombre: 'Perno hexagonal',
            codigo: 'PER-001',
            presentacion: 'Caja',
            equivalencia: '1 Caja = 20 UND',
            cantidadSolicitada: 3,
            cantidadPreparada: 0,
            factorUnidadBase: 20,
            unidadBase: 'UND',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await RegistrarPreparacionDialog.show(
                    context,
                    pedido: pedido,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Completo'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('Preparación parcial'), findsOneWidget);
      expect(find.textContaining('Quedará pendiente: 1 caja'), findsOneWidget);

      await tester.tap(find.text('Confirmar preparación'));
      await tester.pumpAndSettle();
      expect(result?.asignaciones.single.cantidad, 2);
      expect(result?.asignaciones.single.presentacion, 'Caja');
      expect(result?.asignaciones.single.factorUnidadBase, 20);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ver productos cargados muestra presentación y equivalencia secundaria',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final pedido = _pedidoPreparacion(cargado: true, parcial: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    PedidoProductosCargadosDialog.show(context, pedido: pedido),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Productos cargados'), findsOneWidget);
      expect(find.text('Completado: 3 cajas'), findsOneWidget);
      expect(find.text('Completado: 2 cientos'), findsOneWidget);
      expect(find.textContaining('Equivalencia: 60 unidades'), findsOneWidget);
      expect(find.textContaining('Equivalencia: 200 unidades'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirmar carga sugiere paquetes y espera la confirmación', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CargaPedidoConfirmada? result;
    final pedido = _pedidoPreparacion(cargado: false, parcial: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ConfirmarCargaDialog.show(
                  context,
                  pedido: pedido,
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(
      find.text('¿Marcar el pedido PED-0001 como cargado?'),
      findsOneWidget,
    );
    expect(find.text('3 cajas'), findsOneWidget);
    expect(find.text('2 cientos'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar carga'));
    await tester.pumpAndSettle();

    expect(result?.paquetes, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el registro desde consolidado se adapta a pantalla angosta', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => RegistrarPreparacionProductoDialog.show(
                context,
                producto: _productoConsolidado(),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar avance de preparación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

ProductoConsolidado _productoConsolidado() => ProductoConsolidado(
  key: 'producto-1|PER-001|1/4',
  productoId: 'producto-1',
  codigo: 'PER-001',
  nombre: 'Perno hexagonal',
  variante: '1/4',
  presentacion: 'UND',
  equivalencia: '1 UND',
  unidadBase: 'UND',
  totalRequerido: 272,
  totalPreparado: 140,
  distribucion: [
    DistribucionPedido(
      pedidoItemId: 'item-1',
      pedidoId: 'pedido-1',
      codigoPedido: 'PED-0001',
      cliente: 'Cliente uno',
      telefono: '999999999',
      cantidadSolicitada: 60,
      cantidadPreparada: 40,
      fecha: DateTime(2026, 7, 21),
      estadoPedido: 'En proceso',
      presentacion: 'Caja',
      equivalencia: '1 Caja = 20 UND',
      cantidadOriginal: 3,
      unidadBase: 'UND',
    ),
    DistribucionPedido(
      pedidoItemId: 'item-2',
      pedidoId: 'pedido-2',
      codigoPedido: 'PED-0002',
      cliente: 'Cliente dos',
      telefono: '988888888',
      cantidadSolicitada: 200,
      cantidadPreparada: 100,
      fecha: DateTime(2026, 7, 22),
      estadoPedido: 'En proceso',
      presentacion: 'Ciento',
      equivalencia: '1 Ciento = 100 UND',
      cantidadOriginal: 2,
      unidadBase: 'UND',
    ),
    DistribucionPedido(
      pedidoItemId: 'item-3',
      pedidoId: 'pedido-3',
      codigoPedido: 'PED-0003',
      cliente: 'Cliente tres',
      telefono: '977777777',
      cantidadSolicitada: 12,
      cantidadPreparada: 0,
      fecha: DateTime(2026, 7, 23),
      estadoPedido: 'Pendiente',
      presentacion: 'Docena',
      equivalencia: '1 Docena = 12 UND',
      cantidadOriginal: 1,
      unidadBase: 'UND',
    ),
  ],
);

PedidoPreparacion _pedidoPreparacion({
  required bool cargado,
  required bool parcial,
}) => PedidoPreparacion(
  id: 'pedido-1',
  codigo: 'PED-0001',
  cliente: 'Cliente prueba',
  telefono: '999999999',
  direccion: 'Dirección',
  referencia: '',
  fecha: DateTime(2026, 7, 23),
  estadoPedido: 'Listo para entregar',
  estadoCarga: cargado ? 'cargado' : 'pendiente_carga',
  paquetes: cargado ? 2 : 0,
  productos: [
    ProductoPreparacion(
      pedidoItemId: 'item-1',
      productoId: 'producto-1',
      nombre: 'Perno en caja',
      codigo: 'PER-001',
      presentacion: 'Caja',
      equivalencia: '1 Caja = 20 UND',
      cantidadSolicitada: 3,
      cantidadPreparada: parcial ? 2 : 3,
      factorUnidadBase: 20,
      unidadBase: 'UND',
    ),
    const ProductoPreparacion(
      pedidoItemId: 'item-2',
      productoId: 'producto-1',
      nombre: 'Perno por ciento',
      codigo: 'PER-001',
      presentacion: 'Ciento',
      equivalencia: '1 Ciento = 100 UND',
      cantidadSolicitada: 2,
      cantidadPreparada: 2,
      factorUnidadBase: 100,
      unidadBase: 'UND',
    ),
  ],
);
