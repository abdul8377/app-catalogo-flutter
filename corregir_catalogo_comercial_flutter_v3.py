from __future__ import annotations

from datetime import datetime
from pathlib import Path
import argparse
import shutil
import sys

ROOT = Path.cwd()

STEP4 = Path(
    'lib/features/catalogo/presentation/sections/producto_form/venta_logistica_section.dart'
)
PRESENTATION_EDITOR = Path(
    'lib/features/catalogo/presentation/sections/producto_form/venta_logistica/presentation_editor.dart'
)
PRESENTATION_EDITING = Path(
    'lib/features/catalogo/presentation/sections/producto_form/venta_logistica/presentation_editing.dart'
)
CATALOG_DS = Path(
    'lib/features/catalogo/data/datasources/catalogo_local_datasource.dart'
)
PRODUCT_SYNC = Path(
    'lib/features/sync/data/mappers/product_sync_mapper.dart'
)
REGRESSION_TEST = Path('test/venta_logistica_unidad_base_test.dart')


def find_root() -> Path:
    for candidate in (ROOT, ROOT / 'app_catalogo'):
        if (
            (candidate / 'pubspec.yaml').exists()
            and (candidate / STEP4).exists()
            and (candidate / CATALOG_DS).exists()
            and (candidate / PRODUCT_SYNC).exists()
        ):
            return candidate
    raise SystemExit(
        'No se encontro app-catalogo-flutter. Ejecuta este script desde la raiz '
        'que contiene pubspec.yaml.'
    )


APP = find_root()
STAMP = datetime.now().strftime('%Y%m%d_%H%M%S')
BACKUP_ROOT = APP / '.correction_backups' / STAMP
CHECK_MODE = False


def read(relative: Path) -> str:
    path = APP / relative
    if not path.exists():
        raise SystemExit(f'No existe {relative}.')
    return path.read_text(encoding='utf-8')


def save(relative: Path, content: str) -> None:
    path = APP / relative
    if CHECK_MODE:
        print(f'CHECK OK: {relative}')
        return
    if path.exists():
        backup = BACKUP_ROOT / relative
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, backup)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8', newline='\n')
    print(f'Modificado: {relative}')


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        raise SystemExit(
            f"No se pudo aplicar '{label}'. Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return content.replace(old, new, 1)


def replace_method(content: str, start_marker: str, end_marker: str, replacement: str, label: str) -> str:
    start = content.find(start_marker)
    end = content.find(end_marker, start + 1)
    if start < 0 or end < 0 or end <= start:
        raise SystemExit(f"No se pudieron localizar los limites de '{label}'.")
    return content[:start] + replacement + content[end:]


def patch_step4() -> None:
    content = read(STEP4)
    original = content

    if "      'UND',\n      'PZA'," not in content:
        content = replace_once(
            content,
            "    this.baseUnits = const [\n      'PZA',",
            "    this.baseUnits = const [\n      'UND',\n      'PZA',",
            'agregar UND a unidades base',
        )

    getter = '''  List<String> get _effectiveBaseUnits {
    final result = <String>[];
    final seen = <String>{};

    void add(String raw) {
      final value = raw.trim().toUpperCase();
      if (value.isNotEmpty && seen.add(value)) result.add(value);
    }

    for (final unit in widget.baseUnits) {
      add(unit);
    }
    for (final presentation in _presentations) {
      add(presentation.baseUnit);
    }
    add(_presentationBaseUnit);
    if (result.isEmpty) result.add('UND');
    return result;
  }

'''
    if 'List<String> get _effectiveBaseUnits' not in content:
        marker = '''  Set<String> get _allVariantIds =>
      widget.variants.map((item) => item.id).toSet();
'''
        content = replace_once(
            content,
            marker,
            marker + '\n' + getter,
            'agregar lista efectiva y deduplicada de unidades',
        )

    if content != original:
        save(STEP4, content)
    else:
        print(f'Ya corregido: {STEP4}')


def patch_presentation_parts() -> None:
    content = read(PRESENTATION_EDITOR)
    original = content
    if 'items: _effectiveBaseUnits.map((unit)' not in content:
        content = replace_once(
            content,
            'items: widget.baseUnits.map((unit) {',
            'items: _effectiveBaseUnits.map((unit) {',
            'dropdown usa unidades deduplicadas y acepta la unidad persistida',
        )
    if content != original:
        save(PRESENTATION_EDITOR, content)
    else:
        print(f'Ya corregido: {PRESENTATION_EDITOR}')

    content = read(PRESENTATION_EDITING)
    original = content
    old = '''    _presentationBaseUnit = widget.baseUnits.contains('PZA')
        ? 'PZA'
        : widget.baseUnits.first;
'''
    new = '''    final units = _effectiveBaseUnits;
    _presentationBaseUnit = units.contains('UND')
        ? 'UND'
        : units.contains('PZA')
        ? 'PZA'
        : units.first;
'''
    if "final units = _effectiveBaseUnits;" not in content:
        content = replace_once(
            content,
            old,
            new,
            'preferir UND al crear presentaciones nuevas',
        )
    if content != original:
        save(PRESENTATION_EDITING, content)
    else:
        print(f'Ya corregido: {PRESENTATION_EDITING}')


BULK_FORM_METHOD = r"""  Future<CatalogoFormData> obtenerDatosFormulario() async {
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
    final categoryRows = await db.query(
      'categorias',
      where: 'estado = 1',
      orderBy: 'nombre COLLATE NOCASE',
    );
    final relationRows = await db.rawQuery('''
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
    final attributeRows = await db.query(
      'categoria_atributos',
      where: 'estado = 1 AND activo_nuevos = 1',
      orderBy: 'categoria_id, orden, nombre COLLATE NOCASE',
    );
    final optionRows = await db.query(
      'categoria_atributo_opciones',
      columns: ['categoria_atributo_id', 'etiqueta'],
      where: 'estado = 1',
      orderBy: 'categoria_atributo_id, orden, etiqueta COLLATE NOCASE',
    );
    final unitRows = await db.rawQuery('''
      SELECT cau.categoria_atributo_id,
             u.codigo,
             u.simbolo,
             cau.es_predeterminada
      FROM categoria_atributo_unidades cau
      INNER JOIN unidades_medida u ON u.id = cau.unidad_medida_id
      WHERE cau.estado = 1 AND u.estado = 1
      ORDER BY cau.categoria_atributo_id,
               cau.es_predeterminada DESC,
               u.nombre COLLATE NOCASE
    ''');

    final categoriesById = <int, Map<String, Object?>>{};
    final childrenByParent = <int, List<Map<String, Object?>>>{};
    final roots = <Map<String, Object?>>[];
    for (final row in categoryRows) {
      final id = (row['id'] as num).toInt();
      categoriesById[id] = row;
      final parentRaw = row['categoria_padre_id'];
      if (parentRaw == null) {
        roots.add(row);
      } else {
        final parent = (parentRaw as num).toInt();
        childrenByParent.putIfAbsent(parent, () => []).add(row);
      }
    }

    final attributesByCategory = <int, List<Map<String, Object?>>>{};
    for (final row in attributeRows) {
      final categoryId = (row['categoria_id'] as num).toInt();
      attributesByCategory.putIfAbsent(categoryId, () => []).add(row);
    }
    final optionsByAttribute = <String, List<String>>{};
    for (final row in optionRows) {
      final id = row['categoria_atributo_id']?.toString() ?? '';
      final label = row['etiqueta']?.toString().trim() ?? '';
      if (id.isEmpty || label.isEmpty) continue;
      optionsByAttribute.putIfAbsent(id, () => []).add(label);
    }
    final unitsByAttribute = <String, List<Map<String, Object?>>>{};
    for (final row in unitRows) {
      final id = row['categoria_atributo_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      unitsByAttribute.putIfAbsent(id, () => []).add(row);
    }

    AtributoDef toDefinition(Map<String, Object?> row) {
      final id = row['id']?.toString() ?? '';
      final units = <String>[];
      String? defaultUnit;
      for (final unit in unitsByAttribute[id] ?? const []) {
        final symbol = unit['simbolo']?.toString().trim() ?? '';
        if (symbol.isNotEmpty && !units.contains(symbol)) units.add(symbol);
        if ((unit['es_predeterminada'] as num? ?? 0).toInt() == 1 &&
            symbol.isNotEmpty) {
          defaultUnit ??= symbol;
        }
      }
      final capture = row['nivel_captura']?.toString() ?? 'familia';
      return AtributoDef(
        id: id,
        nombre: row['nombre']?.toString() ?? '',
        clave: row['clave']?.toString() ?? '',
        tipo: row['tipo_dato']?.toString() ?? 'texto_corto',
        esVariante:
            capture == 'variante' ||
            (capture == 'decidir' &&
                (row['puede_ser_eje'] as num? ?? 0).toInt() == 1),
        requerido: (row['requerido_activar'] as num? ?? 0).toInt() == 1,
        opciones: List.unmodifiable(optionsByAttribute[id] ?? const []),
        unidades: List.unmodifiable(units),
        unidadPredeterminada: defaultUnit,
        minimo: (row['minimo'] as num?)?.toDouble(),
        maximo: (row['maximo'] as num?)?.toDouble(),
        decimales: (row['decimales'] as num? ?? 0).toInt(),
        maximoSelecciones: (row['maximo_selecciones'] as num?)?.toInt(),
        magnitud: row['magnitud']?.toString(),
        nivelCaptura: capture,
        puedeSerEje: (row['puede_ser_eje'] as num? ?? 0).toInt() == 1,
        ayuda: row['ayuda']?.toString() ?? '',
        ejemplo: row['ejemplo']?.toString() ?? '',
      );
    }

    List<AtributoDef> effectiveDefinitions(int categoryId) {
      final byKey = <String, Map<String, Object?>>{};
      for (final row in attributesByCategory[categoryId] ?? const []) {
        final key = row['clave']?.toString() ?? '';
        if (key.isNotEmpty) byKey.putIfAbsent(key, () => row);
      }
      final parentRaw = categoriesById[categoryId]?['categoria_padre_id'];
      if (parentRaw != null) {
        final parentId = (parentRaw as num).toInt();
        for (final row in attributesByCategory[parentId] ?? const []) {
          final key = row['clave']?.toString() ?? '';
          if (key.isNotEmpty) byKey.putIfAbsent(key, () => row);
        }
      }
      return byKey.values.map(toDefinition).toList();
    }

    final subcategorias = <String, List<String>>{};
    final atributos = <String, List<AtributoDef>>{};
    roots.sort(
      (a, b) => (a['nombre']?.toString() ?? '').toLowerCase().compareTo(
        (b['nombre']?.toString() ?? '').toLowerCase(),
      ),
    );
    for (final root in roots) {
      final id = (root['id'] as num).toInt();
      final name = root['nombre']?.toString() ?? '';
      final children = [...(childrenByParent[id] ?? const [])]
        ..sort(
          (a, b) => (a['nombre']?.toString() ?? '').toLowerCase().compareTo(
            (b['nombre']?.toString() ?? '').toLowerCase(),
          ),
        );
      subcategorias[name] = children
          .map((row) => row['nombre']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
      atributos[name] = effectiveDefinitions(id);
      for (final child in children) {
        final childId = (child['id'] as num).toInt();
        final childName = child['nombre']?.toString() ?? '';
        if (childName.isNotEmpty) {
          atributos[childName] = effectiveDefinitions(childId);
        }
      }
    }

    final marcasPorEmpresa = <String, List<String>>{};
    for (final marca in marcas) {
      final empresa = marca['empresa']?.toString() ?? '';
      final nombre = marca['nombre']?.toString() ?? '';
      if (empresa.isEmpty || nombre.isEmpty) continue;
      marcasPorEmpresa.putIfAbsent(empresa, () => []).add(nombre);
    }
    final categoriasPorMarca = <String, List<String>>{};
    for (final relation in relationRows) {
      final empresa = relation['empresa']?.toString() ?? '';
      final marca = relation['marca']?.toString() ?? '';
      final categoria = relation['categoria']?.toString() ?? '';
      if (empresa.isEmpty || marca.isEmpty || categoria.isEmpty) continue;
      categoriasPorMarca
          .putIfAbsent('$empresa::$marca', () => [])
          .add(categoria);
    }

    return CatalogoFormData(
      empresas: empresas
          .map((row) => row['nombre']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(),
      marcas: marcas
          .map((row) => row['nombre']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      subcategorias: subcategorias,
      atributos: atributos,
      marcasPorEmpresa: marcasPorEmpresa,
      categoriasPorMarca: categoriasPorMarca,
    );
  }
"""

DETAIL_HELPERS_AND_METHODS = r'''  Object? _decodeJsonSafely(Object? value, Object? fallback) {
    if (value == null) return fallback;
    if (value is! String) return value;
    if (value.trim().isEmpty) return fallback;
    try {
      return jsonDecode(value);
    } catch (_) {
      return fallback;
    }
  }

  String _readString(Object? value, [String fallback = '']) =>
      value?.toString() ?? fallback;

  double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  String _valorAtributoLegible(Object? raw) {
    if (raw == null) return '';
    if (raw is bool) return raw ? 'Sí' : 'No';
    if (raw is List) {
      return raw
          .map(_valorAtributoLegible)
          .where((value) => value.isNotEmpty)
          .join(' · ');
    }
    if (raw is Map) {
      final map = Map<Object?, Object?>.from(raw);
      final selected = map['values'] ?? map['valores'];
      if (selected is List && selected.isNotEmpty) {
        final rendered = _valorAtributoLegible(selected);
        if (rendered.isNotEmpty) return rendered;
      }
      final value =
          map['value'] ?? map['valor'] ?? map['text'] ?? map['texto'] ?? map['label'];
      final unit = map['unit'] ?? map['unidad'];
      final renderedValue = _valorAtributoLegible(value);
      final renderedUnit = unit?.toString().trim() ?? '';
      if (renderedValue.isEmpty) return '';
      return renderedUnit.isEmpty
          ? renderedValue
          : '$renderedValue $renderedUnit';
    }
    return raw.toString().trim();
  }

  ProductoResumen _resumenFromMap(Map<String, Object?> row) {
    final atributosDecoded = _decodeJsonSafely(row['atributos_json'], const {});
    final atributos = atributosDecoded is Map
        ? Map<String, dynamic>.from(atributosDecoded)
        : <String, dynamic>{};
    final presentationsDecoded = _decodeJsonSafely(
      row['presentaciones_json'],
      const [],
    );
    final presentacionesRaw = presentationsDecoded is List
        ? presentationsDecoded
        : const <Object?>[];
    final presentaciones = <String>[];
    for (final item in presentacionesRaw.whereType<Map>()) {
      final name = item['nombre']?.toString().trim() ??
          item['name']?.toString().trim() ??
          '';
      if (name.isNotEmpty && !presentaciones.contains(name)) {
        presentaciones.add(name);
      }
    }
    final saleUnit = _readString(row['unidad_venta'], 'Unidad').trim();
    if (presentaciones.isEmpty && saleUnit.isNotEmpty) {
      presentaciones.add(saleUnit);
    }
    final imagenes = _imagenesFromMap(row);
    return ProductoResumen(
      id: _readString(row['id']),
      codigo: _readString(row['codigo']),
      nombre: _readString(row['nombre']),
      empresa: _readString(row['empresa']),
      marca: _readString(row['marca']),
      categoria: _readString(row['categoria']),
      subcategoria: _readString(row['subcategoria']),
      unidadVenta: saleUnit,
      precio: _readDouble(row['precio']),
      sinPrecio: (row['sin_precio'] as num? ?? 0).toInt() == 1,
      activo: (row['activo'] as num? ?? 0).toInt() == 1,
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
      tipoRegistro: _readString(row['tipo_registro'], 'simple'),
      presentaciones: presentaciones,
      atributosClave: atributos.entries
          .map((entry) => MapEntry(entry.key, _valorAtributoLegible(entry.value)))
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) => '${entry.key}: ${entry.value}')
          .toList(),
      creadoEn: DateTime.tryParse(_readString(row['creado_en'])),
    );
  }

  ProductoDetalle _detalleFromMap(Map<String, Object?> row) {
    final atributosDecoded = _decodeJsonSafely(row['atributos_json'], const {});
    final atributosRaw = atributosDecoded is Map
        ? Map<String, dynamic>.from(atributosDecoded)
        : <String, dynamic>{};
    final presentationsDecoded = _decodeJsonSafely(
      row['presentaciones_json'],
      const [],
    );
    final presentacionesRaw = presentationsDecoded is List
        ? presentationsDecoded
        : const <Object?>[];
    final pricesDecoded = _decodeJsonSafely(row['precios_json'], const []);
    final preciosRaw = pricesDecoded is List ? pricesDecoded : const <Object?>[];

    final ventaLogisticaRaw = _decodeJsonSafely(
      row['venta_logistica_json'],
      const {},
    );
    final ventaLogistica = ventaLogisticaRaw is Map
        ? Map<String, dynamic>.from(ventaLogisticaRaw)
        : null;
    final preciosConfiguradosRaw = _decodeJsonSafely(
      row['precios_configurados_json'],
      const {},
    );
    final preciosConfigurados = preciosConfiguradosRaw is Map
        ? Map<String, dynamic>.from(preciosConfiguradosRaw)
        : null;
    final imagenesConfiguradasRaw = _decodeJsonSafely(
      row['imagenes_configuradas_json'],
      const {},
    );
    final imagenesConfiguradas = imagenesConfiguradasRaw is Map
        ? Map<String, dynamic>.from(imagenesConfiguradasRaw)
        : null;

    final imagenes = _imagenesFromMap(row);
    final variantsDecoded = _decodeJsonSafely(row['variantes_json'], const []);
    final variantesRaw = variantsDecoded is List
        ? variantsDecoded
        : const <Object?>[];
    final variantes = <ProductoVariante>[];
    for (final item in variantesRaw.whereType<Map>()) {
      variantes.add(
        ProductoVariante.fromMap(Map<String, dynamic>.from(item)),
      );
    }

    final presentaciones = <PresentacionProducto>[];
    for (final item in presentacionesRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final name = map['nombre']?.toString().trim() ??
          map['name']?.toString().trim() ??
          '';
      final unit = map['unidad']?.toString().trim() ??
          map['baseUnit']?.toString().trim() ??
          map['base_unit']?.toString().trim() ??
          '';
      if (name.isEmpty) continue;
      presentaciones.add(
        PresentacionProducto(
          nombre: name,
          unidad: unit.isEmpty ? 'UND' : unit,
        ),
      );
    }
    if (presentaciones.isEmpty) {
      presentaciones.add(
        PresentacionProducto(
          nombre: _readString(row['unidad_venta'], 'Unidad'),
          unidad: 'UND',
        ),
      );
    }

    final precios = <PrecioProducto>[];
    for (final item in preciosRaw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final value = _readDouble(map['valor'] ?? map['price']);
      if (value == null) continue;
      precios.add(
        PrecioProducto(
          presentacion:
              map['presentacion']?.toString() ?? map['presentation']?.toString() ?? 'Unidad',
          valor: value,
          listaPrecioId:
              map['lista_precio_id']?.toString() ?? map['priceListId']?.toString() ?? '',
          varianteId:
              map['variante_id']?.toString() ?? map['variantId']?.toString() ?? '',
          presentacionId:
              map['presentacion_id']?.toString() ?? map['presentationId']?.toString() ?? '',
          configuracion:
              map['configuracion']?.toString() ?? map['configuration']?.toString() ?? 'precio_fijo',
        ),
      );
    }
    final rowPrice = _readDouble(row['precio']);
    if (precios.isEmpty && rowPrice != null) {
      precios.add(
        PrecioProducto(
          presentacion: presentaciones.first.nombre,
          valor: rowPrice,
        ),
      );
    }

    return ProductoDetalle(
      id: _readString(row['id']),
      codigo: _readString(row['codigo']),
      nombre: _readString(row['nombre']),
      descripcion: _readString(row['descripcion']),
      empresa: _readString(row['empresa']),
      marca: _readString(row['marca']),
      categoria: _readString(row['categoria']),
      subcategoria: _readString(row['subcategoria']),
      tipoRegistro: _readString(row['tipo_registro'], 'simple'),
      atributos: {
        for (final entry in atributosRaw.entries)
          if (_valorAtributoLegible(entry.value).isNotEmpty)
            entry.key: _valorAtributoLegible(entry.value),
      },
      presentaciones: presentaciones,
      precios: precios,
      activo: (row['activo'] as num? ?? 0).toInt() == 1,
      creadoEn:
          DateTime.tryParse(_readString(row['creado_en'])) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      variantes: variantes,
      imagenPath: imagenes.isEmpty ? null : imagenes.first,
      imagenesPaths: imagenes,
      ventaLogisticaContenido: ventaLogistica,
      preciosConfigurados: preciosConfigurados,
      imagenesConfiguradas: imagenesConfiguradas,
    );
  }
'''


def patch_catalog_datasource() -> None:
    content = read(CATALOG_DS)
    original = content

    if 'final attributeRows = await db.query(' not in content or "'categoria_atributos',\n      where: 'estado = 1 AND activo_nuevos = 1'" not in content:
        content = replace_method(
            content,
            '  Future<CatalogoFormData> obtenerDatosFormulario() async {',
            '  Future<void> guardarProducto(',
            BULK_FORM_METHOD + '\n',
            'carga masiva de datos maestros del formulario',
        )

    if 'String _valorAtributoLegible(Object? raw)' not in content:
        content = replace_method(
            content,
            '  ProductoResumen _resumenFromMap(',
            '  List<String> _rutasImagenesConfiguradasDesdeFila(',
            DETAIL_HELPERS_AND_METHODS + '\n',
            'parseo defensivo y atributos legibles',
        )

    if content != original:
        save(CATALOG_DS, content)
    else:
        print(f'Ya corregido: {CATALOG_DS}')


SYNC_PROJECTION = r'''  Future<void> _restoreProjectionRows(
    DatabaseExecutor database, {
    required String productId,
    required Map<String, Object?> aggregate,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    for (final axis in _asMaps(aggregate['familyAxes'])) {
      final attributeId =
          axis['categoria_atributo_id']?.toString() ??
          axis['categoryAttributeId']?.toString() ??
          '';
      if (attributeId.isEmpty) continue;
      await database.insert('producto_familia_ejes', {
        'producto_id': productId,
        'categoria_atributo_id': attributeId,
        'orden': (axis['orden'] as num? ?? axis['order'] as num? ?? 0).toInt(),
      });
    }

    final attributeColumns = (await database.rawQuery(
      'PRAGMA table_info(producto_atributos)',
    )).map((column) => column['name']?.toString() ?? '').toSet();
    final optionColumns = (await database.rawQuery(
      'PRAGMA table_info(producto_atributo_opciones)',
    )).map((column) => column['name']?.toString() ?? '').toSet();

    final rawOptions = _asMaps(aggregate['attributeOptions']);
    final optionsByAttribute = <String, List<Map<String, Object?>>>{};
    for (final option in rawOptions) {
      final attributeId = option['producto_atributo_id']?.toString() ??
          option['productAttributeId']?.toString() ??
          '';
      if (attributeId.isNotEmpty) {
        optionsByAttribute.putIfAbsent(attributeId, () => []).add(option);
      }
    }

    final definitionByValue = <String, String>{};
    final restoredAttributeIds = <String>{};
    for (final row in _asMaps(aggregate['attributeValues'])) {
      final id = row['id']?.toString() ?? '';
      final definitionId =
          row['categoria_atributo_id']?.toString() ??
          row['categoryAttributeId']?.toString() ??
          '';
      if (id.isEmpty || definitionId.isEmpty) continue;

      final variantId =
          (row['variante_id']?.toString() ??
                  row['variantId']?.toString() ??
                  '')
              .trim();
      final unitRelationId =
          (row['categoria_atributo_unidad_id']?.toString() ??
                  row['categoryAttributeUnitId']?.toString() ??
                  '')
              .trim();
      final updatedAt = (row['actualizado_en']?.toString() ?? '').trim();
      final remoteUpdatedAt = (row['updatedAt']?.toString() ?? '').trim();
      final textValue = row['valor_texto'] ?? row['textValue'];
      final numberValue = _projectionDouble(
        row['valor_numero'] ?? row['numberValue'],
      );
      final maximumValue = _projectionDouble(
        row['valor_numero_hasta'] ??
            row['valor_maximo'] ??
            row['maximumValue'],
      );
      final booleanValue = _projectionBoolean(
        row['valor_booleano'] ?? row['booleanValue'],
      );
      final hasOptions = (optionsByAttribute[id] ?? const []).isNotEmpty;

      final values = <String, Object?>{
        'id': id,
        'categoria_atributo_id': definitionId,
        'producto_id': variantId.isEmpty ? productId : null,
        'variante_id': variantId.isEmpty ? null : variantId,
        'categoria_atributo_unidad_id':
            unitRelationId.isEmpty ? null : unitRelationId,
        'tipo_valor': hasOptions
            ? 'lista'
            : booleanValue != null
            ? 'booleano'
            : numberValue != null && unitRelationId.isNotEmpty
            ? 'numero_unidad'
            : numberValue != null
            ? 'numero'
            : 'texto',
        'valor_texto': textValue?.toString(),
        'valor_numero': numberValue,
        'valor_numero_hasta': maximumValue,
        'valor_booleano': booleanValue,
        'actualizado_en': updatedAt.isNotEmpty
            ? updatedAt
            : remoteUpdatedAt.isNotEmpty
            ? remoteUpdatedAt
            : now,
      };
      if (numberValue != null) {
        values['valor_normalizado'] = await _normalizedProjectionNumber(
          database,
          numberValue,
          unitRelationId,
        );
      } else if (booleanValue != null) {
        values['valor_normalizado'] = booleanValue.toDouble();
      }
      if (maximumValue != null) {
        values['valor_normalizado_hasta'] = await _normalizedProjectionNumber(
          database,
          maximumValue,
          unitRelationId,
        );
      }

      values.removeWhere((key, _) => !attributeColumns.contains(key));
      await database.insert('producto_atributos', values);
      restoredAttributeIds.add(id);
      definitionByValue[id] = definitionId;
    }

    for (final row in rawOptions) {
      final attributeId = row['producto_atributo_id']?.toString() ??
          row['productAttributeId']?.toString() ??
          '';
      if (!restoredAttributeIds.contains(attributeId)) continue;
      final definitionId =
          row['categoria_atributo_id']?.toString() ??
          row['categoryAttributeId']?.toString() ??
          definitionByValue[attributeId] ??
          '';
      final optionId =
          row['opcion_id']?.toString() ?? row['optionId']?.toString() ?? '';
      if (definitionId.isEmpty || optionId.isEmpty) continue;
      final values = <String, Object?>{
        'producto_atributo_id': attributeId,
        'categoria_atributo_id': definitionId,
        'opcion_id': optionId,
      };
      values.removeWhere((key, _) => !optionColumns.contains(key));
      await database.insert('producto_atributo_opciones', values);
    }
  }

  double? _projectionDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }

  int? _projectionBoolean(Object? value) {
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toInt() == 0 ? 0 : 1;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (const {'true', 'si', 'sí', '1'}.contains(normalized)) return 1;
    if (const {'false', 'no', '0'}.contains(normalized)) return 0;
    return null;
  }

  Future<double> _normalizedProjectionNumber(
    DatabaseExecutor database,
    double value,
    String unitRelationId,
  ) async {
    if (unitRelationId.isEmpty) return value;
    final rows = await database.rawQuery(
      'SELECT u.factor_a_base AS factor '
      'FROM categoria_atributo_unidades cau '
      'INNER JOIN unidades_medida u ON u.id = cau.unidad_medida_id '
      'WHERE cau.id = ? LIMIT 1',
      [unitRelationId],
    );
    if (rows.isEmpty) return value;
    final factor = _projectionDouble(rows.single['factor']);
    return factor == null ? value : value * factor;
  }

'''

SYNC_HELPERS = r'''  Map<String, Object?> _localFamilyAttributes(Object? value) {
    if (value is! Map) return const {};
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final name = entry.key.toString().trim();
      if (name.isEmpty) continue;
      final rendered = _displayAttributeValue(entry.value);
      if (rendered.isNotEmpty) result[name] = rendered;
    }
    return result;
  }

  String _displayAttributeValue(Object? raw) {
    if (raw == null) return '';
    if (raw is bool) return raw ? 'Sí' : 'No';
    if (raw is List) {
      return raw
          .map(_displayAttributeValue)
          .where((value) => value.isNotEmpty)
          .join(' · ');
    }
    if (raw is Map) {
      final details = Map<Object?, Object?>.from(raw);
      final selected = details['values'] ?? details['valores'];
      if (selected is List && selected.isNotEmpty) {
        final rendered = _displayAttributeValue(selected);
        if (rendered.isNotEmpty) return rendered;
      }
      final value = details['value'] ?? details['valor'] ?? details['text'];
      final unit = details['unit'] ?? details['unidad'];
      final renderedValue = _displayAttributeValue(value);
      final renderedUnit = unit?.toString().trim() ?? '';
      if (renderedValue.isEmpty) return '';
      return renderedUnit.isEmpty
          ? renderedValue
          : '$renderedValue $renderedUnit';
    }
    return raw.toString().trim();
  }

  String _commercialDescription(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    final normalized = text.toLowerCase();
    final looksLikeTrace =
        normalized.contains('familia extraída') ||
        normalized.contains('familia extraida') ||
        normalized.contains('páginas:') ||
        normalized.contains('paginas:') ||
        normalized.contains('archivo pdf:') ||
        (normalized.contains('lista interactiva') &&
            normalized.contains('extra'));
    return looksLikeTrace ? '' : text;
  }

'''


def patch_product_sync() -> None:
    content = read(PRODUCT_SYNC)
    original = content

    if "'descripcion': _commercialDescription(" not in content:
        content = replace_once(
            content,
            "      'descripcion': aggregate['description']?.toString() ?? '',",
            "      'descripcion': _commercialDescription(aggregate['description']),",
            'limpiar trazabilidad de la descripcion local',
        )
    if "'atributos_json': jsonEncode(_localFamilyAttributes(attributes))," not in content:
        content = replace_once(
            content,
            "      'atributos_json': jsonEncode(Map<String, Object?>.from(attributes)),",
            "      'atributos_json': jsonEncode(_localFamilyAttributes(attributes)),",
            'guardar atributos familiares como texto comercial',
        )

    if 'Future<double> _normalizedProjectionNumber(' not in content:
        content = replace_method(
            content,
            '  Future<void> _restoreProjectionRows(',
            '  Future<List<Map<String, Object?>>> _exportImages(',
            SYNC_PROJECTION,
            'restauracion robusta de atributos sincronizados',
        )

    if 'Map<String, Object?> _localFamilyAttributes(Object? value)' not in content:
        marker = '  Map<String, Object?> _localVariant(Map<String, Object?> row) => {'
        pos = content.find(marker)
        if pos < 0:
            raise SystemExit('No se encontro _localVariant para insertar helpers comerciales.')
        content = content[:pos] + SYNC_HELPERS + content[pos:]

    if content != original:
        save(PRODUCT_SYNC, content)
    else:
        print(f'Ya corregido: {PRODUCT_SYNC}')


TEST_CONTENT = r'''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_catalogo/features/catalogo/presentation/models/producto_form/venta_logistica_draft.dart';
import 'package:app_catalogo/features/catalogo/presentation/sections/producto_form/venta_logistica_section.dart';

void main() {
  testWidgets('una presentacion importada con UND no rompe el dropdown', (
    tester,
  ) async {
    const variant = Step4VariantOption(id: 'v1', label: 'Unidad');
    const presentation = SalesPresentationDraft(
      id: 'p1',
      name: 'Unidad',
      baseUnit: 'UND',
      equivalentTo: 1,
      minimumOrder: 1,
      purchaseIncrement: 1,
      allowsDecimals: false,
      assignedVariantIds: {'v1'},
      defaultVariantIds: {'v1'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Step4SalesLogisticsContentPanel(
            familyName: 'Producto de prueba',
            variantLayout: Step4VariantLayout.single,
            variants: const [variant],
            initialPresentations: const [presentation],
            onBack: () {},
            onNext: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('UND'), findsWidgets);
  });
}
'''


def add_regression_test() -> None:
    path = APP / REGRESSION_TEST
    if path.exists() and 'presentacion importada con UND' in path.read_text(encoding='utf-8'):
        print(f'Ya existe: {REGRESSION_TEST}')
        return
    save(REGRESSION_TEST, TEST_CONTENT)


def main() -> None:
    global CHECK_MODE
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--check',
        action='store_true',
        help='Valida los puntos de parcheo sin escribir archivos.',
    )
    args = parser.parse_args()
    CHECK_MODE = args.check

    print(f'App detectada: {APP}')
    if CHECK_MODE:
        print('Modo CHECK: no se modificara ningun archivo.')
    else:
        print(f'Copias de seguridad: {BACKUP_ROOT.relative_to(APP)}')
    patch_step4()
    patch_presentation_parts()
    patch_catalog_datasource()
    patch_product_sync()
    add_regression_test()

    if CHECK_MODE:
        print('\nCHECK COMPLETO: los puntos de correccion fueron reconocidos.')
        return

    print('\nCorreccion comercial Flutter aplicada.')
    print('\nEjecuta:')
    print(r'  & "D:\flutter\bin\dart.bat" format lib test')
    print(r'  & "D:\flutter\bin\dart.bat" analyze --no-fatal-warnings')
    print(r'  & "D:\flutter\bin\flutter.bat" test --no-pub --exclude-tags baseline-known-failure')
    print(r'  & "D:\flutter\bin\flutter.bat" run')
    print('\nPrueba despues: lista -> detalle -> editar -> paso Venta/presentaciones.')


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'ERROR: {error}', file=sys.stderr)
        raise
