import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:app_catalogo/features/pedidos/data/datasources/pedidos_local_datasource.dart';
import 'package:app_catalogo/features/pedidos/domain/entities/pedido.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late PedidosLocalDatasource datasource;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_pedidos_transaction_test_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: p.join(tempDirectory.path, 'pedidos.db'),
    );
    datasource = PedidosLocalDatasource(appDatabase);
    await appDatabase.open();
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'guardar pedido confirma cabecera, item, cliente y vendedor juntos',
    () async {
      final database = await appDatabase.database;
      final hoja = await datasource.obtenerHojaActiva();
      final producto = (await database.query(
        'productos',
        columns: ['id', 'codigo', 'nombre'],
        limit: 1,
      )).single;
      final pedidosAntes = _count(
        await database.rawQuery('SELECT COUNT(*) FROM pedidos'),
      );
      final itemsAntes = _count(
        await database.rawQuery('SELECT COUNT(*) FROM pedido_items'),
      );

      final saved = await datasource.guardarPedido(
        hoja: hoja!,
        cliente: const ClientePedido(
          nombre: 'Cliente transaccional',
          telefono: '999111222',
        ),
        items: [
          PedidoItem(
            productoId: producto['id']! as String,
            codigo: producto['codigo']! as String,
            nombre: producto['nombre']! as String,
            presentacion: 'Unidad',
            equivalencia: '1 UND',
            cantidad: 2,
            precioUnitario: 10,
          ),
        ],
        vendedor: 'Vendedora Norte',
      );

      final pedido = (await database.query(
        'pedidos',
        where: 'id = ?',
        whereArgs: [saved.id],
      )).single;
      expect(
        _count(await database.rawQuery('SELECT COUNT(*) FROM pedidos')),
        pedidosAntes + 1,
      );
      expect(
        _count(await database.rawQuery('SELECT COUNT(*) FROM pedido_items')),
        itemsAntes + 1,
      );
      expect(pedido['vendedor'], 'Vendedora Norte');
      expect(pedido['cliente_id'], isNotNull);
    },
  );

  test('un item inválido revierte pedido y cliente completos', () async {
    final database = await appDatabase.database;
    final hoja = await datasource.obtenerHojaActiva();
    final pedidosAntes = _count(
      await database.rawQuery('SELECT COUNT(*) FROM pedidos'),
    );
    final clientesAntes = _count(
      await database.rawQuery('SELECT COUNT(*) FROM clientes'),
    );

    await expectLater(
      datasource.guardarPedido(
        hoja: hoja!,
        cliente: const ClientePedido(
          nombre: 'Cliente que debe revertirse',
          telefono: '999333444',
        ),
        items: const [
          PedidoItem(
            productoId: 'producto-inexistente',
            codigo: 'INVALIDO',
            nombre: 'Producto inválido',
            presentacion: 'Unidad',
            equivalencia: '1 UND',
            cantidad: 1,
            precioUnitario: 10,
          ),
        ],
        vendedor: 'Vendedora Norte',
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(
      _count(await database.rawQuery('SELECT COUNT(*) FROM pedidos')),
      pedidosAntes,
    );
    expect(
      _count(await database.rawQuery('SELECT COUNT(*) FROM clientes')),
      clientesAntes,
    );
    expect(
      await database.query(
        'clientes',
        where: 'nombre = ?',
        whereArgs: const ['Cliente que debe revertirse'],
      ),
      isEmpty,
    );
  });
}

int _count(List<Map<String, Object?>> rows) => rows.single.values.first! as int;
