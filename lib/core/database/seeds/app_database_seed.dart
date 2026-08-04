part of '../app_database.dart';

extension _AppDatabaseSeed on AppDatabase {
  Future<void> _seed(Database db) async {
    final empresaIds = <String, int>{};
    for (final nombre in [
      'DINA',
      'Garibaldi',
      'Rumi Import',
      'Dubau',
      'Otra',
    ]) {
      empresaIds[nombre] = await db.insert('empresas', {
        'nombre': nombre,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    const marcasEmpresas = {
      'DINA': 'DINA',
      'Garibaldi': 'Garibaldi',
      'Rumi': 'Rumi Import',
      'Dubau': 'Dubau',
      'Otra': 'Otra',
    };
    final marcaIds = <String, int>{};
    for (final entry in marcasEmpresas.entries) {
      marcaIds[entry.key] = await db.insert('marcas', {
        'empresa_id': empresaIds[entry.value],
        'nombre': entry.key,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    for (final empresa in empresaIds.entries) {
      await db.insert('marcas', {
        'empresa_id': empresa.value,
        'nombre': 'Sin marca',
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
    }
    const categorias = {
      'Pernería': ['Pernos métricos', 'Pernos pulgada'],
      'Herramientas eléctricas': ['Rotomartillos', 'Amoladoras'],
      'Herramientas manuales': ['Llaves', 'Martillos'],
      'Purificadores': ['Ultrafiltración', 'Ósmosis inversa'],
      'Limpieza': ['Accesorios de limpieza'],
    };
    const atributos = {
      'Pernería': [
        ('Rosca', 'texto', 0),
        ('Clase', 'texto', 0),
        ('Acabado', 'texto', 0),
        ('Norma', 'texto', 0),
        ('Diámetro', 'texto', 1),
        ('Largo', 'texto', 1),
      ],
      'Herramientas eléctricas': [
        ('Voltaje', 'texto', 0),
        ('Potencia', 'texto', 0),
        ('RPM', 'numero', 0),
      ],
      'Herramientas manuales': [
        ('Medida', 'texto', 0),
        ('Material', 'texto', 0),
        ('Peso', 'numero', 0),
        ('Tipo de mango', 'texto', 0),
      ],
      'Purificadores': [
        ('Tecnología', 'texto', 0),
        ('Número de etapas', 'numero', 0),
        ('Alto (cm)', 'numero', 0),
        ('Ancho (cm)', 'numero', 0),
        ('Garantía', 'texto', 0),
        ('Requiere electricidad', 'booleano', 0),
      ],
    };
    final categoriaIds = <String, int>{};
    for (final entry in categorias.entries) {
      final categoriaId = await db.insert('categorias', {
        'nombre': entry.key,
        'estado': 1,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      categoriaIds[entry.key] = categoriaId;
      for (final subcategoria in entry.value) {
        await db.insert('categorias', {
          'categoria_padre_id': categoriaId,
          'nombre': subcategoria,
          'estado': 1,
          'actualizado_en': DateTime.now().toIso8601String(),
        });
      }
      for (final atributo in atributos[entry.key] ?? const []) {
        await db.insert('atributos_def', {
          'categoria_id': categoriaId,
          'nombre': atributo.$1,
          'tipo': atributo.$2,
          'es_variante': atributo.$3,
        });
      }
    }
    const relacionesIniciales = {
      'DINA': ['Pernería'],
      'Rumi': ['Pernería'],
      'Garibaldi': ['Herramientas eléctricas', 'Herramientas manuales'],
      'Dubau': ['Limpieza'],
      'Otra': ['Purificadores'],
    };
    for (final entry in relacionesIniciales.entries) {
      for (final categoria in entry.value) {
        await db.insert('marca_categorias', {
          'marca_id': marcaIds[entry.key],
          'categoria_id': categoriaIds[categoria],
          'estado': 1,
          'actualizado_en': DateTime.now().toIso8601String(),
        });
      }
    }
    final ahora = DateTime.now().toIso8601String();
    const productosDemo = [
      (
        'demo-1',
        'ABZ-001',
        'Abrazadera liviana 1 oreja',
        'DINA',
        'DINA',
        'Pernería',
        'UND',
        1.95,
      ),
      (
        'demo-2',
        'PER-002',
        'Perno hexagonal grado 2 UNC',
        'Rumi Import',
        'Rumi',
        'Pernería',
        'Ciento',
        18.50,
      ),
      (
        'demo-3',
        'TAL-020',
        'Taladro impacto 20V',
        'Garibaldi',
        'Garibaldi',
        'Herramientas eléctricas',
        'UND',
        null,
      ),
      (
        'demo-4',
        'ESC-011',
        'Escobilla lavandera',
        'Dubau',
        'Dubau',
        'Limpieza',
        'Docena',
        12.00,
      ),
    ];
    for (final producto in productosDemo) {
      await db.insert('productos', {
        'id': producto.$1,
        'codigo': producto.$2,
        'nombre': producto.$3,
        'empresa': producto.$4,
        'marca': producto.$5,
        'categoria': producto.$6,
        'tipo_registro': 'unico',
        'unidad_venta': producto.$7,
        'precio': producto.$8,
        'sin_precio': producto.$8 == null ? 1 : 0,
        'activo': 1,
        'creado_en': ahora,
      });
    }
    await _asegurarHojaInicial(db);
  }
}
