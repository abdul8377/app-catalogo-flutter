import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/catalogo_form_data.dart';
import '../../domain/entities/nuevo_producto.dart';
import '../../domain/entities/producto_resumen.dart';
import '../../domain/entities/producto_detalle.dart';
import '../../domain/entities/producto_variante.dart';

class CatalogoLocalDatasource {
  const CatalogoLocalDatasource(this._appDatabase);
  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  Future<List<ProductoResumen>> obtenerProductos() async {
    final rows = await (await _db).query(
      'productos',
      orderBy: 'creado_en DESC',
    );
    return rows.map(_resumenFromMap).toList();
  }

  Future<List<ProductoResumen>> buscarProductos(String query) async {
    final texto = '%${query.trim()}%';
    final rows = await (await _db).query(
      'productos',
      where:
          'codigo LIKE ? OR nombre LIKE ? OR empresa LIKE ? OR marca LIKE ? OR categoria LIKE ?',
      whereArgs: [texto, texto, texto, texto, texto],
      orderBy: 'creado_en DESC',
    );
    return rows.map(_resumenFromMap).toList();
  }

  Future<ProductoDetalle?> obtenerDetalleProducto(String id) async {
    final rows = await (await _db).query(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _detalleFromMap(rows.first);
  }

  Future<void> cambiarEstadoProducto(String id, {required bool activo}) async {
    final actualizados = await (await _db).update(
      'productos',
      {'activo': activo ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (actualizados != 1) {
      throw StateError('No se encontró el producto.');
    }
  }

  Future<CatalogoFormData> obtenerDatosFormulario() async {
    final db = await _db;
    final empresas = await db.query(
      'empresas',
      where: 'estado = 1',
      orderBy: 'nombre COLLATE NOCASE',
    );
    final marcas = await db.rawQuery('''
      SELECT m.nombre, e.nombre AS empresa
      FROM marcas m
      INNER JOIN empresas e ON e.id = m.empresa_id
      WHERE m.estado = 1 AND e.estado = 1
      ORDER BY e.nombre COLLATE NOCASE, m.nombre COLLATE NOCASE
    ''');
    final categorias = await db.query(
      'categorias',
      where: 'categoria_padre_id IS NULL AND estado = 1',
      orderBy: 'nombre COLLATE NOCASE',
    );
    final subcategorias = <String, List<String>>{};
    final atributos = <String, List<AtributoDef>>{};
    final marcasPorEmpresa = <String, List<String>>{};
    final categoriasPorMarca = <String, List<String>>{};
    for (final marca in marcas) {
      final empresa = marca['empresa'] as String;
      marcasPorEmpresa
          .putIfAbsent(empresa, () => [])
          .add(marca['nombre'] as String);
    }
    for (final categoria in categorias) {
      final id = categoria['id'] as int;
      final nombre = categoria['nombre'] as String;
      final subs = await db.query(
        'categorias',
        where: 'categoria_padre_id = ? AND estado = 1',
        whereArgs: [id],
        orderBy: 'nombre COLLATE NOCASE',
      );
      subcategorias[nombre] = subs
          .map((row) => row['nombre'] as String)
          .toList();
      atributos[nombre] = await _obtenerAtributosFormulario(db, id);
      for (final sub in subs) {
        atributos[sub['nombre'] as String] = await _obtenerAtributosFormulario(
          db,
          sub['id'] as int,
        );
      }
    }
    final relations = await db.rawQuery('''
      SELECT e.nombre AS empresa, m.nombre AS marca, c.nombre AS categoria
      FROM marca_categorias mc
      INNER JOIN marcas m ON m.id = mc.marca_id
      INNER JOIN empresas e ON e.id = m.empresa_id
      INNER JOIN categorias c ON c.id = mc.categoria_id
      WHERE mc.estado = 1
        AND m.estado = 1
        AND e.estado = 1
        AND c.estado = 1
        AND c.categoria_padre_id IS NULL
      ORDER BY c.nombre COLLATE NOCASE
    ''');
    for (final relation in relations) {
      final key = '${relation['empresa']}::${relation['marca']}';
      categoriasPorMarca
          .putIfAbsent(key, () => [])
          .add(relation['categoria'] as String);
    }
    return CatalogoFormData(
      empresas: empresas.map((row) => row['nombre'] as String).toList(),
      marcas: marcas.map((row) => row['nombre'] as String).toSet().toList(),
      subcategorias: subcategorias,
      atributos: atributos,
      marcasPorEmpresa: marcasPorEmpresa,
      categoriasPorMarca: categoriasPorMarca,
    );
  }

  Future<List<AtributoDef>> _obtenerAtributosFormulario(
    Database db,
    int categoriaId,
  ) async {
    final rows = await db.rawQuery(
      '''
      WITH RECURSIVE cadena(id, categoria_padre_id, profundidad) AS (
        SELECT id, categoria_padre_id, 0
        FROM categorias
        WHERE id = ?
        UNION ALL
        SELECT c.id, c.categoria_padre_id, cadena.profundidad + 1
        FROM categorias c
        INNER JOIN cadena ON cadena.categoria_padre_id = c.id
      )
      SELECT a.*, cadena.profundidad
      FROM cadena
      INNER JOIN categoria_atributos a ON a.categoria_id = cadena.id
      WHERE a.estado = 1 AND a.activo_nuevos = 1
      ORDER BY cadena.profundidad, a.orden, a.nombre COLLATE NOCASE
    ''',
      [categoriaId],
    );
    final byKey = <String, Map<String, Object?>>{};
    for (final row in rows) {
      byKey.putIfAbsent(row['clave'] as String, () => row);
    }
    final result = <AtributoDef>[];
    for (final row in byKey.values) {
      final id = row['id'] as String;
      final optionRows = await db.query(
        'categoria_atributo_opciones',
        columns: ['etiqueta'],
        where: 'categoria_atributo_id = ? AND estado = 1',
        whereArgs: [id],
        orderBy: 'orden, etiqueta COLLATE NOCASE',
      );
      final unitRows = await db.rawQuery(
        '''
        SELECT u.codigo, u.simbolo, cau.es_predeterminada
        FROM categoria_atributo_unidades cau
        INNER JOIN unidades_medida u ON u.id = cau.unidad_medida_id
        WHERE cau.categoria_atributo_id = ? AND u.estado = 1
        ORDER BY cau.es_predeterminada DESC, u.nombre COLLATE NOCASE
      ''',
        [id],
      );
      final defaultUnit = unitRows
          .where((unit) => unit['es_predeterminada'] == 1)
          .map((unit) => unit['simbolo'] as String)
          .firstOrNull;
      final capture = row['nivel_captura'] as String;
      result.add(
        AtributoDef(
          id: id,
          nombre: row['nombre'] as String,
          clave: row['clave'] as String,
          tipo: row['tipo_dato'] as String,
          esVariante:
              capture == 'variante' ||
              (capture == 'decidir' && row['puede_ser_eje'] == 1),
          requerido: row['requerido_activar'] == 1,
          opciones: optionRows
              .map((option) => option['etiqueta'] as String)
              .toList(),
          unidades: unitRows.map((unit) => unit['simbolo'] as String).toList(),
          unidadPredeterminada: defaultUnit,
        ),
      );
    }
    return result;
  }

  Future<void> guardarProducto(NuevoProducto producto) async {
    final db = await _db;
    await _validarClasificacion(db, producto);
    await _validarSkusVariantes(db, producto);
    final id = const Uuid().v4();
    final precio = producto.precios.isEmpty
        ? null
        : producto.precios.first.valor;
    final presentacion = producto.presentaciones.isEmpty
        ? const PresentacionProducto(nombre: 'Unidad', unidad: 'UND')
        : producto.presentaciones.first;
    final rutasFamilia = producto.imagenes;
    final rutasConfiguradas = _rutasImagenesConfiguradas(
      producto.imagenesConfiguradas,
    );
    final rutasOrigen = {...rutasFamilia, ...rutasConfiguradas}.toList();
    final imagenesGuardadas = await _guardarImagenes(rutasOrigen, id);
    final reemplazos = {
      for (var index = 0; index < rutasOrigen.length; index++)
        rutasOrigen[index]: imagenesGuardadas[index],
    };
    final imagenesPaths = rutasFamilia
        .map((path) => reemplazos[path] ?? path)
        .toList();
    final imagenesConfiguradas = _normalizarImagenesConfiguradas(
      producto.imagenesConfiguradas,
      reemplazos,
      familyId: id,
    );
    try {
      await db.transaction((txn) async {
        await txn.insert('productos', {
          'id': id,
          'codigo': producto.codigo,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion,
          'empresa': producto.empresa,
          'marca': producto.marca,
          'categoria': producto.categoria,
          'subcategoria': producto.subcategoria,
          'tipo_registro': producto.tipoRegistro,
          'atributos_json': jsonEncode(producto.atributos),
          'variantes_json': jsonEncode(
            producto.variantes.map((item) => item.toMap()).toList(),
          ),
          'presentaciones_json': jsonEncode(
            producto.presentaciones.map((item) => item.toMap()).toList(),
          ),
          'venta_logistica_json': jsonEncode(
            producto.ventaLogisticaContenido ?? const <String, dynamic>{},
          ),
          'precios_configurados_json': jsonEncode(
            producto.preciosConfigurados ?? const <String, dynamic>{},
          ),
          'imagenes_configuradas_json': jsonEncode(
            imagenesConfiguradas ?? const <String, dynamic>{},
          ),
          'precios_json': jsonEncode(
            producto.precios.map((item) => item.toMap()).toList(),
          ),
          'unidad_venta': presentacion.nombre,
          'precio': precio,
          'sin_precio': precio == null ? 1 : 0,
          'activo': producto.activo ? 1 : 0,
          'imagen_path': imagenesPaths.isEmpty ? null : imagenesPaths.first,
          'imagenes_json': jsonEncode(imagenesPaths),
          'creado_en': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.abort);
        await _sincronizarAtributosProducto(txn, id, producto);
      });
    } catch (_) {
      await _eliminarImagenes(imagenesGuardadas);
      rethrow;
    }
  }

  Future<void> actualizarProducto(String id, NuevoProducto producto) async {
    final db = await _db;
    await _validarClasificacion(db, producto);
    await _validarSkusVariantes(db, producto, productoId: id);
    final rows = await db.query(
      'productos',
      columns: ['imagen_path', 'imagenes_json', 'imagenes_configuradas_json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('No se encontró el producto.');
    final imagenesAnteriores = {
      ..._imagenesFromMap(rows.first),
      ..._rutasImagenesConfiguradasDesdeFila(rows.first),
    }.toList();
    final rutasFamilia = producto.imagenes;
    final rutasConfiguradas = _rutasImagenesConfiguradas(
      producto.imagenesConfiguradas,
    );
    final rutasOrigen = {...rutasFamilia, ...rutasConfiguradas}.toList();
    final imagenesGuardadas = await _guardarImagenes(
      rutasOrigen,
      id,
      existentes: imagenesAnteriores.toSet(),
    );
    final reemplazos = {
      for (var index = 0; index < rutasOrigen.length; index++)
        rutasOrigen[index]: imagenesGuardadas[index],
    };
    final imagenesPaths = rutasFamilia
        .map((path) => reemplazos[path] ?? path)
        .toList();
    final imagenesConfiguradas = _normalizarImagenesConfiguradas(
      producto.imagenesConfiguradas,
      reemplazos,
      familyId: id,
    );
    final precio = producto.precios.isEmpty
        ? null
        : producto.precios.first.valor;
    final presentacion = producto.presentaciones.isEmpty
        ? const PresentacionProducto(nombre: 'Unidad', unidad: 'UND')
        : producto.presentaciones.first;
    int actualizados;
    try {
      actualizados = await db.transaction((txn) async {
        final count = await txn.update(
          'productos',
          {
            'codigo': producto.codigo,
            'nombre': producto.nombre,
            'descripcion': producto.descripcion,
            'empresa': producto.empresa,
            'marca': producto.marca,
            'categoria': producto.categoria,
            'subcategoria': producto.subcategoria,
            'tipo_registro': producto.tipoRegistro,
            'atributos_json': jsonEncode(producto.atributos),
            'variantes_json': jsonEncode(
              producto.variantes.map((item) => item.toMap()).toList(),
            ),
            'presentaciones_json': jsonEncode(
              producto.presentaciones.map((item) => item.toMap()).toList(),
            ),
            'venta_logistica_json': jsonEncode(
              producto.ventaLogisticaContenido ?? const <String, dynamic>{},
            ),
            'precios_configurados_json': jsonEncode(
              producto.preciosConfigurados ?? const <String, dynamic>{},
            ),
            'imagenes_configuradas_json': jsonEncode(
              imagenesConfiguradas ?? const <String, dynamic>{},
            ),
            'precios_json': jsonEncode(
              producto.precios.map((item) => item.toMap()).toList(),
            ),
            'unidad_venta': presentacion.nombre,
            'precio': precio,
            'sin_precio': precio == null ? 1 : 0,
            'activo': producto.activo ? 1 : 0,
            'imagen_path': imagenesPaths.isEmpty ? null : imagenesPaths.first,
            'imagenes_json': jsonEncode(imagenesPaths),
          },
          where: 'id = ?',
          whereArgs: [id],
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        if (count == 1) {
          await _sincronizarAtributosProducto(txn, id, producto);
        }
        return count;
      });
    } catch (_) {
      await _eliminarImagenes(
        imagenesGuardadas.where((path) => !imagenesAnteriores.contains(path)),
      );
      rethrow;
    }
    if (actualizados != 1) {
      await _eliminarImagenes(
        imagenesGuardadas.where((path) => !imagenesAnteriores.contains(path)),
      );
      throw StateError('No se pudo actualizar.');
    }
    await _eliminarImagenes(
      imagenesAnteriores.where((path) => !imagenesGuardadas.contains(path)),
    );
  }

  Future<void> _sincronizarAtributosProducto(
    Transaction txn,
    String productoId,
    NuevoProducto producto,
  ) async {
    final categoriaId = await _categoriaIdProducto(txn, producto);
    if (categoriaId == null) return;
    final definitions = await txn.rawQuery(
      '''
      WITH RECURSIVE cadena(id, categoria_padre_id, profundidad) AS (
        SELECT id, categoria_padre_id, 0
        FROM categorias
        WHERE id = ?
        UNION ALL
        SELECT c.id, c.categoria_padre_id, cadena.profundidad + 1
        FROM categorias c
        INNER JOIN cadena ON cadena.categoria_padre_id = c.id
      )
      SELECT a.*, cadena.profundidad
      FROM cadena
      INNER JOIN categoria_atributos a ON a.categoria_id = cadena.id
      WHERE a.estado = 1
      ORDER BY cadena.profundidad, a.orden
    ''',
      [categoriaId],
    );
    final byName = <String, Map<String, Object?>>{};
    for (final definition in definitions) {
      byName.putIfAbsent(
        _normalizarNombreAtributo(definition['nombre'] as String),
        () => definition,
      );
      byName.putIfAbsent(
        _normalizarNombreAtributo(definition['clave'] as String),
        () => definition,
      );
    }

    final variantIds = producto.variantes.map((item) => item.id).toSet();
    final oldVariants = await txn.query(
      'producto_variantes_catalogo',
      columns: ['id'],
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
    for (final row in oldVariants) {
      final id = row['id'] as String;
      if (!variantIds.contains(id)) {
        await txn.delete(
          'producto_variantes_catalogo',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    for (final variant in producto.variantes) {
      final values = <String, Object?>{
        'producto_id': productoId,
        'sku': variant.sku.trim().toUpperCase(),
        'nombre_corto': variant.nombreCorto.trim(),
        'estado': variant.activa ? 1 : 0,
      };
      final exists = await txn.query(
        'producto_variantes_catalogo',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [variant.id],
        limit: 1,
      );
      if (exists.isEmpty) {
        await txn.insert('producto_variantes_catalogo', {
          'id': variant.id,
          ...values,
        });
      } else {
        await txn.update(
          'producto_variantes_catalogo',
          values,
          where: 'id = ?',
          whereArgs: [variant.id],
        );
      }
    }

    await txn.delete(
      'producto_atributos',
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );
    if (variantIds.isNotEmpty) {
      final placeholders = List.filled(variantIds.length, '?').join(',');
      await txn.delete(
        'producto_atributos',
        where: 'variante_id IN ($placeholders)',
        whereArgs: variantIds.toList(),
      );
    }
    await txn.delete(
      'producto_familia_ejes',
      where: 'producto_id = ?',
      whereArgs: [productoId],
    );

    for (final entry in producto.atributos.entries) {
      final definition = byName[_normalizarNombreAtributo(entry.key)];
      if (definition == null || entry.value.trim().isEmpty) continue;
      final parsed = _separarValorUnidad(entry.value);
      await _guardarValorAtributo(
        txn,
        definition: definition,
        productoId: productoId,
        value: parsed.$1,
        unitCode: parsed.$2,
      );
    }

    final axisIds = <String>[];
    for (final variant in producto.variantes) {
      for (final attribute in variant.atributos) {
        final definition = byName[_normalizarNombreAtributo(attribute.nombre)];
        if (definition == null || attribute.valor.trim().isEmpty) continue;
        await _guardarValorAtributo(
          txn,
          definition: definition,
          varianteId: variant.id,
          value: attribute.valor,
          unitCode: attribute.unidad,
        );
        if ((definition['puede_ser_eje'] as int? ?? 0) == 1) {
          final definitionId = definition['id'] as String;
          if (!axisIds.contains(definitionId)) axisIds.add(definitionId);
        }
      }
    }
    for (var index = 0; index < axisIds.length; index++) {
      await txn.insert('producto_familia_ejes', {
        'producto_id': productoId,
        'categoria_atributo_id': axisIds[index],
        'orden': index,
      });
    }
  }

  Future<int?> _categoriaIdProducto(
    DatabaseExecutor db,
    NuevoProducto producto,
  ) async {
    if (producto.subcategoria.trim().isNotEmpty) {
      final rows = await db.rawQuery(
        '''
        SELECT hija.id
        FROM categorias hija
        INNER JOIN categorias padre ON padre.id = hija.categoria_padre_id
        WHERE LOWER(TRIM(hija.nombre)) = LOWER(TRIM(?))
          AND LOWER(TRIM(padre.nombre)) = LOWER(TRIM(?))
        LIMIT 1
      ''',
        [producto.subcategoria, producto.categoria],
      );
      if (rows.isNotEmpty) return rows.first['id'] as int;
    }
    final rows = await db.query(
      'categorias',
      columns: ['id'],
      where:
          'LOWER(TRIM(nombre)) = LOWER(TRIM(?)) AND categoria_padre_id IS NULL',
      whereArgs: [producto.categoria],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<void> _guardarValorAtributo(
    DatabaseExecutor db, {
    required Map<String, Object?> definition,
    required String value,
    String unitCode = '',
    String? productoId,
    String? varianteId,
  }) async {
    final definitionId = definition['id'] as String;
    final type = definition['tipo_dato'] as String;
    final trimmed = value.trim();
    final values = <String, Object?>{
      'id': const Uuid().v4(),
      'categoria_atributo_id': definitionId,
      'producto_id': productoId,
      'variante_id': varianteId,
      'actualizado_en': DateTime.now().toIso8601String(),
    };
    final optionIds = <String>[];

    switch (type) {
      case 'numero':
      case 'numero_unidad':
        final number = double.tryParse(trimmed.replaceAll(',', '.'));
        if (number == null) {
          throw StateError(
            'El valor de ${definition['nombre']} debe ser numérico.',
          );
        }
        final minimum = (definition['minimo'] as num?)?.toDouble();
        final maximum = (definition['maximo'] as num?)?.toDouble();
        if ((minimum != null && number < minimum) ||
            (maximum != null && number > maximum)) {
          throw StateError(
            'El valor de ${definition['nombre']} está fuera del rango permitido.',
          );
        }
        values['valor_numero'] = number;
        values['valor_normalizado'] = number;
        if (type == 'numero_unidad') {
          final unitRows = await db.rawQuery(
            '''
            SELECT cu.id, cu.es_predeterminada, u.factor_a_base
            FROM categoria_atributo_unidades cu
            INNER JOIN unidades_medida u ON u.id = cu.unidad_medida_id
            WHERE cu.categoria_atributo_id = ?
              AND cu.estado = 1
              AND (
                LOWER(u.codigo) = LOWER(?) OR
                LOWER(u.simbolo) = LOWER(?) OR
                (? = '' AND cu.es_predeterminada = 1)
              )
            ORDER BY
              CASE WHEN LOWER(u.codigo) = LOWER(?) THEN 0 ELSE 1 END,
              cu.es_predeterminada DESC
            LIMIT 1
          ''',
            [
              definitionId,
              unitCode.trim(),
              unitCode.trim(),
              unitCode.trim(),
              unitCode.trim(),
            ],
          );
          if (unitRows.isEmpty) {
            throw StateError(
              'Selecciona una unidad válida para ${definition['nombre']}.',
            );
          }
          values['categoria_atributo_unidad_id'] = unitRows.first['id'];
          values['valor_normalizado'] =
              number * (unitRows.first['factor_a_base'] as num).toDouble();
        }
        break;
      case 'lista_unica':
      case 'lista_multiple':
        final selections = trimmed
            .split(RegExp(r'[,;|]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (type == 'lista_unica' && selections.length != 1) {
          throw StateError('${definition['nombre']} permite una sola opción.');
        }
        final maxSelections = definition['maximo_selecciones'] as int?;
        if (maxSelections != null && selections.length > maxSelections) {
          throw StateError(
            '${definition['nombre']} permite hasta $maxSelections opciones.',
          );
        }
        for (final selection in selections) {
          final rows = await db.query(
            'categoria_atributo_opciones',
            columns: ['id'],
            where:
                'categoria_atributo_id = ? AND estado = 1 '
                'AND (LOWER(etiqueta) = LOWER(?) OR LOWER(codigo) = LOWER(?))',
            whereArgs: [definitionId, selection, selection],
            limit: 1,
          );
          if (rows.isEmpty) {
            throw StateError(
              'La opción “$selection” no pertenece a ${definition['nombre']}.',
            );
          }
          optionIds.add(rows.first['id'] as String);
        }
        values['valor_texto'] = selections.join(' · ');
        break;
      case 'si_no':
        final normalized = _normalizarNombreAtributo(trimmed);
        if (!{'si', 'no', 'true', 'false', '1', '0'}.contains(normalized)) {
          throw StateError(
            'El valor de ${definition['nombre']} debe ser Sí o No.',
          );
        }
        values['valor_booleano'] = {'si', 'true', '1'}.contains(normalized)
            ? 1
            : 0;
        break;
      default:
        values['valor_texto'] = trimmed;
        break;
    }

    await db.insert('producto_atributos', values);
    for (final optionId in optionIds) {
      await db.insert('producto_atributo_opciones', {
        'producto_atributo_id': values['id'],
        'categoria_atributo_id': definitionId,
        'opcion_id': optionId,
      });
    }
  }

  (String, String) _separarValorUnidad(String raw) {
    final match = RegExp(
      r'^([-+]?[0-9]+(?:[.,][0-9]+)?)\s*([^\d\s].*)$',
    ).firstMatch(raw.trim());
    if (match == null) return (raw.trim(), '');
    return (match.group(1)!.replaceAll(',', '.'), match.group(2)?.trim() ?? '');
  }

  String _normalizarNombreAtributo(String value) {
    var normalized = value.trim().toLowerCase();
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    replacements.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    if (normalized == 'ø' ||
        normalized == 'diameter' ||
        normalized == 'diam.') {
      normalized = 'diametro';
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Future<List<String>> _guardarImagenes(
    Iterable<String> origenes,
    String productoId, {
    Set<String> existentes = const {},
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'productos'));
    await directory.create(recursive: true);
    final guardadas = <String>[];
    try {
      for (final origenPath in origenes) {
        if (existentes.contains(origenPath)) {
          final existente = File(origenPath);
          if (await existente.exists()) {
            guardadas.add(origenPath);
            continue;
          }
        }
        final origen = File(origenPath);
        if (!await origen.exists()) {
          throw const FileSystemException(
            'Una imagen seleccionada ya no existe.',
          );
        }
        final extension = p.extension(origen.path).toLowerCase();
        final destino = File(
          p.join(
            directory.path,
            '$productoId-${const Uuid().v4()}${extension.isEmpty ? '.jpg' : extension}',
          ),
        );
        await origen.copy(destino.path);
        guardadas.add(destino.path);
      }
      return guardadas;
    } catch (_) {
      await _eliminarImagenes(
        guardadas.where((path) => !existentes.contains(path)),
      );
      rethrow;
    }
  }

  Future<void> _eliminarImagenes(Iterable<String> paths) async {
    for (final path in paths) {
      final archivo = File(path);
      if (await archivo.exists()) await archivo.delete();
    }
  }

  Future<void> _validarClasificacion(
    DatabaseExecutor db,
    NuevoProducto producto,
  ) async {
    final tieneSubcategoria = producto.subcategoria.trim().isNotEmpty;
    final rows = await db.rawQuery(
      tieneSubcategoria
          ? '''
      SELECT e.id
      FROM empresas e
      INNER JOIN marcas m
        ON m.empresa_id = e.id
       AND LOWER(TRIM(m.nombre)) = LOWER(TRIM(?))
       AND m.estado = 1
      INNER JOIN marca_categorias mc
        ON mc.marca_id = m.id
       AND mc.estado = 1
      INNER JOIN categorias c
        ON c.id = mc.categoria_id
       AND LOWER(TRIM(c.nombre)) = LOWER(TRIM(?))
       AND c.categoria_padre_id IS NULL
       AND c.estado = 1
      INNER JOIN categorias s
        ON s.categoria_padre_id = c.id
       AND LOWER(TRIM(s.nombre)) = LOWER(TRIM(?))
       AND s.estado = 1
      WHERE LOWER(TRIM(e.nombre)) = LOWER(TRIM(?))
        AND e.estado = 1
      LIMIT 1
      '''
          : '''
      SELECT e.id
      FROM empresas e
      INNER JOIN marcas m
        ON m.empresa_id = e.id
       AND LOWER(TRIM(m.nombre)) = LOWER(TRIM(?))
       AND m.estado = 1
      INNER JOIN marca_categorias mc
        ON mc.marca_id = m.id
       AND mc.estado = 1
      INNER JOIN categorias c
        ON c.id = mc.categoria_id
       AND LOWER(TRIM(c.nombre)) = LOWER(TRIM(?))
       AND c.categoria_padre_id IS NULL
       AND c.estado = 1
      WHERE LOWER(TRIM(e.nombre)) = LOWER(TRIM(?))
        AND e.estado = 1
      LIMIT 1
      ''',
      tieneSubcategoria
          ? [
              producto.marca,
              producto.categoria,
              producto.subcategoria,
              producto.empresa,
            ]
          : [producto.marca, producto.categoria, producto.empresa],
    );
    if (rows.isEmpty) {
      throw StateError(
        'La combinación empresa, marca, categoría y subcategoría no es válida o contiene elementos inactivos.',
      );
    }
  }

  Future<void> _validarSkusVariantes(
    DatabaseExecutor db,
    NuevoProducto producto, {
    String? productoId,
  }) async {
    final nuevos = <String>{};
    for (final variante in producto.variantes) {
      final sku = variante.sku.trim().toUpperCase();
      if (sku.isEmpty) throw StateError('Todas las variantes requieren SKU.');
      if (!nuevos.add(sku)) {
        throw StateError('El SKU $sku está repetido en la familia.');
      }
    }

    final rows = await db.query(
      'productos',
      columns: ['id', 'codigo', 'variantes_json'],
    );
    final existentes = <String>{};
    for (final row in rows) {
      if (row['id'] == productoId) continue;
      existentes.add((row['codigo'] as String).trim().toUpperCase());
      final raw = row['variantes_json'] as String? ?? '[]';
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;
      for (final item in decoded.whereType<Map>()) {
        final sku = item['sku']?.toString().trim().toUpperCase();
        if (sku != null && sku.isNotEmpty) existentes.add(sku);
      }
    }
    final repetido = nuevos.where(existentes.contains).firstOrNull;
    if (repetido != null) {
      throw StateError('El SKU $repetido ya existe en el catálogo.');
    }
  }

  ProductoResumen _resumenFromMap(Map<String, Object?> row) {
    final atributos =
        jsonDecode(row['atributos_json'] as String) as Map<String, dynamic>;
    final presentacionesRaw =
        jsonDecode(row['presentaciones_json'] as String) as List<dynamic>;
    final presentaciones = presentacionesRaw
        .map((item) => (item as Map<String, dynamic>)['nombre'] as String)
        .where((nombre) => nombre.trim().isNotEmpty)
        .toList();
    if (presentaciones.isEmpty) {
      presentaciones.add(row['unidad_venta'] as String);
    }
    final imagenes = _imagenesFromMap(row);
    return ProductoResumen(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      nombre: row['nombre'] as String,
      empresa: row['empresa'] as String,
      marca: row['marca'] as String,
      categoria: row['categoria'] as String,
      subcategoria: row['subcategoria'] as String,
      unidadVenta: row['unidad_venta'] as String,
      precio: (row['precio'] as num?)?.toDouble(),
      sinPrecio: (row['sin_precio'] as int) == 1,
      activo: (row['activo'] as int) == 1,
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
      tipoRegistro: row['tipo_registro'] as String,
      presentaciones: presentaciones,
      atributosClave: atributos.entries
          .where((entry) => entry.value.toString().trim().isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList(),
      creadoEn: DateTime.tryParse(row['creado_en'] as String),
    );
  }

  ProductoDetalle _detalleFromMap(Map<String, Object?> row) {
    final atributosRaw =
        jsonDecode(row['atributos_json'] as String) as Map<String, dynamic>;
    final presentacionesRaw =
        jsonDecode(row['presentaciones_json'] as String) as List<dynamic>;
    final preciosRaw =
        jsonDecode(row['precios_json'] as String) as List<dynamic>;
    final ventaLogisticaRaw = jsonDecode(
      row['venta_logistica_json'] as String? ?? '{}',
    );
    final ventaLogistica = ventaLogisticaRaw is Map
        ? Map<String, dynamic>.from(ventaLogisticaRaw)
        : null;
    final preciosConfiguradosRaw = jsonDecode(
      row['precios_configurados_json'] as String? ?? '{}',
    );
    final preciosConfigurados = preciosConfiguradosRaw is Map
        ? Map<String, dynamic>.from(preciosConfiguradosRaw)
        : null;
    final imagenesConfiguradasRaw = jsonDecode(
      row['imagenes_configuradas_json'] as String? ?? '{}',
    );
    final imagenesConfiguradas = imagenesConfiguradasRaw is Map
        ? Map<String, dynamic>.from(imagenesConfiguradasRaw)
        : null;
    final imagenes = _imagenesFromMap(row);
    final variantesRaw =
        jsonDecode(row['variantes_json'] as String? ?? '[]') as List<dynamic>;
    final variantes = variantesRaw
        .whereType<Map>()
        .map(
          (item) => ProductoVariante.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
    final presentaciones = presentacionesRaw.map((item) {
      final map = item as Map<String, dynamic>;
      return PresentacionProducto(
        nombre: map['nombre'] as String,
        unidad: map['unidad'] as String,
      );
    }).toList();
    if (presentaciones.isEmpty) {
      presentaciones.add(
        PresentacionProducto(
          nombre: row['unidad_venta'] as String,
          unidad: '1 ${row['unidad_venta'] as String}',
        ),
      );
    }
    final precios = preciosRaw.map((item) {
      final map = item as Map<String, dynamic>;
      return PrecioProducto(
        presentacion: map['presentacion'] as String,
        valor: (map['valor'] as num).toDouble(),
        listaPrecioId: map['lista_precio_id'] as String? ?? '',
        varianteId: map['variante_id'] as String? ?? '',
        presentacionId: map['presentacion_id'] as String? ?? '',
        configuracion: map['configuracion'] as String? ?? 'precio_fijo',
      );
    }).toList();
    if (precios.isEmpty && row['precio'] != null) {
      precios.add(
        PrecioProducto(
          presentacion: presentaciones.first.nombre,
          valor: (row['precio'] as num).toDouble(),
        ),
      );
    }
    return ProductoDetalle(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      nombre: row['nombre'] as String,
      descripcion: row['descripcion'] as String,
      empresa: row['empresa'] as String,
      marca: row['marca'] as String,
      categoria: row['categoria'] as String,
      subcategoria: row['subcategoria'] as String,
      tipoRegistro: row['tipo_registro'] as String,
      atributos: atributosRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      presentaciones: presentaciones,
      precios: precios,
      activo: (row['activo'] as int) == 1,
      creadoEn: DateTime.parse(row['creado_en'] as String),
      variantes: variantes,
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
      ventaLogisticaContenido: ventaLogistica,
      preciosConfigurados: preciosConfigurados,
      imagenesConfiguradas: imagenesConfiguradas,
    );
  }

  List<String> _rutasImagenesConfiguradasDesdeFila(Map<String, Object?> row) {
    final decoded = jsonDecode(
      row['imagenes_configuradas_json'] as String? ?? '{}',
    );
    return decoded is Map
        ? _rutasImagenesConfiguradas(Map<String, dynamic>.from(decoded))
        : const [];
  }

  List<String> _rutasImagenesConfiguradas(Map<String, dynamic>? configuracion) {
    if (configuracion == null || configuracion.isEmpty) return const [];
    final result = <String>{};
    for (final key in ['family_images', 'variant_specific_images']) {
      for (final raw in configuracion[key] as List? ?? const []) {
        if (raw is! Map) continue;
        final candidate = raw['candidate'];
        if (candidate is! Map) continue;
        final path = candidate['local_path'] as String?;
        if (path != null && path.trim().isNotEmpty) result.add(path);
      }
    }
    return result.toList();
  }

  Map<String, dynamic>? _normalizarImagenesConfiguradas(
    Map<String, dynamic>? configuracion,
    Map<String, String> reemplazos, {
    required String familyId,
  }) {
    if (configuracion == null || configuracion.isEmpty) return null;
    final decoded = jsonDecode(jsonEncode(configuracion));
    if (decoded is! Map) return null;
    final result = Map<String, dynamic>.from(decoded);

    void normalizeImages(String key, {required bool familyOwner}) {
      final images = result[key];
      if (images is! List) return;
      for (final raw in images) {
        if (raw is! Map) continue;
        raw['owner'] = familyOwner ? 'family' : 'variant';
        raw['family_id'] = familyOwner ? familyId : null;
        if (familyOwner) raw['variant_id'] = null;
        final candidate = raw['candidate'];
        if (candidate is! Map) continue;
        final path = candidate['local_path'] as String?;
        if (path != null && reemplazos.containsKey(path)) {
          candidate['local_path'] = reemplazos[path];
        }
      }
    }

    normalizeImages('family_images', familyOwner: true);
    normalizeImages('variant_specific_images', familyOwner: false);
    return result;
  }

  List<String> _imagenesFromMap(Map<String, Object?> row) {
    final raw = row['imagenes_json'] as String?;
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final paths = decoded
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toList();
        if (paths.isNotEmpty) return paths;
      }
    }
    final principal = row['imagen_path'] as String?;
    return principal == null || principal.isEmpty ? const [] : [principal];
  }
}
