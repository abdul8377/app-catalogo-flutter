import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/estructura_catalogo.dart';

class EstructuraCatalogoLocalDatasource {
  const EstructuraCatalogoLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<EstructuraCatalogoSnapshot> obtenerEstructura() async {
    final db = await _db;
    final results = await Future.wait([
      db.rawQuery('''
        SELECT e.*,
               COUNT(DISTINCT m.id) AS cantidad_marcas,
               COUNT(DISTINCT mc.categoria_id) AS cantidad_categorias,
               COUNT(DISTINCT p.id) AS cantidad_productos,
               GROUP_CONCAT(DISTINCT m.nombre) AS principales_marcas
        FROM empresas e
        LEFT JOIN marcas m ON m.empresa_id = e.id
        LEFT JOIN marca_categorias mc
          ON mc.marca_id = m.id AND mc.estado = 1
        LEFT JOIN productos p ON LOWER(p.empresa) = LOWER(e.nombre)
        GROUP BY e.id
        ORDER BY e.nombre COLLATE NOCASE
      '''),
      db.rawQuery('''
        SELECT m.*,
               e.nombre AS empresa_nombre,
               GROUP_CONCAT(DISTINCT c.nombre) AS categorias,
               COUNT(DISTINCT p.id) AS cantidad_productos
        FROM marcas m
        INNER JOIN empresas e ON e.id = m.empresa_id
        LEFT JOIN marca_categorias mc
          ON mc.marca_id = m.id AND mc.estado = 1
        LEFT JOIN categorias c ON c.id = mc.categoria_id
        LEFT JOIN productos p
          ON LOWER(p.marca) = LOWER(m.nombre)
         AND LOWER(p.empresa) = LOWER(e.nombre)
        GROUP BY m.id
        ORDER BY e.nombre COLLATE NOCASE, m.nombre COLLATE NOCASE
      '''),
      db.rawQuery('''
        SELECT c.*,
               padre.nombre AS categoria_padre_nombre,
               GROUP_CONCAT(DISTINCT m.nombre) AS marcas,
               GROUP_CONCAT(DISTINCT e.nombre) AS empresas,
               COUNT(DISTINCT p.id) AS cantidad_productos
        FROM categorias c
        LEFT JOIN categorias padre ON padre.id = c.categoria_padre_id
        LEFT JOIN marca_categorias mc
          ON mc.categoria_id = COALESCE(c.categoria_padre_id, c.id)
         AND mc.estado = 1
        LEFT JOIN marcas m ON m.id = mc.marca_id
        LEFT JOIN empresas e ON e.id = m.empresa_id
        LEFT JOIN productos p
          ON (
            c.categoria_padre_id IS NULL
            AND LOWER(p.categoria) = LOWER(c.nombre)
          ) OR (
            c.categoria_padre_id IS NOT NULL
            AND LOWER(p.subcategoria) = LOWER(c.nombre)
          )
        GROUP BY c.id
        ORDER BY COALESCE(padre.nombre, c.nombre) COLLATE NOCASE,
                 c.categoria_padre_id IS NOT NULL,
                 c.nombre COLLATE NOCASE
      '''),
      db.query('marca_categorias'),
    ]);

    return EstructuraCatalogoSnapshot(
      empresas: results[0].map(_empresaFromMap).toList(),
      marcas: results[1].map(_marcaFromMap).toList(),
      categorias: results[2].map(_categoriaFromMap).toList(),
      relaciones: results[3]
          .map(
            (row) => RelacionMarcaCategoria(
              marcaId: row['marca_id'] as int,
              categoriaId: row['categoria_id'] as int,
              activa: (row['estado'] as int? ?? 1) == 1,
            ),
          )
          .toList(),
    );
  }

  Future<void> guardarEmpresa({
    int? id,
    required EmpresaCatalogoDraft empresa,
  }) async {
    final nombre = empresa.nombre.trim();
    if (nombre.isEmpty) throw ArgumentError('El nombre es obligatorio.');
    final db = await _db;
    await db.transaction((txn) async {
      await _validarNombreEmpresa(txn, nombre, excluirId: id);
      final now = DateTime.now().toIso8601String();
      late int entityId;
      if (id == null) {
        entityId = await txn.insert('empresas', {
          'nombre': nombre,
          'ruc': empresa.ruc.trim(),
          'telefono': empresa.telefono.trim(),
          'direccion': empresa.direccion.trim(),
          'estado': 1,
          'actualizado_en': now,
        });
        await txn.insert('marcas', {
          'empresa_id': entityId,
          'nombre': 'Sin marca',
          'estado': 1,
          'actualizado_en': now,
        });
      } else {
        final previous = await txn.query(
          'empresas',
          columns: ['nombre'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (previous.isEmpty) throw StateError('La empresa ya no existe.');
        final oldName = previous.first['nombre'] as String;
        await txn.update(
          'empresas',
          {
            'nombre': nombre,
            'ruc': empresa.ruc.trim(),
            'telefono': empresa.telefono.trim(),
            'direccion': empresa.direccion.trim(),
            'actualizado_en': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        if (oldName.toLowerCase() != nombre.toLowerCase()) {
          await txn.update(
            'productos',
            {'empresa': nombre},
            where: 'LOWER(empresa) = LOWER(?)',
            whereArgs: [oldName],
          );
        }
        entityId = id;
      }
      await _encolar(
        txn,
        entidad: 'empresa',
        entidadId: '$entityId',
        accion: id == null ? 'crear' : 'actualizar',
        payload: {
          'id': entityId,
          'nombre': nombre,
          'ruc': empresa.ruc.trim(),
          'telefono': empresa.telefono.trim(),
          'direccion': empresa.direccion.trim(),
        },
      );
    });
  }

  Future<void> guardarMarca({
    int? id,
    required MarcaCatalogoDraft marca,
  }) async {
    final nombre = marca.nombre.trim();
    if (nombre.isEmpty) throw ArgumentError('El nombre es obligatorio.');
    final db = await _db;
    await db.transaction((txn) async {
      final company = await txn.query(
        'empresas',
        columns: ['id', 'nombre', 'estado'],
        where: 'id = ?',
        whereArgs: [marca.empresaId],
        limit: 1,
      );
      if (company.isEmpty || (company.first['estado'] as int? ?? 1) != 1) {
        throw StateError('Selecciona una empresa activa.');
      }
      final duplicateArgs = <Object?>[marca.empresaId, nombre];
      if (id != null) duplicateArgs.add(id);
      final duplicate = await txn.rawQuery('''
        SELECT id FROM marcas
        WHERE empresa_id = ? AND LOWER(TRIM(nombre)) = LOWER(TRIM(?))
          ${id == null ? '' : 'AND id <> ?'}
        LIMIT 1
        ''', duplicateArgs);
      if (duplicate.isNotEmpty) {
        throw StateError('Ya existe una marca con ese nombre en la empresa.');
      }
      final now = DateTime.now().toIso8601String();
      late int entityId;
      if (id == null) {
        entityId = await txn.insert('marcas', {
          'empresa_id': marca.empresaId,
          'nombre': nombre,
          'estado': 1,
          'actualizado_en': now,
        });
      } else {
        final previous = await txn.rawQuery(
          '''
          SELECT m.nombre, e.nombre AS empresa
          FROM marcas m
          INNER JOIN empresas e ON e.id = m.empresa_id
          WHERE m.id = ?
          ''',
          [id],
        );
        if (previous.isEmpty) throw StateError('La marca ya no existe.');
        await txn.update(
          'marcas',
          {
            'empresa_id': marca.empresaId,
            'nombre': nombre,
            'actualizado_en': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await txn.update(
          'productos',
          {'empresa': company.first['nombre'] as String, 'marca': nombre},
          where: 'LOWER(empresa) = LOWER(?) AND LOWER(marca) = LOWER(?)',
          whereArgs: [
            previous.first['empresa'] as String,
            previous.first['nombre'] as String,
          ],
        );
        entityId = id;
      }
      await _guardarRelacionesTxn(
        txn,
        marcaId: entityId,
        categoriaIds: marca.categoriaIds,
      );
      await _encolar(
        txn,
        entidad: 'marca',
        entidadId: '$entityId',
        accion: id == null ? 'crear' : 'actualizar',
        payload: {
          'id': entityId,
          'empresa_id': marca.empresaId,
          'nombre': nombre,
          'categorias': marca.categoriaIds.toList(),
        },
      );
    });
  }

  Future<void> guardarCategoria({
    int? id,
    required CategoriaCatalogoDraft categoria,
  }) async {
    final nombre = categoria.nombre.trim();
    if (nombre.isEmpty) throw ArgumentError('El nombre es obligatorio.');
    if (id != null && categoria.categoriaPadreId == id) {
      throw StateError('Una categoría no puede ser su propia superior.');
    }
    final db = await _db;
    await db.transaction((txn) async {
      if (categoria.categoriaPadreId != null) {
        await _validarPadreCategoria(
          txn,
          categoria.categoriaPadreId!,
          categoriaId: id,
        );
      }
      final duplicateArgs = <Object?>[
        nombre,
        categoria.categoriaPadreId,
        categoria.categoriaPadreId,
      ];
      if (id != null) duplicateArgs.add(id);
      final duplicate = await txn.rawQuery('''
        SELECT id FROM categorias
        WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?))
          AND (
            (categoria_padre_id IS NULL AND ? IS NULL)
            OR categoria_padre_id = ?
          )
          ${id == null ? '' : 'AND id <> ?'}
        LIMIT 1
        ''', duplicateArgs);
      if (duplicate.isNotEmpty) {
        throw StateError('Ya existe una categoría con ese nombre en el nivel.');
      }
      final now = DateTime.now().toIso8601String();
      late int entityId;
      if (id == null) {
        entityId = await txn.insert('categorias', {
          'categoria_padre_id': categoria.categoriaPadreId,
          'nombre': nombre,
          'descripcion': categoria.descripcion.trim(),
          'estado': 1,
          'actualizado_en': now,
        });
      } else {
        final previous = await txn.query(
          'categorias',
          columns: ['nombre', 'categoria_padre_id'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (previous.isEmpty) throw StateError('La categoría ya no existe.');
        final hadParent = previous.first['categoria_padre_id'] != null;
        final hasParent = categoria.categoriaPadreId != null;
        if (hadParent != hasParent) {
          throw StateError(
            'No se puede convertir una categoría en subcategoría o viceversa si ya existe.',
          );
        }
        await txn.update(
          'categorias',
          {
            'categoria_padre_id': categoria.categoriaPadreId,
            'nombre': nombre,
            'descripcion': categoria.descripcion.trim(),
            'actualizado_en': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        final oldName = previous.first['nombre'] as String;
        await txn.update(
          'productos',
          {hadParent ? 'subcategoria' : 'categoria': nombre},
          where:
              'LOWER(${hadParent ? 'subcategoria' : 'categoria'}) = LOWER(?)',
          whereArgs: [oldName],
        );
        entityId = id;
      }
      await _encolar(
        txn,
        entidad: 'categoria',
        entidadId: '$entityId',
        accion: id == null ? 'crear' : 'actualizar',
        payload: {
          'id': entityId,
          'categoria_padre_id': categoria.categoriaPadreId,
          'nombre': nombre,
          'descripcion': categoria.descripcion.trim(),
        },
      );
    });
  }

  Future<void> guardarRelaciones({
    required int marcaId,
    required Set<int> categoriaIds,
  }) async {
    final db = await _db;
    await db.transaction(
      (txn) => _guardarRelacionesTxn(
        txn,
        marcaId: marcaId,
        categoriaIds: categoriaIds,
      ),
    );
  }

  Future<ImpactoEstructura> obtenerImpacto({
    required String tipo,
    required int id,
  }) async {
    final db = await _db;
    switch (tipo) {
      case 'empresa':
        final row = (await db.rawQuery(
          '''
          SELECT COUNT(DISTINCT m.id) AS marcas,
                 COUNT(DISTINCT mc.categoria_id) AS categorias,
                 COUNT(DISTINCT p.id) AS productos
          FROM empresas e
          LEFT JOIN marcas m ON m.empresa_id = e.id
          LEFT JOIN marca_categorias mc
            ON mc.marca_id = m.id AND mc.estado = 1
          LEFT JOIN productos p
            ON LOWER(p.empresa) = LOWER(e.nombre) AND p.activo = 1
          WHERE e.id = ?
          ''',
          [id],
        )).first;
        return _impactoFromMap(row);
      case 'marca':
        final row = (await db.rawQuery(
          '''
          SELECT 0 AS marcas,
                 COUNT(DISTINCT mc.categoria_id) AS categorias,
                 COUNT(DISTINCT p.id) AS productos
          FROM marcas m
          INNER JOIN empresas e ON e.id = m.empresa_id
          LEFT JOIN marca_categorias mc
            ON mc.marca_id = m.id AND mc.estado = 1
          LEFT JOIN productos p
            ON LOWER(p.marca) = LOWER(m.nombre)
           AND LOWER(p.empresa) = LOWER(e.nombre)
           AND p.activo = 1
          WHERE m.id = ?
          ''',
          [id],
        )).first;
        return _impactoFromMap(row);
      default:
        final row = (await db.rawQuery(
          '''
          SELECT COUNT(DISTINCT mc.marca_id) AS marcas,
                 COUNT(DISTINCT hija.id) AS categorias,
                 COUNT(DISTINCT p.id) AS productos
          FROM categorias c
          LEFT JOIN categorias hija ON hija.categoria_padre_id = c.id
          LEFT JOIN marca_categorias mc
            ON mc.categoria_id = COALESCE(c.categoria_padre_id, c.id)
           AND mc.estado = 1
          LEFT JOIN productos p
            ON (
              c.categoria_padre_id IS NULL
              AND LOWER(p.categoria) = LOWER(c.nombre)
            ) OR (
              c.categoria_padre_id IS NOT NULL
              AND LOWER(p.subcategoria) = LOWER(c.nombre)
            )
          WHERE c.id = ? AND (p.id IS NULL OR p.activo = 1)
          ''',
          [id],
        )).first;
        return _impactoFromMap(row);
    }
  }

  Future<void> cambiarEstado({
    required String tipo,
    required int id,
    required bool activo,
  }) async {
    final table = switch (tipo) {
      'empresa' => 'empresas',
      'marca' => 'marcas',
      'categoria' => 'categorias',
      _ => throw ArgumentError('Tipo de estructura no válido.'),
    };
    final db = await _db;
    await db.transaction((txn) async {
      if (activo) await _validarActivacion(txn, tipo: tipo, id: id);
      final updated = await txn.update(
        table,
        {
          'estado': activo ? 1 : 0,
          'actualizado_en': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated != 1) throw StateError('El registro ya no existe.');
      await _encolar(
        txn,
        entidad: tipo,
        entidadId: '$id',
        accion: activo ? 'activar' : 'desactivar',
        payload: {'id': id, 'estado': activo},
      );
    });
  }

  Future<void> _guardarRelacionesTxn(
    Transaction txn, {
    required int marcaId,
    required Set<int> categoriaIds,
  }) async {
    final brandRows = await txn.rawQuery(
      '''
      SELECT m.nombre, m.estado, e.nombre AS empresa, e.estado AS empresa_estado
      FROM marcas m
      INNER JOIN empresas e ON e.id = m.empresa_id
      WHERE m.id = ?
      ''',
      [marcaId],
    );
    if (brandRows.isEmpty) throw StateError('La marca ya no existe.');
    final currentRows = await txn.query(
      'marca_categorias',
      columns: ['categoria_id', 'estado'],
      where: 'marca_id = ?',
      whereArgs: [marcaId],
    );
    final currentActive = currentRows
        .where((row) => (row['estado'] as int? ?? 1) == 1)
        .map((row) => row['categoria_id'] as int)
        .toSet();
    final removed = currentActive.difference(categoriaIds);
    for (final categoryId in removed) {
      final categoryRows = await txn.query(
        'categorias',
        columns: ['nombre'],
        where: 'id = ?',
        whereArgs: [categoryId],
        limit: 1,
      );
      if (categoryRows.isEmpty) continue;
      final activeProducts =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              '''
              SELECT COUNT(*)
              FROM productos
              WHERE activo = 1
                AND LOWER(empresa) = LOWER(?)
                AND LOWER(marca) = LOWER(?)
                AND LOWER(categoria) = LOWER(?)
              ''',
              [
                brandRows.first['empresa'],
                brandRows.first['nombre'],
                categoryRows.first['nombre'],
              ],
            ),
          ) ??
          0;
      if (activeProducts > 0) {
        throw StateError(
          'No se puede desvincular la categoría porque $activeProducts producto(s) activo(s) utilizan esta combinación.',
        );
      }
    }
    if (categoriaIds.isNotEmpty) {
      final placeholders = List.filled(categoriaIds.length, '?').join(',');
      final validCount =
          Sqflite.firstIntValue(
            await txn.rawQuery('''
              SELECT COUNT(*)
              FROM categorias
              WHERE id IN ($placeholders)
                AND categoria_padre_id IS NULL
                AND estado = 1
              ''', categoriaIds.toList()),
          ) ??
          0;
      if (validCount != categoriaIds.length) {
        throw StateError(
          'Solo se pueden relacionar categorías principales activas.',
        );
      }
    }
    final now = DateTime.now().toIso8601String();
    final allIds = {
      ...currentRows.map((row) => row['categoria_id'] as int),
      ...categoriaIds,
    };
    for (final categoryId in allIds) {
      await txn.insert('marca_categorias', {
        'marca_id': marcaId,
        'categoria_id': categoryId,
        'estado': categoriaIds.contains(categoryId) ? 1 : 0,
        'actualizado_en': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await _encolar(
      txn,
      entidad: 'marca_categoria',
      entidadId: '$marcaId',
      accion: 'reemplazar_relaciones',
      payload: {'marca_id': marcaId, 'categoria_ids': categoriaIds.toList()},
    );
  }

  Future<void> _validarNombreEmpresa(
    Transaction txn,
    String nombre, {
    int? excluirId,
  }) async {
    final args = <Object?>[nombre];
    if (excluirId != null) args.add(excluirId);
    final rows = await txn.rawQuery('''
      SELECT id FROM empresas
      WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?))
        ${excluirId == null ? '' : 'AND id <> ?'}
      LIMIT 1
      ''', args);
    if (rows.isNotEmpty) {
      throw StateError('Ya existe una empresa con ese nombre.');
    }
  }

  Future<void> _validarPadreCategoria(
    Transaction txn,
    int parentId, {
    int? categoriaId,
  }) async {
    final parent = await txn.query(
      'categorias',
      columns: ['id', 'categoria_padre_id', 'estado'],
      where: 'id = ?',
      whereArgs: [parentId],
      limit: 1,
    );
    if (parent.isEmpty || (parent.first['estado'] as int? ?? 1) != 1) {
      throw StateError('Selecciona una categoría superior activa.');
    }
    if (parent.first['categoria_padre_id'] != null) {
      throw StateError('La jerarquía admite categoría y subcategoría.');
    }
    if (categoriaId != null && parentId == categoriaId) {
      throw StateError('Una categoría no puede ser su propia superior.');
    }
  }

  Future<void> _validarActivacion(
    Transaction txn, {
    required String tipo,
    required int id,
  }) async {
    if (tipo == 'marca') {
      final parent = await txn.rawQuery(
        '''
        SELECT e.estado
        FROM marcas m
        INNER JOIN empresas e ON e.id = m.empresa_id
        WHERE m.id = ?
        ''',
        [id],
      );
      if (parent.isEmpty || (parent.first['estado'] as int? ?? 0) != 1) {
        throw StateError('Activa primero la empresa propietaria.');
      }
    } else if (tipo == 'categoria') {
      final parent = await txn.rawQuery(
        '''
        SELECT padre.estado
        FROM categorias hija
        INNER JOIN categorias padre ON padre.id = hija.categoria_padre_id
        WHERE hija.id = ?
        ''',
        [id],
      );
      if (parent.isNotEmpty && (parent.first['estado'] as int? ?? 0) != 1) {
        throw StateError('Activa primero la categoría superior.');
      }
    }
  }

  Future<void> _encolar(
    DatabaseExecutor db, {
    required String entidad,
    required String entidadId,
    required String accion,
    required Map<String, Object?> payload,
  }) async {
    final now = DateTime.now().toIso8601String();
    await db.insert('sync_queue', {
      'id': const Uuid().v4(),
      'entidad': entidad,
      'entidad_id': entidadId,
      'accion': accion,
      'payload_json': jsonEncode(payload),
      'estado': 'pendiente',
      'intentos': 0,
      'creado_en': now,
      'actualizado_en': now,
    });
  }

  EmpresaCatalogo _empresaFromMap(Map<String, Object?> row) => EmpresaCatalogo(
    id: row['id'] as int,
    nombre: row['nombre'] as String,
    ruc: row['ruc'] as String? ?? '',
    telefono: row['telefono'] as String? ?? '',
    direccion: row['direccion'] as String? ?? '',
    activa: (row['estado'] as int? ?? 1) == 1,
    cantidadMarcas: row['cantidad_marcas'] as int? ?? 0,
    cantidadCategorias: row['cantidad_categorias'] as int? ?? 0,
    cantidadProductos: row['cantidad_productos'] as int? ?? 0,
    principalesMarcas: _split(row['principales_marcas']),
  );

  MarcaCatalogo _marcaFromMap(Map<String, Object?> row) => MarcaCatalogo(
    id: row['id'] as int,
    empresaId: row['empresa_id'] as int,
    nombre: row['nombre'] as String,
    empresaNombre: row['empresa_nombre'] as String,
    activa: (row['estado'] as int? ?? 1) == 1,
    categorias: _split(row['categorias']),
    cantidadProductos: row['cantidad_productos'] as int? ?? 0,
  );

  CategoriaCatalogo _categoriaFromMap(Map<String, Object?> row) =>
      CategoriaCatalogo(
        id: row['id'] as int,
        categoriaPadreId: row['categoria_padre_id'] as int?,
        categoriaPadreNombre: row['categoria_padre_nombre'] as String?,
        nombre: row['nombre'] as String,
        descripcion: row['descripcion'] as String? ?? '',
        activa: (row['estado'] as int? ?? 1) == 1,
        marcas: _split(row['marcas']),
        empresas: _split(row['empresas']),
        cantidadProductos: row['cantidad_productos'] as int? ?? 0,
      );

  ImpactoEstructura _impactoFromMap(Map<String, Object?> row) =>
      ImpactoEstructura(
        productos: row['productos'] as int? ?? 0,
        marcas: row['marcas'] as int? ?? 0,
        categorias: row['categorias'] as int? ?? 0,
      );

  List<String> _split(Object? raw) {
    if (raw == null || raw.toString().trim().isEmpty) return const [];
    return raw
        .toString()
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }
}
