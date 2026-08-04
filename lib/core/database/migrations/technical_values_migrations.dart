part of '../app_database.dart';

extension _TechnicalValuesMigrations on AppDatabase {
  Future<void> _migrarValoresTecnicos(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(producto_atributos)');
    final names = columns.map((column) => column['name'] as String).toSet();

    Future<void> addColumn(String name, String sql) async {
      if (!names.contains(name)) await db.execute(sql);
    }

    await addColumn(
      'tipo_valor',
      "ALTER TABLE producto_atributos "
          "ADD COLUMN tipo_valor TEXT NOT NULL DEFAULT 'texto'",
    );
    await addColumn(
      'valor_numero_hasta',
      'ALTER TABLE producto_atributos '
          'ADD COLUMN valor_numero_hasta REAL',
    );
    await addColumn(
      'valor_normalizado_hasta',
      'ALTER TABLE producto_atributos '
          'ADD COLUMN valor_normalizado_hasta REAL',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_producto_atributos_rangos '
      'ON producto_atributos('
      'categoria_atributo_id, '
      'valor_normalizado, '
      'valor_normalizado_hasta'
      ')',
    );

    await _asegurarUnidadesTecnicas(db);
  }

  Future<void> _asegurarUnidadesTecnicas(Database db) async {
    const units = [
      ('unit-hz', 'Hz', 'Hercio', 'Hz', 'Frecuencia', 1.0, 2),
      ('unit-rpm', 'rpm', 'Revolución por minuto', 'rpm', 'Rotación', 1.0, 0),
      ('unit-bpm', 'bpm', 'Golpe por minuto', 'bpm', 'Impactos', 1.0, 0),
      ('unit-nm', 'Nm', 'Newton metro', 'Nm', 'Torque', 1.0, 2),
      ('unit-j', 'J', 'Julio', 'J', 'Energía', 1.0, 2),
      ('unit-bar', 'bar', 'Bar', 'bar', 'Presión', 100000.0, 4),
      (
        'unit-psi',
        'psi',
        'Libra por pulgada cuadrada',
        'psi',
        'Presión',
        6894.757293,
        4,
      ),
      ('unit-mpa', 'MPa', 'Megapascal', 'MPa', 'Presión', 1000000.0, 4),
      (
        'unit-ml-min',
        'ml/min',
        'Mililitro por minuto',
        'ml/min',
        'Caudal',
        1.0,
        3,
      ),
      ('unit-din-s', 'DIN-s', 'Segundo DIN', 'DIN-s', 'Viscosidad', 1.0, 2),
      ('unit-celsius', 'C', 'Grado Celsius', '°C', 'Temperatura', 1.0, 2),
    ];

    for (final unit in units) {
      await db.insert('unidades_medida', {
        'id': unit.$1,
        'codigo': unit.$2,
        'nombre': unit.$3,
        'simbolo': unit.$4,
        'magnitud': unit.$5,
        'factor_a_base': unit.$6,
        'decimales': unit.$7,
        'estado': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _migrarCodigoProveedorVariantes(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(producto_variantes_catalogo)',
    );
    final hasColumn = columns.any(
      (column) => column['name'] == 'codigo_proveedor',
    );
    if (!hasColumn) {
      await db.execute(
        "ALTER TABLE producto_variantes_catalogo "
        "ADD COLUMN codigo_proveedor TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_variantes_codigo_proveedor '
      'ON producto_variantes_catalogo(codigo_proveedor)',
    );
  }
}
