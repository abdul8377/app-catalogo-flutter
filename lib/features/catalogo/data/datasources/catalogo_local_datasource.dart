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
      final attrs = await db.query(
        'atributos_def',
        where: 'categoria_id = ?',
        whereArgs: [id],
        orderBy: 'id',
      );
      subcategorias[nombre] = subs
          .map((row) => row['nombre'] as String)
          .toList();
      atributos[nombre] = attrs
          .map(
            (row) => AtributoDef(
              nombre: row['nombre'] as String,
              tipo: row['tipo'] as String,
              esVariante: (row['es_variante'] as int) == 1,
            ),
          )
          .toList();
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

  Future<void> guardarProducto(NuevoProducto producto) async {
    final db = await _db;
    await _validarClasificacion(db, producto);
    final id = const Uuid().v4();
    final precio = producto.precios.isEmpty
        ? null
        : producto.precios.first.valor;
    final presentacion = producto.presentaciones.isEmpty
        ? const PresentacionProducto(nombre: 'Unidad', unidad: 'UND')
        : producto.presentaciones.first;
    final imagenesPaths = await _guardarImagenes(producto.imagenes, id);
    try {
      await db.insert('productos', {
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
        'presentaciones_json': jsonEncode(
          producto.presentaciones.map((item) => item.toMap()).toList(),
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
    } catch (_) {
      await _eliminarImagenes(imagenesPaths);
      rethrow;
    }
  }

  Future<void> actualizarProducto(String id, NuevoProducto producto) async {
    final db = await _db;
    await _validarClasificacion(db, producto);
    final rows = await db.query(
      'productos',
      columns: ['imagen_path', 'imagenes_json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('No se encontró el producto.');
    final imagenesAnteriores = _imagenesFromMap(rows.first);
    final imagenesPaths = await _guardarImagenes(
      producto.imagenes,
      id,
      existentes: imagenesAnteriores.toSet(),
    );
    final precio = producto.precios.isEmpty
        ? null
        : producto.precios.first.valor;
    final presentacion = producto.presentaciones.isEmpty
        ? const PresentacionProducto(nombre: 'Unidad', unidad: 'UND')
        : producto.presentaciones.first;
    int actualizados;
    try {
      actualizados = await db.update(
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
          'presentaciones_json': jsonEncode(
            producto.presentaciones.map((item) => item.toMap()).toList(),
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
    } catch (_) {
      await _eliminarImagenes(
        imagenesPaths.where((path) => !imagenesAnteriores.contains(path)),
      );
      rethrow;
    }
    if (actualizados != 1) {
      await _eliminarImagenes(
        imagenesPaths.where((path) => !imagenesAnteriores.contains(path)),
      );
      throw StateError('No se pudo actualizar.');
    }
    await _eliminarImagenes(
      imagenesAnteriores.where((path) => !imagenesPaths.contains(path)),
    );
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
    final rows = await db.rawQuery(
      '''
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
      ''',
      [
        producto.marca,
        producto.categoria,
        producto.subcategoria,
        producto.empresa,
      ],
    );
    if (rows.isEmpty) {
      throw StateError(
        'La combinación empresa, marca, categoría y subcategoría no es válida o contiene elementos inactivos.',
      );
    }
  }

  ProductoResumen _resumenFromMap(Map<String, Object?> row) {
    final atributos =
        jsonDecode(row['atributos_json'] as String) as Map<String, dynamic>;
    final imagenes = _imagenesFromMap(row);
    return ProductoResumen(
      id: row['id'] as String,
      codigo: row['codigo'] as String,
      nombre: row['nombre'] as String,
      empresa: row['empresa'] as String,
      marca: row['marca'] as String,
      categoria: row['categoria'] as String,
      unidadVenta: row['unidad_venta'] as String,
      precio: (row['precio'] as num?)?.toDouble(),
      sinPrecio: (row['sin_precio'] as int) == 1,
      activo: (row['activo'] as int) == 1,
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
      tipoRegistro: row['tipo_registro'] as String,
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
    final imagenes = _imagenesFromMap(row);
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
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
    );
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
