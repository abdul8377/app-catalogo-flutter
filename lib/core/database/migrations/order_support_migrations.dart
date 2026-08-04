part of '../app_database.dart';

extension _OrderSupportMigrations on AppDatabase {
  Future<void> _asegurarColumnasHojas(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(hojas_pedido)');
    final columns = info.map((row) => row['name'] as String).toSet();
    Future<void> addColumn(String name, String definition) async {
      if (!columns.contains(name)) await db.execute(definition);
    }

    await addColumn(
      'vendedor',
      "ALTER TABLE hojas_pedido ADD COLUMN vendedor TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'fecha_cierre',
      'ALTER TABLE hojas_pedido ADD COLUMN fecha_cierre TEXT',
    );
    await addColumn(
      'referencia',
      "ALTER TABLE hojas_pedido ADD COLUMN referencia TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'observacion',
      "ALTER TABLE hojas_pedido ADD COLUMN observacion TEXT NOT NULL DEFAULT ''",
    );
    await addColumn(
      'sincronizado',
      'ALTER TABLE hojas_pedido ADD COLUMN sincronizado INTEGER NOT NULL DEFAULT 0',
    );
    await addColumn(
      'usuario_cierre',
      'ALTER TABLE hojas_pedido ADD COLUMN usuario_cierre TEXT',
    );
    await db.execute('''
      UPDATE hojas_pedido
      SET vendedor = COALESCE(
        NULLIF(vendedor, ''),
        (SELECT p.vendedor FROM pedidos p WHERE p.hoja_id = hojas_pedido.id LIMIT 1),
        'Alfonzo Esteban'
      )
    ''');
  }

  Future<void> _asegurarUnidadesBasePedidos(Database db) async {
    final itemInfo = await db.rawQuery('PRAGMA table_info(pedido_items)');
    final itemColumns = itemInfo.map((row) => row['name'] as String).toSet();
    if (!itemColumns.contains('factor_unidad_base')) {
      await db.execute(
        'ALTER TABLE pedido_items ADD COLUMN factor_unidad_base INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!itemColumns.contains('unidad_base')) {
      await db.execute(
        "ALTER TABLE pedido_items ADD COLUMN unidad_base TEXT NOT NULL DEFAULT 'UND'",
      );
    }

    final preparacionInfo = await db.rawQuery(
      'PRAGMA table_info(preparacion_productos)',
    );
    final preparacionColumns = preparacionInfo
        .map((row) => row['name'] as String)
        .toSet();
    final columnaBaseNueva = !preparacionColumns.contains('cantidad_base');
    if (columnaBaseNueva) {
      await db.execute(
        'ALTER TABLE preparacion_productos ADD COLUMN cantidad_base INTEGER NOT NULL DEFAULT 0',
      );
    }

    final items = await db.query(
      'pedido_items',
      columns: ['id', 'presentacion', 'equivalencia'],
    );
    for (final item in items) {
      final presentacion = item['presentacion'] as String? ?? '';
      final equivalencia = item['equivalencia'] as String? ?? '';
      await db.update(
        'pedido_items',
        {
          'factor_unidad_base': _factorUnidadBase(presentacion, equivalencia),
          'unidad_base': _unidadBase(presentacion, equivalencia),
        },
        where: 'id = ?',
        whereArgs: [item['id']],
      );
    }
    if (columnaBaseNueva) {
      await db.execute('''
        UPDATE preparacion_productos
        SET cantidad_base = cantidad * COALESCE(
          (SELECT factor_unidad_base
           FROM pedido_items
           WHERE pedido_items.id = preparacion_productos.pedido_item_id),
          1
        )
      ''');
    }
  }

  int _factorUnidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toLowerCase();
    final coincidencias = RegExp(r'(\d+)').allMatches(equivalencia).toList();
    final numero = coincidencias.isEmpty ? null : coincidencias.last.group(1);
    final parsed = int.tryParse(numero ?? '');
    if (parsed != null && parsed > 0) return parsed;
    if (texto.contains('millar')) return 1000;
    if (texto.contains('ciento')) return 100;
    if (texto.contains('docena')) return 12;
    if (texto.contains('par')) return 2;
    return 1;
  }

  String _unidadBase(String presentacion, String equivalencia) {
    final texto = '$equivalencia $presentacion'.toUpperCase();
    if (texto.contains('KG')) return 'KG';
    if (texto.contains('LT') || texto.contains('LITRO')) return 'LT';
    if (texto.contains('MT') || texto.contains('METRO')) return 'MT';
    return 'UND';
  }

  Future<void> _asegurarColumnasClientes(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(clientes)');
    final columns = info.map((row) => row['name'] as String).toSet();
    Future<void> addColumn(String name, String definition) async {
      if (!columns.contains(name)) await db.execute(definition);
    }

    await addColumn(
      'tipo',
      "ALTER TABLE clientes ADD COLUMN tipo TEXT NOT NULL DEFAULT 'Persona'",
    );
    await addColumn(
      'foto_ubicacion_path',
      'ALTER TABLE clientes ADD COLUMN foto_ubicacion_path TEXT',
    );
    await addColumn(
      'activo',
      'ALTER TABLE clientes ADD COLUMN activo INTEGER NOT NULL DEFAULT 1',
    );
    await addColumn(
      'actualizado_en',
      'ALTER TABLE clientes ADD COLUMN actualizado_en TEXT',
    );
    await db.execute(
      "UPDATE clientes SET tipo = 'Empresa' WHERE ruc != '' AND tipo = 'Persona'",
    );
  }

  Future<void> _asegurarHojaInicial(Database db) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            "SELECT COUNT(*) FROM hojas_pedido WHERE activa = 1 AND estado = 'Abierta'",
          ),
        ) ??
        0;
    if (count == 0) {
      final year = DateTime.now().year;
      await db.insert('hojas_pedido', {
        'id': 'hoja-inicial-$year',
        'codigo': 'HP-$year-001',
        'estado': 'Abierta',
        'activa': 1,
        'vendedor': 'Alfonzo Esteban',
        'sincronizado': 0,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }
}
