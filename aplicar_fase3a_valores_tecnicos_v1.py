from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

FILES = {
    "variant": ROOT / "lib/features/catalogo/domain/entities/producto_variante.dart",
    "form_data": ROOT / "lib/features/catalogo/domain/entities/catalogo_form_data.dart",
    "datasource": ROOT / "lib/features/catalogo/data/datasources/catalogo_local_datasource.dart",
    "database": ROOT / "lib/core/database/app_database.dart",
    "single": ROOT / "lib/features/catalogo/presentation/widgets/producto_unico_step.dart",
}

PARSER_PATH = (
    ROOT
    / "lib/features/catalogo/domain/services/valor_tecnico_parser.dart"
)
TEST_PATH = ROOT / "test/valor_tecnico_parser_test.dart"


def fail(message: str) -> None:
    raise SystemExit(f"\nERROR: {message}\nNo se escribió ningún archivo.")


def read(path: Path) -> str:
    if not path.exists():
        fail(f"No se encontró {path}")
    return path.read_text(encoding="utf-8")


def replace_once(content: str, old: str, new: str, label: str) -> str:
    count = content.count(old)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 coincidencia y se encontraron {count}."
        )
    return content.replace(old, new, 1)


def regex_once(
    content: str,
    pattern: str,
    replacement: str,
    label: str,
    *,
    flags: int = re.DOTALL,
) -> str:
    updated, count = re.subn(pattern, replacement, content, count=1, flags=flags)
    if count != 1:
        fail(
            f"No se pudo aplicar “{label}”. "
            f"Se esperaba 1 bloque compatible y se encontraron {count}."
        )
    return updated


contents = {name: read(path) for name, path in FILES.items()}

if "codigoProveedor" not in contents["variant"]:
    fail(
        "La fase 2 no está aplicada en ProductoVariante. "
        "Primero completa la reparación de códigos."
    )

if "version: 20" not in contents["database"]:
    fail(
        "La base local no está en versión 20. "
        "La fase 3A espera la migración de códigos ya aplicada."
    )

if PARSER_PATH.exists() or TEST_PATH.exists():
    fail("La fase 3A ya parece estar aplicada.")

# ---------------------------------------------------------------------------
# Servicio de análisis de valores técnicos.
# ---------------------------------------------------------------------------

parser_content = r'''enum TipoValorTecnico { numero, rango, compuesto, texto }

class EntradaValorUnidad {
  const EntradaValorUnidad({
    required this.valor,
    required this.unidad,
  });

  final String valor;
  final String unidad;
}

class ValorTecnicoParseado {
  const ValorTecnicoParseado({
    required this.original,
    required this.unidad,
    required this.tipo,
    required this.valores,
  });

  final String original;
  final String unidad;
  final TipoValorTecnico tipo;
  final List<double> valores;

  bool get esNumerico =>
      tipo != TipoValorTecnico.texto && valores.isNotEmpty;

  double? get minimo {
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a < b ? a : b);
  }

  double? get maximo {
    if (valores.isEmpty) return null;
    return valores.reduce((a, b) => a > b ? a : b);
  }

  bool get tieneDosExtremos => valores.length == 2;
}

abstract final class ValorTecnicoParser {
  static const String _numberToken =
      r'(?:[-+]?\d+\s+\d+\s*/\s*\d+|'
      r'[-+]?\d+\s*/\s*\d+|'
      r'[-+]?\d+(?:[.,]\d+)?)';

  static final RegExp _range = RegExp(
    '^($_numberToken)\\s*(?:-|–|—|a)\\s*($_numberToken)\$',
    caseSensitive: false,
  );

  static final RegExp _compound = RegExp(
    r'^([-+]?\d+(?:[.,]\d+)?)\s*/\s*([-+]?\d+(?:[.,]\d+)?)$',
  );

  static final RegExp _mixed = RegExp(
    r'^([-+]?\d+)\s+(\d+)\s*/\s*(\d+)$',
  );

  static final RegExp _fraction = RegExp(
    r'^([-+]?\d+)\s*/\s*(\d+)$',
  );

  static final RegExp _decimal = RegExp(
    r'^[-+]?\d+(?:[.,]\d+)?$',
  );

  static ValorTecnicoParseado parse(
    String raw, {
    String unidad = '',
  }) {
    final original = raw.trim();
    final cleanUnit = unidad.trim();

    final range = _range.firstMatch(original);
    if (range != null) {
      final first = parseNumero(range.group(1)!);
      final second = parseNumero(range.group(2)!);
      if (first != null && second != null) {
        return ValorTecnicoParseado(
          original: original,
          unidad: cleanUnit,
          tipo: TipoValorTecnico.rango,
          valores: [first, second],
        );
      }
    }

    final compound = _compound.firstMatch(original);
    if (compound != null) {
      final first = double.tryParse(
        compound.group(1)!.replaceAll(',', '.'),
      );
      final second = double.tryParse(
        compound.group(2)!.replaceAll(',', '.'),
      );
      if (first != null &&
          second != null &&
          _esCompuesto(first, second, cleanUnit)) {
        return ValorTecnicoParseado(
          original: original,
          unidad: cleanUnit,
          tipo: TipoValorTecnico.compuesto,
          valores: [first, second],
        );
      }
    }

    final number = parseNumero(original);
    if (number != null) {
      return ValorTecnicoParseado(
        original: original,
        unidad: cleanUnit,
        tipo: TipoValorTecnico.numero,
        valores: [number],
      );
    }

    return ValorTecnicoParseado(
      original: original,
      unidad: cleanUnit,
      tipo: TipoValorTecnico.texto,
      valores: const [],
    );
  }

  static double? parseNumero(String raw) {
    final value = raw.trim();

    final mixed = _mixed.firstMatch(value);
    if (mixed != null) {
      final whole = double.parse(mixed.group(1)!);
      final numerator = double.parse(mixed.group(2)!);
      final denominator = double.parse(mixed.group(3)!);
      if (denominator == 0) return null;
      final sign = whole < 0 ? -1.0 : 1.0;
      return whole + sign * numerator / denominator;
    }

    final fraction = _fraction.firstMatch(value);
    if (fraction != null) {
      final numerator = double.parse(fraction.group(1)!);
      final denominator = double.parse(fraction.group(2)!);
      return denominator == 0 ? null : numerator / denominator;
    }

    if (!_decimal.hasMatch(value)) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  static EntradaValorUnidad separarValorUnidad(String raw) {
    final original = raw.trim();
    if (original.isEmpty) {
      return const EntradaValorUnidad(valor: '', unidad: '');
    }

    final match = RegExp(
      r'^(.+?)\s*([A-Za-zµ°%″"][A-Za-z0-9µ°%″"/.\-·]*)$',
    ).firstMatch(original);

    if (match == null) {
      return EntradaValorUnidad(valor: original, unidad: '');
    }

    final value = match.group(1)!.trim();
    final unit = match.group(2)!.trim();
    final parsed = parse(value, unidad: unit);

    if (!parsed.esNumerico) {
      return EntradaValorUnidad(valor: original, unidad: '');
    }

    return EntradaValorUnidad(valor: value, unidad: unit);
  }

  static bool _esCompuesto(
    double first,
    double second,
    String unidad,
  ) {
    final normalizedUnit = unidad.trim().toLowerCase();
    if (normalizedUnit == 'hz') return true;
    return first.abs() >= 10 && second.abs() >= 10;
  }
}
'''

# ---------------------------------------------------------------------------
# Entidad de atributo/variante ampliada.
# ---------------------------------------------------------------------------

variant_content = r'''import 'package:equatable/equatable.dart';

import '../services/valor_tecnico_parser.dart';

class AtributoProductoVariante extends Equatable {
  const AtributoProductoVariante({
    required this.nombre,
    required this.valor,
    this.unidad = '',
    this.valorNormalizado,
    this.valorMaximo,
    this.valores = const [],
  });

  final String nombre;

  /// Texto original capturado. Conserva fracciones, rangos y valores
  /// compuestos exactamente como fueron ingresados.
  final String valor;

  final String unidad;

  /// Extremo inferior o valor único convertido a número cuando corresponde.
  final double? valorNormalizado;

  /// Extremo superior para rangos o segundo valor para datos compuestos.
  final double? valorMaximo;

  /// Opciones seleccionadas cuando el atributo es de selección múltiple.
  final List<String> valores;

  String get texto {
    if (valores.isNotEmpty) return valores.join(' · ');
    return unidad.trim().isEmpty
        ? valor.trim()
        : '${valor.trim()} ${unidad.trim()}';
  }

  bool get esRango =>
      valorNormalizado != null &&
      valorMaximo != null &&
      valorNormalizado != valorMaximo;

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'valor': valor,
    'unidad': unidad,
    'valor_normalizado': valorNormalizado,
    'valor_maximo': valorMaximo,
    'valores': valores,
  };

  factory AtributoProductoVariante.fromMap(Map<String, dynamic> map) =>
      AtributoProductoVariante(
        nombre: map['nombre'] as String? ?? '',
        valor: map['valor']?.toString() ?? '',
        unidad: map['unidad'] as String? ?? '',
        valorNormalizado: (map['valor_normalizado'] as num?)?.toDouble(),
        valorMaximo: (map['valor_maximo'] as num?)?.toDouble(),
        valores: (map['valores'] as List?)
                ?.map((item) => item.toString())
                .where((item) => item.trim().isNotEmpty)
                .toList() ??
            const [],
      );

  factory AtributoProductoVariante.fromText(String nombre, String texto) {
    final separated = ValorTecnicoParser.separarValorUnidad(texto);
    final parsed = ValorTecnicoParser.parse(
      separated.valor,
      unidad: separated.unidad,
    );

    return AtributoProductoVariante(
      nombre: nombre,
      valor: separated.valor,
      unidad: separated.unidad,
      valorNormalizado: parsed.minimo,
      valorMaximo: parsed.tieneDosExtremos ? parsed.maximo : null,
    );
  }

  @override
  List<Object?> get props => [
    nombre,
    valor,
    unidad,
    valorNormalizado,
    valorMaximo,
    valores,
  ];
}

class ProductoVariante extends Equatable {
  const ProductoVariante({
    required this.id,
    required this.sku,
    required this.nombreCorto,
    required this.atributos,
    this.codigoProveedor = '',
    this.activa = true,
    this.imagenPath,
  });

  final String id;

  /// Código interno automático. Se conserva el nombre `sku` para mantener
  /// compatibilidad con los módulos existentes y los datos ya almacenados.
  final String sku;

  /// Código comercial proporcionado por el fabricante o distribuidor.
  final String codigoProveedor;

  final String nombreCorto;
  final List<AtributoProductoVariante> atributos;
  final bool activa;
  final String? imagenPath;

  String get atributosTexto {
    final values = atributos
        .map((atributo) => atributo.texto)
        .where((value) => value.isNotEmpty);
    return values.isEmpty ? 'Sin atributos' : values.join(' · ');
  }

  String get combinacionNormalizada {
    final values =
        atributos
            .where(
              (atributo) =>
                  atributo.valor.trim().isNotEmpty ||
                  atributo.valores.isNotEmpty,
            )
            .map(
              (atributo) =>
                  '${atributo.nombre.trim().toLowerCase()}:'
                  '${atributo.valor.trim().toLowerCase()}:'
                  '${atributo.unidad.trim().toLowerCase()}:'
                  '${atributo.valores.map((item) => item.toLowerCase()).join(",")}',
            )
            .toList()
          ..sort();
    return values.join('|');
  }

  ProductoVariante copyWith({
    String? id,
    String? sku,
    String? codigoProveedor,
    String? nombreCorto,
    List<AtributoProductoVariante>? atributos,
    bool? activa,
    String? imagenPath,
  }) => ProductoVariante(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    codigoProveedor: codigoProveedor ?? this.codigoProveedor,
    nombreCorto: nombreCorto ?? this.nombreCorto,
    atributos: atributos ?? this.atributos,
    activa: activa ?? this.activa,
    imagenPath: imagenPath ?? this.imagenPath,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'sku': sku,
    'codigo_proveedor': codigoProveedor,
    'nombre_corto': nombreCorto,
    'atributos': atributos.map((atributo) => atributo.toMap()).toList(),
    'activa': activa,
    'imagen_path': imagenPath,
  };

  factory ProductoVariante.fromMap(Map<String, dynamic> map) {
    final atributos = map['atributos'];
    return ProductoVariante(
      id: map['id'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      codigoProveedor: map['codigo_proveedor'] as String? ?? '',
      nombreCorto: map['nombre_corto'] as String? ?? '',
      atributos: atributos is List
          ? atributos
                .whereType<Map>()
                .map(
                  (item) => AtributoProductoVariante.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      activa: map['activa'] as bool? ?? true,
      imagenPath: map['imagen_path'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sku,
    codigoProveedor,
    nombreCorto,
    atributos,
    activa,
    imagenPath,
  ];
}
'''

contents["variant"] = variant_content

# ---------------------------------------------------------------------------
# Definición de atributo preparada para controles avanzados.
# ---------------------------------------------------------------------------

form_data = contents["form_data"]
form_data = replace_once(
    form_data,
    "    this.unidadPredeterminada,\n"
    "  });",
    "    this.unidadPredeterminada,\n"
    "    this.minimo,\n"
    "    this.maximo,\n"
    "    this.decimales = 0,\n"
    "    this.maximoSelecciones,\n"
    "    this.magnitud,\n"
    "  });",
    "parámetros técnicos de AtributoDef",
)
form_data = replace_once(
    form_data,
    "  final String? unidadPredeterminada;\n"
    "  @override",
    "  final String? unidadPredeterminada;\n"
    "  final double? minimo;\n"
    "  final double? maximo;\n"
    "  final int decimales;\n"
    "  final int? maximoSelecciones;\n"
    "  final String? magnitud;\n"
    "  @override",
    "campos técnicos de AtributoDef",
)
form_data = replace_once(
    form_data,
    "    unidadPredeterminada,\n"
    "  ];",
    "    unidadPredeterminada,\n"
    "    minimo,\n"
    "    maximo,\n"
    "    decimales,\n"
    "    maximoSelecciones,\n"
    "    magnitud,\n"
    "  ];",
    "props técnicos de AtributoDef",
)
contents["form_data"] = form_data

# ---------------------------------------------------------------------------
# Persistencia normalizada.
# ---------------------------------------------------------------------------

datasource = contents["datasource"]
datasource = replace_once(
    datasource,
    "import '../../domain/entities/producto_variante.dart';\n",
    "import '../../domain/entities/producto_variante.dart';\n"
    "import '../../domain/services/valor_tecnico_parser.dart';\n",
    "importar parser en datasource",
)

datasource = replace_once(
    datasource,
    "          unidadPredeterminada: defaultUnit,\n",
    "          unidadPredeterminada: defaultUnit,\n"
    "          minimo: (row['minimo'] as num?)?.toDouble(),\n"
    "          maximo: (row['maximo'] as num?)?.toDouble(),\n"
    "          decimales: row['decimales'] as int? ?? 0,\n"
    "          maximoSelecciones: row['maximo_selecciones'] as int?,\n"
    "          magnitud: row['magnitud'] as String?,\n",
    "mapear configuración técnica",
)

numeric_block = r'''      case 'numero':
      case 'numero_unidad':
        final parsed = ValorTecnicoParser.parse(
          trimmed,
          unidad: unitCode,
        );
        if (!parsed.esNumerico) {
          throw StateError(
            'El valor de ${definition['nombre']} debe ser numérico, '
            'una fracción, un rango o un valor compuesto válido.',
          );
        }

        final lower = parsed.minimo!;
        final upper = parsed.maximo!;
        final minimum = (definition['minimo'] as num?)?.toDouble();
        final maximum = (definition['maximo'] as num?)?.toDouble();

        if ((minimum != null && lower < minimum) ||
            (maximum != null && upper > maximum)) {
          throw StateError(
            'El valor de ${definition['nombre']} está fuera del rango permitido.',
          );
        }

        values['tipo_valor'] = parsed.tipo.name;
        values['valor_texto'] = trimmed;
        values['valor_numero'] = lower;
        values['valor_numero_hasta'] =
            parsed.tieneDosExtremos ? upper : null;
        values['valor_normalizado'] = lower;
        values['valor_normalizado_hasta'] =
            parsed.tieneDosExtremos ? upper : null;

        if (type == 'numero_unidad') {
          final unitRows = await db.rawQuery(
            'SELECT cu.id, cu.es_predeterminada, u.factor_a_base '
            'FROM categoria_atributo_unidades cu '
            'INNER JOIN unidades_medida u '
            'ON u.id = cu.unidad_medida_id '
            'WHERE cu.categoria_atributo_id = ? '
            'AND cu.estado = 1 '
            'AND ('
            'LOWER(u.codigo) = LOWER(?) OR '
            'LOWER(u.simbolo) = LOWER(?) OR '
            "(? = '' AND cu.es_predeterminada = 1)"
            ') '
            'ORDER BY '
            'CASE WHEN LOWER(u.codigo) = LOWER(?) THEN 0 ELSE 1 END, '
            'cu.es_predeterminada DESC '
            'LIMIT 1',
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

          final factor =
              (unitRows.first['factor_a_base'] as num).toDouble();
          values['categoria_atributo_unidad_id'] = unitRows.first['id'];
          values['valor_normalizado'] = lower * factor;
          values['valor_normalizado_hasta'] =
              parsed.tieneDosExtremos ? upper * factor : null;
        }
        break;'''

datasource = regex_once(
    datasource,
    r'''      case 'numero':
      case 'numero_unidad':
.*?
        break;
      case 'lista_unica':''',
    numeric_block + "\n      case 'lista_unica':",
    "persistencia de valores numéricos técnicos",
)

datasource = replace_once(
    datasource,
    "        values['valor_texto'] = selections.join(' · ');\n"
    "        break;",
    "        values['tipo_valor'] = type;\n"
    "        values['valor_texto'] = selections.join(' · ');\n"
    "        break;",
    "tipo de lista normalizada",
)

datasource = replace_once(
    datasource,
    "        values['valor_booleano'] = {'si', 'true', '1'}.contains(normalized)\n"
    "            ? 1\n"
    "            : 0;\n"
    "        break;",
    "        values['tipo_valor'] = 'booleano';\n"
    "        values['valor_booleano'] = {'si', 'true', '1'}.contains(normalized)\n"
    "            ? 1\n"
    "            : 0;\n"
    "        break;",
    "tipo booleano normalizado",
)

datasource = replace_once(
    datasource,
    "      default:\n"
    "        values['valor_texto'] = trimmed;\n"
    "        break;",
    "      default:\n"
    "        values['tipo_valor'] = 'texto';\n"
    "        values['valor_texto'] = trimmed;\n"
    "        break;",
    "tipo texto normalizado",
)

datasource = regex_once(
    datasource,
    r'''  \(String, String\) _separarValorUnidad\(String raw\) \{
.*?
  \}

  String _normalizarNombreAtributo''',
    '''  (String, String) _separarValorUnidad(String raw) {
    final separated = ValorTecnicoParser.separarValorUnidad(raw);
    return (separated.valor, separated.unidad);
  }

  String _normalizarNombreAtributo''',
    "separación avanzada de valor y unidad",
)

contents["datasource"] = datasource

# ---------------------------------------------------------------------------
# SQLite versión 21 y catálogo de unidades.
# ---------------------------------------------------------------------------

database = contents["database"]

database = replace_once(
    database,
    "      version: 20,",
    "      version: 21,",
    "subir SQLite a versión 21",
)

database = replace_once(
    database,
    "       valor_texto TEXT,\n"
    "       valor_numero REAL,\n"
    "       valor_booleano INTEGER,\n"
    "       valor_normalizado REAL,\n",
    "       tipo_valor TEXT NOT NULL DEFAULT 'texto',\n"
    "       valor_texto TEXT,\n"
    "       valor_numero REAL,\n"
    "       valor_numero_hasta REAL,\n"
    "       valor_booleano INTEGER,\n"
    "       valor_normalizado REAL,\n"
    "       valor_normalizado_hasta REAL,\n",
    "columnas técnicas en bases nuevas",
)

database = replace_once(
    database,
    "        if (oldVersion < 20) {\n"
    "          await _migrarCodigoProveedorVariantes(db);\n"
    "        }\n",
    "        if (oldVersion < 20) {\n"
    "          await _migrarCodigoProveedorVariantes(db);\n"
    "        }\n"
    "        if (oldVersion < 21) {\n"
    "          await _migrarValoresTecnicos(db);\n"
    "        }\n",
    "migración versión 21",
)

migration_methods = r'''  Future<void> _migrarValoresTecnicos(Database db) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info(producto_atributos)',
    );
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
      ('unit-psi', 'psi', 'Libra por pulgada cuadrada', 'psi', 'Presión', 6894.757293, 4),
      ('unit-mpa', 'MPa', 'Megapascal', 'MPa', 'Presión', 1000000.0, 4),
      ('unit-ml-min', 'ml/min', 'Mililitro por minuto', 'ml/min', 'Caudal', 1.0, 3),
      ('unit-din-s', 'DIN-s', 'Segundo DIN', 'DIN-s', 'Viscosidad', 1.0, 2),
      ('unit-celsius', 'C', 'Grado Celsius', '°C', 'Temperatura', 1.0, 2),
    ];

    for (final unit in units) {
      await db.insert(
        'unidades_medida',
        {
          'id': unit.$1,
          'codigo': unit.$2,
          'nombre': unit.$3,
          'simbolo': unit.$4,
          'magnitud': unit.$5,
          'factor_a_base': unit.$6,
          'decimales': unit.$7,
          'estado': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

'''

database = replace_once(
    database,
    "  Future<void> _migrarCodigoProveedorVariantes(Database db) async {",
    migration_methods
    + "  Future<void> _migrarCodigoProveedorVariantes(Database db) async {",
    "métodos de migración técnica",
)

database = replace_once(
    database,
    "    for (final unit in units) {\n"
    "      await db.insert('unidades_medida', {\n"
    "        'id': unit.$1,\n"
    "        'codigo': unit.$2,\n"
    "        'nombre': unit.$3,\n"
    "        'simbolo': unit.$4,\n"
    "        'magnitud': unit.$5,\n"
    "        'factor_a_base': unit.$6,\n"
    "        'decimales': unit.$7,\n"
    "        'estado': 1,\n"
    "      }, conflictAlgorithm: ConflictAlgorithm.ignore);\n"
    "    }\n"
    "  }\n\n"
    "  Future<void> _migrarAtributosDef(Database db) async {",
    "    for (final unit in units) {\n"
    "      await db.insert('unidades_medida', {\n"
    "        'id': unit.$1,\n"
    "        'codigo': unit.$2,\n"
    "        'nombre': unit.$3,\n"
    "        'simbolo': unit.$4,\n"
    "        'magnitud': unit.$5,\n"
    "        'factor_a_base': unit.$6,\n"
    "        'decimales': unit.$7,\n"
    "        'estado': 1,\n"
    "      }, conflictAlgorithm: ConflictAlgorithm.ignore);\n"
    "    }\n"
    "    await _asegurarUnidadesTecnicas(db);\n"
    "  }\n\n"
    "  Future<void> _migrarAtributosDef(Database db) async {",
    "sembrar unidades técnicas en bases nuevas",
)

contents["database"] = database

# ---------------------------------------------------------------------------
# Unidades disponibles al crear características excepcionales.
# ---------------------------------------------------------------------------

single = contents["single"]
single = replace_once(
    single,
    "    'Ah',\n"
    "    'W',\n"
    "    'un.',",
    "    'Ah',\n"
    "    'W',\n"
    "    'Hz',\n"
    "    'rpm',\n"
    "    'bpm',\n"
    "    'Nm',\n"
    "    'J',\n"
    "    'bar',\n"
    "    'psi',\n"
    "    'MPa',\n"
    "    'ml/min',\n"
    "    'DIN-s',\n"
    "    '°C',\n"
    "    'un.',",
    "unidades técnicas en producto único",
)
contents["single"] = single

# ---------------------------------------------------------------------------
# Pruebas de dominio.
# ---------------------------------------------------------------------------

test_content = r'''import 'package:flutter_test/flutter_test.dart';

import 'package:app_catalogo/features/catalogo/domain/entities/producto_variante.dart';
import 'package:app_catalogo/features/catalogo/domain/services/valor_tecnico_parser.dart';

void main() {
  group('ValorTecnicoParser', () {
    test('normaliza fracciones sin perder el texto original', () {
      final parsed = ValorTecnicoParser.parse('1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.minimo, closeTo(0.5, 0.000001));
      expect(parsed.original, '1/2');
      expect(parsed.unidad, '″');
    });

    test('normaliza números mixtos', () {
      final parsed = ValorTecnicoParser.parse('1 1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.minimo, closeTo(1.5, 0.000001));
    });

    test('reconoce un rango con unidad', () {
      final separated =
          ValorTecnicoParser.separarValorUnidad('220–240 V');
      final parsed = ValorTecnicoParser.parse(
        separated.valor,
        unidad: separated.unidad,
      );

      expect(separated.valor, '220–240');
      expect(separated.unidad, 'V');
      expect(parsed.tipo, TipoValorTecnico.rango);
      expect(parsed.minimo, 220);
      expect(parsed.maximo, 240);
    });

    test('reconoce frecuencia compuesta 50/60 Hz', () {
      final separated =
          ValorTecnicoParser.separarValorUnidad('50/60 Hz');
      final parsed = ValorTecnicoParser.parse(
        separated.valor,
        unidad: separated.unidad,
      );

      expect(parsed.tipo, TipoValorTecnico.compuesto);
      expect(parsed.valores, [50, 60]);
    });

    test('mantiene 1/2 como fracción y no como valor compuesto', () {
      final parsed = ValorTecnicoParser.parse('1/2', unidad: '″');

      expect(parsed.tipo, TipoValorTecnico.numero);
      expect(parsed.valores, [0.5]);
    });

    test('no separa una descripción textual como valor y unidad', () {
      final separated =
          ValorTecnicoParser.separarValorUnidad('Acero inoxidable 304');

      expect(separated.valor, 'Acero inoxidable 304');
      expect(separated.unidad, isEmpty);
    });
  });

  test('AtributoProductoVariante conserva rango y selección múltiple', () {
    const original = AtributoProductoVariante(
      nombre: 'Voltaje',
      valor: '220–240',
      unidad: 'V',
      valorNormalizado: 220,
      valorMaximo: 240,
      valores: ['Monofásico', 'Trifásico'],
    );

    final restored = AtributoProductoVariante.fromMap(original.toMap());

    expect(restored.valor, '220–240');
    expect(restored.valorNormalizado, 220);
    expect(restored.valorMaximo, 240);
    expect(restored.valores, ['Monofásico', 'Trifásico']);
  });
}
'''

updates = {
    FILES[name]: content
    for name, content in contents.items()
}
updates[PARSER_PATH] = parser_content
updates[TEST_PATH] = test_content

# ---------------------------------------------------------------------------
# Escritura transaccional con respaldo.
# ---------------------------------------------------------------------------

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_fase3a_valores_tecnicos_{timestamp}"
backup_dir.mkdir(parents=True, exist_ok=False)

for path in updates:
    if not path.exists():
        continue
    target = backup_dir / path.relative_to(ROOT)
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)

for path, content in updates.items():
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Modificado: {path.relative_to(ROOT)}")

print(f"\nRespaldo: {backup_dir}")
print("\nFase 3A aplicada.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/valor_tecnico_parser_test.dart")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
