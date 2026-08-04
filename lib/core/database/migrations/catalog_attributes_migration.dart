part of '../app_database.dart';

extension _CatalogAttributesMigration on AppDatabase {
  Future<void> _migrarAtributosDef(Database db) async {
    final legacyTable = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' AND name = 'atributos_def'",
    );
    if (legacyTable.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final rows = await db.rawQuery('''
      SELECT a.*, c.nombre AS categoria_nombre
      FROM atributos_def a
      INNER JOIN categorias c ON c.id = a.categoria_id
      ORDER BY a.id
    ''');
    for (final row in rows) {
      final id = 'legacy-atributo-${row['id']}';
      final exists = await db.query(
        'categoria_atributos',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (exists.isNotEmpty) continue;
      final name = row['nombre'] as String;
      final legacyType = (row['tipo'] as String).toLowerCase();
      final type = switch (legacyType) {
        'numero' => 'numero',
        'booleano' => 'si_no',
        _ => 'texto_corto',
      };
      await db.insert('categoria_atributos', {
        'id': id,
        'categoria_id': row['categoria_id'],
        'nombre': name,
        'clave': _claveAtributo(name),
        'tipo_dato': type,
        'nivel_captura': (row['es_variante'] as int? ?? 0) == 1
            ? 'variante'
            : 'familia',
        'requerido_activar': 0,
        'visible_ficha': 1,
        'filtrable': 1,
        'puede_ser_eje': (row['es_variante'] as int? ?? 0) == 1 ? 1 : 0,
        'activo_nuevos': 1,
        'orden': row['id'],
        'estado': 1,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  String _claveAtributo(String value) {
    var normalized = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      'ø': 'diametro',
    };
    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
