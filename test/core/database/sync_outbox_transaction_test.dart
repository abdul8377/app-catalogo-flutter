import 'dart:io';

import 'package:app_catalogo/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase appDatabase;
  late Database database;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'app_catalogo_sync_outbox_test_',
    );
    appDatabase = AppDatabase.forTesting(
      factory: databaseFactoryFfi,
      path: p.join(tempDirectory.path, 'catalogo.db'),
    );
    database = await appDatabase.database;
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDirectory.existsSync()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('confirma dato local y evento outbox en la misma transacción', () async {
    await database.transaction((transaction) async {
      await transaction.insert('clientes', _cliente('cliente-commit'));
    });

    expect(
      await database.query(
        'clientes',
        where: 'id = ?',
        whereArgs: const ['cliente-commit'],
      ),
      hasLength(1),
    );
    final events = await database.query(
      'sync_queue',
      where: 'entidad = ? AND entidad_id = ?',
      whereArgs: const ['CLIENT', 'cliente-commit'],
    );
    expect(events, hasLength(1));
    expect(events.single['accion'], 'UPSERT');
    expect(events.single['estado'], 'pending');
  });

  test('rollback revierte el dato y también su evento outbox', () async {
    await expectLater(
      database.transaction((transaction) async {
        await transaction.insert('clientes', _cliente('cliente-rollback'));
        throw StateError('forzar rollback');
      }),
      throwsStateError,
    );

    expect(
      await database.query(
        'clientes',
        where: 'id = ?',
        whereArgs: const ['cliente-rollback'],
      ),
      isEmpty,
    );
    expect(
      await database.query(
        'sync_queue',
        where: 'entidad_id = ?',
        whereArgs: const ['cliente-rollback'],
      ),
      isEmpty,
    );
  });

  test('aplicar un cambio remoto no vuelve a encolarlo', () async {
    await database.transaction((transaction) async {
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 1,
      }, where: 'id = 1');
      await transaction.insert('clientes', _cliente('cliente-remoto'));
      await transaction.update('sync_runtime_context', const {
        'applying_remote': 0,
      }, where: 'id = 1');
    });

    expect(
      await database.query(
        'clientes',
        where: 'id = ?',
        whereArgs: const ['cliente-remoto'],
      ),
      hasLength(1),
    );
    expect(
      await database.query(
        'sync_queue',
        where: 'entidad_id = ?',
        whereArgs: const ['cliente-remoto'],
      ),
      isEmpty,
    );
  });

  test('asigna identidad global a tablas con id entero y las encola', () async {
    final localId = await database.insert('empresas', {
      'nombre': 'Empresa sincronizable',
    });

    final company = (await database.query(
      'empresas',
      where: 'id = ?',
      whereArgs: [localId],
    )).single;
    final syncId = company['sync_id'] as String;
    final events = await database.query(
      'sync_queue',
      where: 'entidad = ? AND entidad_id = ?',
      whereArgs: ['COMPANY', syncId],
    );

    expect(syncId, isNotEmpty);
    expect(events, hasLength(1));
  });

  test('encola archivos por separado dentro de la transacción local', () async {
    final client = _cliente('cliente-con-foto')
      ..['foto_ubicacion_path'] = r'D:\fotos\ubicacion.jpg';
    await database.insert('clientes', client);

    final files = await database.query(
      'sync_file_queue',
      where: 'owner_type = ? AND owner_id = ?',
      whereArgs: const ['CLIENT', 'cliente-con-foto'],
    );
    expect(files, hasLength(1));
    expect(files.single['status'], 'pending');
  });
}

Map<String, Object?> _cliente(String id) => {
  'id': id,
  'nombre': 'Cliente de prueba',
  'telefono': '999999999',
  'creado_en': '2026-08-04T00:00:00.000Z',
};
