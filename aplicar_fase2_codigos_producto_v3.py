
from __future__ import annotations

from datetime import datetime
from pathlib import Path
import re
import shutil

ROOT = Path.cwd()

FILES = {
    "variant": ROOT / "lib/features/catalogo/domain/entities/producto_variante.dart",
    "bloc": ROOT / "lib/features/catalogo/presentation/bloc/producto_form_bloc.dart",
    "page": ROOT / "lib/features/catalogo/presentation/pages/producto_form_page.dart",
    "single": ROOT / "lib/features/catalogo/presentation/widgets/producto_unico_step.dart",
    "list": ROOT / "lib/features/catalogo/presentation/widgets/producto_variantes_step.dart",
    "matrix": ROOT / "lib/features/catalogo/presentation/widgets/producto_matriz_step.dart",
    "datasource": ROOT / "lib/features/catalogo/data/datasources/catalogo_local_datasource.dart",
    "database": ROOT / "lib/core/database/app_database.dart",
    "tests": ROOT / "test/producto_form_page_test.dart",
}

SERVICE = (
    ROOT
    / "lib/features/catalogo/domain/services/codigo_interno_generator.dart"
)

PHASE_MARKER = "codigoProveedor"


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


def replace_optional(content: str, old: str, new: str) -> str:
    return content.replace(old, new)


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


def _matching_delimiter(
    content: str,
    start: int,
    opening: str,
    closing: str,
) -> int:
    depth = 0
    in_single = False
    in_double = False
    escaped = False

    for index in range(start, len(content)):
        char = content[index]

        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue

        if not in_double and char == "'":
            in_single = not in_single
            continue
        if not in_single and char == '"':
            in_double = not in_double
            continue
        if in_single or in_double:
            continue

        if char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth == 0:
                return index

    return -1


def inject_new_product_code(content: str) -> str:
    if "codigo: CodigoInternoGenerator.nuevoProducto()" in content:
        return content

    marker = re.search(
        r"if\s*\(\s*event\.productoId\s*==\s*null\s*\)",
        content,
    )
    if marker is None:
        fail(
            "No se encontró el bloque de inicialización de un producto nuevo "
            "(`event.productoId == null`)."
        )

    block_start = content.find("{", marker.end())
    if block_start < 0:
        fail("El bloque de producto nuevo no tiene una llave de apertura.")

    block_end = _matching_delimiter(content, block_start, "{", "}")
    if block_end < 0:
        fail("No se pudo determinar el final del bloque de producto nuevo.")

    block = content[block_start : block_end + 1]
    copy_marker = block.find("state.copyWith")
    if copy_marker < 0:
        fail(
            "El bloque de producto nuevo no contiene `state.copyWith(...)`."
        )

    open_parenthesis = block.find("(", copy_marker)
    if open_parenthesis < 0:
        fail("No se encontró la apertura de `state.copyWith(...)`.")

    close_parenthesis = _matching_delimiter(
        block,
        open_parenthesis,
        "(",
        ")",
    )
    if close_parenthesis < 0:
        fail("No se pudo determinar el final de `state.copyWith(...)`.")

    arguments = block[open_parenthesis + 1 : close_parenthesis]
    if re.search(r"\bcodigo\s*:", arguments):
        return content

    datos_match = re.search(
        r"(?m)^(?P<indent>[ \t]*)datos\s*:\s*datos(?P<comma>\s*,?)",
        arguments,
    )

    if datos_match is not None:
        indent = datos_match.group("indent")
        original = datos_match.group(0)
        normalized = original.rstrip()
        if not normalized.endswith(","):
            normalized += ","
        replacement = (
            normalized
            + "\n"
            + indent
            + "codigo: CodigoInternoGenerator.nuevoProducto(),"
        )
        updated_arguments = (
            arguments[: datos_match.start()]
            + replacement
            + arguments[datos_match.end() :]
        )
    else:
        line_start = block.rfind("\n", 0, close_parenthesis) + 1
        closing_indent = re.match(
            r"[ \t]*",
            block[line_start:close_parenthesis],
        ).group(0)
        field_indent = closing_indent + "  "
        prefix = "\n" if arguments.strip() else ""
        updated_arguments = (
            arguments
            + prefix
            + field_indent
            + "codigo: CodigoInternoGenerator.nuevoProducto(),\n"
            + closing_indent
        )

    updated_block = (
        block[: open_parenthesis + 1]
        + updated_arguments
        + block[close_parenthesis:]
    )

    return (
        content[:block_start]
        + updated_block
        + content[block_end + 1 :]
    )


contents = {name: read(path) for name, path in FILES.items()}

if PHASE_MARKER in contents["variant"]:
    fail("La fase 2 ya parece estar aplicada.")

service_content = '''import 'package:uuid/uuid.dart';

abstract final class CodigoInternoGenerator {
  static const Uuid _uuid = Uuid();

  static String nuevoProducto() => _generate('PRD');

  static String nuevaVariante() => _generate('VAR');

  static String _generate(String prefix) {
    final token = _uuid
        .v4()
        .replaceAll('-', '')
        .substring(0, 10)
        .toUpperCase();
    return '$prefix-$token';
  }
}
'''

variant_content = '''import 'package:equatable/equatable.dart';

class AtributoProductoVariante extends Equatable {
  const AtributoProductoVariante({
    required this.nombre,
    required this.valor,
    this.unidad = '',
  });

  final String nombre;
  final String valor;
  final String unidad;

  String get texto =>
      unidad.trim().isEmpty ? valor.trim() : '${valor.trim()} ${unidad.trim()}';

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'valor': valor,
    'unidad': unidad,
  };

  factory AtributoProductoVariante.fromMap(Map<String, dynamic> map) =>
      AtributoProductoVariante(
        nombre: map['nombre'] as String? ?? '',
        valor: map['valor']?.toString() ?? '',
        unidad: map['unidad'] as String? ?? '',
      );

  factory AtributoProductoVariante.fromText(String nombre, String texto) {
    final value = texto.trim();
    final match = RegExp(
      r'^([-+]?[0-9]+(?:[.,][0-9]+)?)\\s*([^\\d\\s].*)$',
    ).firstMatch(value);
    return AtributoProductoVariante(
      nombre: nombre,
      valor: match?.group(1)?.replaceAll(',', '.') ?? value,
      unidad: match?.group(2)?.trim() ?? '',
    );
  }

  @override
  List<Object?> get props => [nombre, valor, unidad];
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
            .where((atributo) => atributo.valor.trim().isNotEmpty)
            .map(
              (atributo) =>
                  '${atributo.nombre.trim().toLowerCase()}:'
                  '${atributo.valor.trim().toLowerCase()}:'
                  '${atributo.unidad.trim().toLowerCase()}',
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

bloc = contents["bloc"]
bloc = replace_once(
    bloc,
    "import '../../domain/entities/producto_variante.dart';\n",
    "import '../../domain/entities/producto_variante.dart';\n"
    "import '../../domain/services/codigo_interno_generator.dart';\n",
    "importar generador en el BLoC",
)
bloc = replace_once(
    bloc,
    "          codigo: '',\n          variantes: const [],",
    "          variantes: const [],",
    "preservar código de producto al cambiar tipo",
)
bloc = inject_new_product_code(bloc)
bloc = replace_once(
    bloc,
    "          variantes: variantes,\n          codigo: variantes.first.sku,\n"
    "          edicionVariantePendiente: false,",
    "          variantes: variantes,\n"
    "          edicionVariantePendiente: false,",
    "no reemplazar código de producto al guardar variante",
)
bloc = replace_once(
    bloc,
    "          variantes: event.variantes,\n"
    "          codigo: event.variantes.firstOrNull?.sku ?? '',\n"
    "          edicionVariantePendiente: false,",
    "          variantes: event.variantes,\n"
    "          edicionVariantePendiente: false,",
    "no reemplazar código de producto al reemplazar variantes",
)
bloc = replace_once(
    bloc,
    "          variantes: variantes,\n"
    "          codigo: variantes.firstOrNull?.sku ?? '',\n"
    "          edicionVariantePendiente: false,",
    "          variantes: variantes,\n"
    "          edicionVariantePendiente: false,",
    "no reemplazar código de producto al eliminar variante",
)
bloc = replace_once(
    bloc,
    "    codigo: state.variantes.first.sku.trim().toUpperCase(),",
    "    codigo: state.codigo.trim().isEmpty\n"
    "        ? CodigoInternoGenerator.nuevoProducto()\n"
    "        : state.codigo.trim().toUpperCase(),",
    "persistir código PRD",
)
contents["bloc"] = bloc

page = contents["page"]
page = replace_once(
    page,
    '''      TextFormField(
        initialValue: state.codigo,
        textCapitalization: TextCapitalization.characters,
        onChanged: (value) => context.read<ProductoFormBloc>().add(
          ProductoFormFamiliaCambiada(codigo: value),
        ),
        decoration: _decoration(
          'Código único *',
          Icons.qr_code_2,
          helperText: 'Debe ser único en todo el catálogo.',
        ),
      ),''',
    '''      TextFormField(
        initialValue: state.codigo,
        readOnly: true,
        decoration: _decoration(
          'Código interno',
          Icons.qr_code_2,
          helperText: 'Se genera automáticamente y no cambia al renombrar.',
        ),
      ),''',
    "código interno de solo lectura en edición",
)
contents["page"] = page

single = contents["single"]
single = replace_once(
    single,
    "import '../../domain/entities/producto_variante.dart';\n",
    "import '../../domain/entities/producto_variante.dart';\n"
    "import '../../domain/services/codigo_interno_generator.dart';\n",
    "importar generador en producto único",
)
single = replace_once(
    single,
    "  final _singleSkuController = TextEditingController();\n"
    "  final _singleNameController = TextEditingController();",
    "  final _singleInternalCodeController = TextEditingController();\n"
    "  final _singleSupplierCodeController = TextEditingController();\n"
    "  final _singleNameController = TextEditingController();",
    "controladores de códigos en producto único",
)
single = replace_once(
    single,
    "  final Set<String> _singleReservedSkus = {};\n\n"
    "  String? _singleOriginalSku;\n"
    "  late String _singleGeneratedSku;",
    "  late String _singleGeneratedSku;",
    "eliminar estado de SKU manual en producto único",
)
single = replace_once(
    single,
    "    _singleSkuController.dispose();\n",
    "    _singleInternalCodeController.dispose();\n"
    "    _singleSupplierCodeController.dispose();\n",
    "dispose de códigos en producto único",
)
single = regex_once(
    single,
    r'''    for \(final variante in widget\.state\.variantes\) \{
      if \(variante\.id != existing\?\.id && variante\.sku\.trim\(\)\.isNotEmpty\) \{
        _singleReservedSkus\.add\(variante\.sku\.trim\(\)\.toUpperCase\(\)\);
      \}
    \}

    final savedSku = existing\?\.sku\.trim\(\) \?\? '';
    final autogenerated = savedSku\.startsWith\('AUTO-SINGLE-'\);
    _singleGeneratedSku = autogenerated \|\| savedSku\.isEmpty
        \? \(savedSku\.isEmpty
              \? 'AUTO-SINGLE-\$\{DateTime\.now\(\)\.microsecondsSinceEpoch\}'
              : savedSku\)
        : 'AUTO-SINGLE-\$\{DateTime\.now\(\)\.microsecondsSinceEpoch\}';
    _singleOriginalSku = savedSku\.isEmpty \? null : savedSku\.toUpperCase\(\);
    _singleSkuController\.text = autogenerated \? '' : savedSku;''',
    '''    final savedSku = existing?.sku.trim() ?? '';
    _singleGeneratedSku = savedSku.isEmpty
        ? CodigoInternoGenerator.nuevaVariante()
        : savedSku.toUpperCase();
    _singleInternalCodeController.text = _singleGeneratedSku;
    _singleSupplierCodeController.text = existing?.codigoProveedor ?? '';''',
    "inicialización de códigos en producto único",
)
single = regex_once(
    single,
    r'''  String\? _validateSingleSku\(String\? rawValue\) \{
.*?
  \}

  bool _isValidSingleNumericValue''',
    '''  String? _validateSingleSupplierCode(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    return value.length > 100
        ? 'El código del proveedor admite hasta 100 caracteres.'
        : null;
  }

  bool _isValidSingleNumericValue''',
    "validación de código proveedor en producto único",
)
single = replace_once(
    single,
    '''  String get _effectiveSku {
    final sku = _singleSkuController.text.trim().toUpperCase();
    return sku.isEmpty ? _singleGeneratedSku : sku;
  }''',
    '''  String get _effectiveSku => _singleGeneratedSku;''',
    "código interno efectivo en producto único",
)
single = replace_once(
    single,
    "      sku: _effectiveSku,\n"
    "      nombreCorto: _singleNameController.text.trim(),",
    "      sku: _effectiveSku,\n"
    "      codigoProveedor: _singleSupplierCodeController.text.trim().toUpperCase(),\n"
    "      nombreCorto: _singleNameController.text.trim(),",
    "guardar código proveedor en producto único",
)
single = replace_once(
    single,
    "    final skuError = _validateSingleSku(_singleSkuController.text);",
    "    final skuError = _validateSingleSupplierCode(\n"
    "      _singleSupplierCodeController.text,\n"
    "    );",
    "validar proveedor al guardar borrador único",
)

single_identification = '''            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final internalCodeField = _buildSingleTextField(
                  fieldKey: const Key('producto_unico_codigo_interno'),
                  label: 'Código interno',
                  controller: _singleInternalCodeController,
                  hint: 'VAR-XXXXXXXXXX',
                  helper: 'Generado automáticamente. No es editable.',
                  readOnly: true,
                );
                final supplierCodeField = _buildSingleTextField(
                  fieldKey: const Key('producto_unico_codigo_proveedor'),
                  label: 'Código del proveedor (opcional)',
                  controller: _singleSupplierCodeController,
                  hint: 'UY-MG16',
                  helper: 'Cópialo exactamente como aparece en el catálogo.',
                  textCapitalization: TextCapitalization.characters,
                  validator: _validateSingleSupplierCode,
                );
                final nameField = _buildSingleTextField(
                  fieldKey: const Key('producto_unico_nombre'),
                  label: 'Nombre comercial corto *',
                  controller: _singleNameController,
                  hint: 'Martillo de goma 16 oz',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre comercial.'
                      : null,
                );
                if (compact) {
                  return Column(
                    children: [
                      internalCodeField,
                      const SizedBox(height: 16),
                      supplierCodeField,
                      const SizedBox(height: 16),
                      nameField,
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: internalCodeField),
                        const SizedBox(width: 18),
                        Expanded(child: supplierCodeField),
                      ],
                    ),
                    const SizedBox(height: 16),
                    nameField,
                  ],
                );
              },
            ),'''

single = regex_once(
    single,
    r'''            LayoutBuilder\(
              builder: \(context, constraints\) \{
                final compact = constraints\.maxWidth < 680;
                final skuField = _buildSingleTextField\(.*?
              \},
            \),''',
    single_identification,
    "campos de identificación del producto único",
)
single = replace_once(
    single,
    "    TextCapitalization textCapitalization = TextCapitalization.none,\n"
    "  }) => Column(",
    "    TextCapitalization textCapitalization = TextCapitalization.none,\n"
    "    bool readOnly = false,\n"
    "  }) => Column(",
    "parámetro readOnly del campo único",
)
single = replace_once(
    single,
    "        textCapitalization: textCapitalization,\n"
    "        decoration: _singleInputDecoration(hint: hint, helper: helper),",
    "        textCapitalization: textCapitalization,\n"
    "        readOnly: readOnly,\n"
    "        decoration: _singleInputDecoration(hint: hint, helper: helper),",
    "aplicar readOnly en producto único",
)
contents["single"] = single

variant_list = contents["list"]
variant_list = replace_once(
    variant_list,
    "import '../../domain/entities/producto_variante.dart';\n",
    "import '../../domain/entities/producto_variante.dart';\n"
    "import '../../domain/services/codigo_interno_generator.dart';\n",
    "importar generador en lista",
)
variant_list = replace_once(
    variant_list,
    "  final _sku = TextEditingController();\n"
    "  final _nombre = TextEditingController();",
    "  final _sku = TextEditingController();\n"
    "  final _codigoProveedor = TextEditingController();\n"
    "  final _nombre = TextEditingController();",
    "controlador del código proveedor en lista",
)
variant_list = replace_once(
    variant_list,
    "    _sku.dispose();\n    _nombre.dispose();",
    "    _sku.dispose();\n"
    "    _codigoProveedor.dispose();\n"
    "    _nombre.dispose();",
    "dispose del proveedor en lista",
)
variant_list = replace_once(
    variant_list,
    "'Cada variante representa un artículo exacto con su propio SKU.'",
    "'Cada variante recibe un código interno automático y puede conservar el código del proveedor.'",
    "ayuda superior de lista",
)
variant_list = replace_optional(
    variant_list,
    "'Agrega el primer artículo con su código y atributos.'",
    "'Agrega el primer artículo; el código interno se generará automáticamente.'",
)
variant_list = replace_optional(
    variant_list,
    "'Úsala cuando cada artículo tiene SKU o características '",
    "'Úsala cuando cada artículo tiene medidas, modelos o características '",
)
variant_list = replace_once(
    variant_list,
    "              DataColumn(label: Text('Código')),\n"
    "              DataColumn(label: Text('Nombre corto')),",
    "              DataColumn(label: Text('Código interno')),\n"
    "              DataColumn(label: Text('Código proveedor')),\n"
    "              DataColumn(label: Text('Nombre corto')),",
    "columnas de códigos en lista",
)
variant_list = replace_once(
    variant_list,
    '''                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        variante.nombreCorto,''',
    '''                  DataCell(
                    SizedBox(
                      width: 130,
                      child: Text(
                        variante.codigoProveedor.trim().isEmpty
                            ? '—'
                            : variante.codigoProveedor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        variante.nombreCorto,''',
    "celda de código proveedor en lista",
)

editor_codes = '''              _field(
                key: const Key('variante_codigo_interno'),
                label: 'Código interno',
                controller: _sku,
                hint: 'VAR-XXXXXXXXXX',
                validator: _validarSku,
                readOnly: true,
              ),
              const SizedBox(height: 15),
              _field(
                key: const Key('variante_codigo_proveedor'),
                label: 'Código del proveedor (opcional)',
                controller: _codigoProveedor,
                hint: 'UY-BTR204',
                capitalization: TextCapitalization.characters,
              ),'''

variant_list = regex_once(
    variant_list,
    r'''              _field\(
                key: const Key\('variante_sku'\),
                label: 'Código / SKU \*',
                controller: _sku,
                hint: 'UY-BTR204',
                capitalization: TextCapitalization\.characters,
                validator: _validarSku,
              \),''',
    editor_codes,
    "campos de códigos en editor de lista",
)
variant_list = replace_once(
    variant_list,
    "    TextCapitalization capitalization = TextCapitalization.none,\n"
    "  }) => Column(",
    "    TextCapitalization capitalization = TextCapitalization.none,\n"
    "    bool readOnly = false,\n"
    "  }) => Column(",
    "parámetro readOnly del campo de lista",
)
variant_list = replace_once(
    variant_list,
    "        textCapitalization: capitalization,\n"
    "        onChanged: (_) => _marcarPendiente(),",
    "        textCapitalization: capitalization,\n"
    "        readOnly: readOnly,\n"
    "        onChanged: readOnly ? null : (_) => _marcarPendiente(),",
    "aplicar readOnly en lista",
)
variant_list = replace_once(
    variant_list,
    "    _sku.clear();\n    _nombre.clear();",
    "    _sku.text = CodigoInternoGenerator.nuevaVariante();\n"
    "    _codigoProveedor.clear();\n"
    "    _nombre.clear();",
    "generar código al crear variante",
)
variant_list = replace_once(
    variant_list,
    "    _sku.text = variante.sku;\n"
    "    _nombre.text = variante.nombreCorto;",
    "    _sku.text = variante.sku;\n"
    "    _codigoProveedor.text = variante.codigoProveedor;\n"
    "    _nombre.text = variante.nombreCorto;",
    "cargar código proveedor en lista",
)
variant_list = replace_once(
    variant_list,
    "      sku: _sku.text.trim().toUpperCase(),\n"
    "      nombreCorto: _nombre.text.trim(),",
    "      sku: _sku.text.trim().toUpperCase(),\n"
    "      codigoProveedor: _codigoProveedor.text.trim().toUpperCase(),\n"
    "      nombreCorto: _nombre.text.trim(),",
    "guardar proveedor en lista",
)
variant_list = replace_once(
    variant_list,
    "      id: const Uuid().v4(),\n"
    "      sku: _siguienteSkuCopia(selected.sku),\n"
    "      nombreCorto: '${selected.nombreCorto} (copia)',",
    "      id: const Uuid().v4(),\n"
    "      sku: CodigoInternoGenerator.nuevaVariante(),\n"
    "      codigoProveedor: '',\n"
    "      nombreCorto: '${selected.nombreCorto} (copia)',",
    "duplicar con nuevo código interno",
)
variant_list = regex_once(
    variant_list,
    r'''  String _siguienteSkuCopia\(String sku\) \{
.*?
  \}

  String\? _validarSku''',
    '''  String? _validarSku''',
    "eliminar generación manual de copia",
)
variant_list = replace_optional(
    variant_list,
    "if (sku.isEmpty) return 'Ingresa el código o SKU.';",
    "if (sku.isEmpty) return 'No se pudo generar el código interno.';",
)
variant_list = replace_optional(
    variant_list,
    "return duplicated ? 'Este SKU ya existe en la familia.' : null;",
    "return duplicated ? 'El código interno está duplicado.' : null;",
)
contents["list"] = variant_list

matrix = contents["matrix"]
matrix = replace_once(
    matrix,
    "import '../../domain/entities/producto_variante.dart';\n",
    "import '../../domain/entities/producto_variante.dart';\n"
    "import '../../domain/services/codigo_interno_generator.dart';\n",
    "importar generador en matriz",
)
matrix = replace_once(
    matrix,
    "enum _MatrixGeneralAction { generateNames, generateSkus, applyAttribute }",
    "enum _MatrixGeneralAction { generateNames, applyAttribute }",
    "quitar generación de SKU por patrón",
)
matrix = replace_once(
    matrix,
    "    required this.sku,\n"
    "    required this.generatedName,",
    "    required this.sku,\n"
    "    required this.supplierCode,\n"
    "    required this.generatedName,",
    "supplierCode en constructor matricial",
)
matrix = replace_once(
    matrix,
    "  final String sku;\n"
    "  final String generatedName;",
    "  final String sku;\n"
    "  final String supplierCode;\n"
    "  final String generatedName;",
    "campo supplierCode matricial",
)
matrix = replace_once(
    matrix,
    "    String? sku,\n"
    "    String? generatedName,",
    "    String? sku,\n"
    "    String? supplierCode,\n"
    "    String? generatedName,",
    "copyWith supplierCode matricial",
)
matrix = replace_once(
    matrix,
    "    sku: sku ?? this.sku,\n"
    "    generatedName: generatedName ?? this.generatedName,",
    "    sku: sku ?? this.sku,\n"
    "    supplierCode: supplierCode ?? this.supplierCode,\n"
    "    generatedName: generatedName ?? this.generatedName,",
    "asignar supplierCode matricial",
)
matrix = replace_once(
    matrix,
    "  final _matrixSkuController = TextEditingController();\n"
    "  final _matrixNameController = TextEditingController();",
    "  final _matrixSkuController = TextEditingController();\n"
    "  final _matrixSupplierCodeController = TextEditingController();\n"
    "  final _matrixNameController = TextEditingController();",
    "controlador proveedor matricial",
)
matrix = replace_once(
    matrix,
    "    _matrixSkuController.dispose();\n"
    "    _matrixNameController.dispose();",
    "    _matrixSkuController.dispose();\n"
    "    _matrixSupplierCodeController.dispose();\n"
    "    _matrixNameController.dispose();",
    "dispose proveedor matricial",
)
matrix = replace_once(
    matrix,
    "                sku: saved.sku,\n"
    "                generatedName: saved.nombreCorto,",
    "                sku: saved.sku,\n"
    "                supplierCode: saved.codigoProveedor,\n"
    "                generatedName: saved.nombreCorto,",
    "cargar proveedor desde variante matricial",
)
matrix = replace_once(
    matrix,
    "      sku: _generateDefaultMatrixSku(columnLabel, rowLabel),\n"
    "      generatedName: '$_matrixFamilyLabel $columnLabel × $rowLabel',",
    "      sku: CodigoInternoGenerator.nuevaVariante(),\n"
    "      supplierCode: '',\n"
    "      generatedName: '$_matrixFamilyLabel $columnLabel × $rowLabel',",
    "generar código matricial independiente",
)
matrix = regex_once(
    matrix,
    r'''  String _matrixCodeToken\(String value\) =>
.*?
  void _loadMatrixEditor''',
    '''  void _loadMatrixEditor''',
    "eliminar generador matricial basado en nombres",
)
matrix = replace_once(
    matrix,
    "    _matrixSkuController.text = combination.sku;\n"
    "    _matrixNameController.text = combination.generatedName;",
    "    _matrixSkuController.text = combination.sku;\n"
    "    _matrixSupplierCodeController.text = combination.supplierCode;\n"
    "    _matrixNameController.text = combination.generatedName;",
    "cargar proveedor en editor matricial",
)
matrix = replace_once(
    matrix,
    "      case _MatrixGeneralAction.generateSkus:\n"
    "        await _showMatrixSkuPatternDialog();\n",
    "",
    "quitar acción de patrón SKU",
)
matrix = regex_once(
    matrix,
    r'''  Future<void> _showMatrixSkuPatternDialog\(\) async \{
.*?
  \}

  Future<void> _showApplyMatrixAttributeDialog''',
    '''  Future<void> _showApplyMatrixAttributeDialog''',
    "eliminar diálogo de patrón SKU",
)
matrix = replace_once(
    matrix,
    "      sku: _matrixSkuController.text.trim().toUpperCase(),\n"
    "      generatedName: _matrixNameController.text.trim(),",
    "      sku: _matrixSkuController.text.trim().toUpperCase(),\n"
    "      supplierCode: _matrixSupplierCodeController.text.trim().toUpperCase(),\n"
    "      generatedName: _matrixNameController.text.trim(),",
    "guardar proveedor matricial",
)
matrix = replace_once(
    matrix,
    "      sku: combination.sku.trim().toUpperCase(),\n"
    "      nombreCorto: combination.generatedName.trim(),",
    "      sku: combination.sku.trim().toUpperCase(),\n"
    "      codigoProveedor: combination.supplierCode.trim().toUpperCase(),\n"
    "      nombreCorto: combination.generatedName.trim(),",
    "sincronizar proveedor matricial",
)
matrix = regex_once(
    matrix,
    r'''          PopupMenuItem\(
            value: _MatrixGeneralAction\.generateSkus,
            child: ListTile\(
              dense: true,
              contentPadding: EdgeInsets\.zero,
              leading: Icon\(Icons\.qr_code_2_outlined\),
              title: Text\('Generar SKU mediante patrón'\),
            \),
          \),
''',
    "",
    "quitar menú de generación SKU",
)
matrix = replace_optional(
    matrix,
    "'$_matrixReadyCount variantes listas · '\n"
    "                        '$_matrixDuplicateSkuCount SKU duplicados'",
    "'$_matrixReadyCount variantes listas · '\n"
    "                        '$_matrixDuplicateSkuCount códigos internos duplicados'",
)

matrix_form = '''        _buildMatrixTextField(
          fieldKey: const Key('matriz_codigo_interno'),
          label: 'Código interno',
          controller: _matrixSkuController,
          hint: 'VAR-XXXXXXXXXX',
          validator: _validateMatrixSku,
          readOnly: true,
        ),
        const SizedBox(height: 14),
        _buildMatrixTextField(
          fieldKey: const Key('matriz_codigo_proveedor'),
          label: 'Código del proveedor (opcional)',
          controller: _matrixSupplierCodeController,
          hint: 'PER-384',
        ),'''

matrix = regex_once(
    matrix,
    r'''        _buildMatrixTextField\(
          fieldKey: const Key\('matriz_sku'\),
          label: 'Código / SKU',
          controller: _matrixSkuController,
          hint: 'PER-384',
          validator: _validateMatrixSku,
        \),''',
    matrix_form,
    "campos de códigos matriciales",
)
matrix = replace_once(
    matrix,
    "    int maxLines = 1,\n"
    "  }) => Column(",
    "    int maxLines = 1,\n"
    "    bool readOnly = false,\n"
    "  }) => Column(",
    "parámetro readOnly matricial",
)
matrix = replace_once(
    matrix,
    "        maxLines: maxLines,\n"
    "        onChanged: (_) => _markMatrixEditorDirty(),",
    "        maxLines: maxLines,\n"
    "        readOnly: readOnly,\n"
    "        onChanged: readOnly ? null : (_) => _markMatrixEditorDirty(),",
    "aplicar readOnly matricial",
)
matrix = replace_optional(
    matrix,
    "if (sku.isEmpty) return 'Ingresa el código o SKU.';",
    "if (sku.isEmpty) return 'No se pudo generar el código interno.';",
)
matrix = replace_optional(
    matrix,
    "return duplicated ? 'Este SKU ya está en uso.' : null;",
    "return duplicated ? 'El código interno está duplicado.' : null;",
)
contents["matrix"] = matrix

datasource = contents["datasource"]
datasource = regex_once(
    datasource,
    r'''  Future<List<ProductoResumen>> buscarProductos\(String query\) async \{
.*?
  \}

  Future<ProductoDetalle\?> obtenerDetalleProducto''',
    '''  Future<List<ProductoResumen>> buscarProductos(String query) async {
    final texto = '%${query.trim()}%';
    final rows = await (await _db).rawQuery(
      'SELECT DISTINCT p.* '
      'FROM productos p '
      'LEFT JOIN producto_variantes_catalogo pv ON pv.producto_id = p.id '
      'WHERE p.codigo LIKE ? '
      'OR p.nombre LIKE ? '
      'OR p.empresa LIKE ? '
      'OR p.marca LIKE ? '
      'OR p.categoria LIKE ? '
      'OR pv.sku LIKE ? '
      'OR pv.codigo_proveedor LIKE ? '
      'ORDER BY p.creado_en DESC',
      [texto, texto, texto, texto, texto, texto, texto],
    );
    return rows.map(_resumenFromMap).toList();
  }

  Future<ProductoDetalle?> obtenerDetalleProducto''',
    "buscar por códigos internos y proveedor",
)
datasource = replace_once(
    datasource,
    "        'sku': variant.sku.trim().toUpperCase(),\n"
    "        'nombre_corto': variant.nombreCorto.trim(),",
    "        'sku': variant.sku.trim().toUpperCase(),\n"
    "        'codigo_proveedor': variant.codigoProveedor.trim().toUpperCase(),\n"
    "        'nombre_corto': variant.nombreCorto.trim(),",
    "persistir proveedor normalizado",
)
contents["datasource"] = datasource

database = contents["database"]
database = replace_once(
    database,
    "      version: 19,",
    "      version: 20,",
    "subir SQLite a versión 20",
)
database = replace_once(
    database,
    "      sku TEXT NOT NULL COLLATE NOCASE UNIQUE,\n"
    "      nombre_corto TEXT NOT NULL,",
    "      sku TEXT NOT NULL COLLATE NOCASE UNIQUE,\n"
    "      codigo_proveedor TEXT NOT NULL DEFAULT '',\n"
    "      nombre_corto TEXT NOT NULL,",
    "columna proveedor en creación inicial",
)
database = replace_once(
    database,
    "        if (oldVersion < 19) {\n"
    "          await _crearTablasAtributosCategoria(db);\n"
    "          await _migrarAtributosDef(db);\n"
    "        }\n",
    "        if (oldVersion < 19) {\n"
    "          await _crearTablasAtributosCategoria(db);\n"
    "          await _migrarAtributosDef(db);\n"
    "        }\n"
    "        if (oldVersion < 20) {\n"
    "          await _migrarCodigoProveedorVariantes(db);\n"
    "        }\n",
    "migración versión 20",
)

migration_method = '''  Future<void> _migrarCodigoProveedorVariantes(Database db) async {
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

'''

database = replace_once(
    database,
    "  Future<void> _crearTablasEstructuraCatalogo(Database db) async {",
    migration_method
    + "  Future<void> _crearTablasEstructuraCatalogo(Database db) async {",
    "método de migración de proveedor",
)
database = replace_once(
    database,
    "    await db.execute('''CREATE TABLE IF NOT EXISTS producto_familia_ejes(",
    "    await db.execute(\n"
    "      'CREATE INDEX IF NOT EXISTS idx_variantes_codigo_proveedor '\n"
    "      'ON producto_variantes_catalogo(codigo_proveedor)',\n"
    "    );\n"
    "    await db.execute('''CREATE TABLE IF NOT EXISTS producto_familia_ejes(",
    "índice proveedor en bases nuevas",
)
contents["database"] = database

tests = contents["tests"]
tests = replace_once(
    tests,
    "        find.byKey(const Key('matriz_sku')),\n"
    "        'MATRIX-EDITADO',",
    "        find.byKey(const Key('matriz_codigo_proveedor')),\n"
    "        'MATRIX-PROV',",
    "editar proveedor en prueba matricial",
)
tests = replace_once(
    tests,
    "          (variante) => variante.sku == 'MATRIX-EDITADO',",
    "          (variante) => variante.codigoProveedor == 'MATRIX-PROV',",
    "validar proveedor matricial",
)
tests = replace_optional(
    tests,
    "startsWith('AUTO-SINGLE-')",
    "startsWith('VAR-')",
)
tests = replace_once(
    tests,
    "      expect(bloc.state.variantes, hasLength(1));\n"
    "      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));",
    "      expect(bloc.state.codigo, startsWith('PRD-'));\n"
    "      expect(bloc.state.variantes, hasLength(1));\n"
    "      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));",
    "validar código PRD en producto único",
)
tests = replace_once(
    tests,
    "      await tester.enterText(\n"
    "        find.byKey(const Key('producto_unico_nombre')),\n"
    "        'Perno hexagonal 1/2',\n"
    "      );",
    "      await tester.enterText(\n"
    "        find.byKey(const Key('producto_unico_codigo_proveedor')),\n"
    "        'DINA-PER-12',\n"
    "      );\n"
    "      await tester.enterText(\n"
    "        find.byKey(const Key('producto_unico_nombre')),\n"
    "        'Perno hexagonal 1/2',\n"
    "      );",
    "ingresar proveedor en producto único",
)
tests = replace_once(
    tests,
    "      expect(bloc.state.variantes.single.nombreCorto, 'Perno hexagonal 1/2');\n"
    "      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));",
    "      expect(bloc.state.variantes.single.nombreCorto, 'Perno hexagonal 1/2');\n"
    "      expect(bloc.state.variantes.single.sku, startsWith('VAR-'));\n"
    "      expect(bloc.state.variantes.single.codigoProveedor, 'DINA-PER-12');",
    "validar proveedor único",
)

list_test = '''  testWidgets(
    'la lista genera códigos internos y conserva el código del proveedor',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepositoryProvider<CatalogoRepository>.value(
          value: _FakeCatalogoRepository(),
          child: const MaterialApp(home: ProductoFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final bloc = context.read<ProductoFormBloc>();
      bloc
        ..add(
          const ProductoFormClasificacionCambiada(
            empresa: 'DINA',
            marca: 'DINA',
            categoria: 'Pernería',
          ),
        )
        ..add(
          const ProductoFormClasificacionCambiada(
            subcategoria: 'Pernos métricos',
          ),
        )
        ..add(const ProductoFormFamiliaCambiada(nombre: 'Familia de pernos'))
        ..add(const ProductoFormTipoCambiado('variantes'))
        ..add(
          const ProductoFormVarianteGuardada(
            ProductoVariante(
              id: 'v1',
              sku: 'SKU-001',
              codigoProveedor: 'PROV-001',
              nombreCorto: 'Perno 10 x 40',
              atributos: [
                AtributoProductoVariante(
                  nombre: 'Diámetro',
                  valor: '10',
                  unidad: 'mm',
                ),
                AtributoProductoVariante(
                  nombre: 'Largo',
                  valor: '40',
                  unidad: 'mm',
                ),
              ],
            ),
          ),
        )
        ..add(
          const ProductoFormVarianteGuardada(
            ProductoVariante(
              id: 'v2',
              sku: 'SKU-002',
              codigoProveedor: 'PROV-002',
              nombreCorto: 'Perno 12 x 50',
              atributos: [
                AtributoProductoVariante(
                  nombre: 'Diámetro',
                  valor: '12',
                  unidad: 'mm',
                ),
                AtributoProductoVariante(
                  nombre: 'Largo',
                  valor: '50',
                  unidad: 'mm',
                ),
              ],
            ),
          ),
        )
        ..add(const ProductoFormPasoSeleccionado(1));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SKU-002').first);
      await tester.tap(find.text('SKU-002').first);
      await tester.pumpAndSettle();

      final internalField = tester.widget<TextFormField>(
        find.byKey(const Key('variante_codigo_interno')),
      );
      expect(internalField.controller?.text, 'SKU-002');
      expect(internalField.readOnly, isTrue);

      await tester.ensureVisible(find.byKey(const Key('agregar_variante')));
      await tester.tap(find.byKey(const Key('agregar_variante')));
      await tester.pumpAndSettle();

      final generatedInternal = tester
          .widget<TextFormField>(
            find.byKey(const Key('variante_codigo_interno')),
          )
          .controller
          ?.text;
      expect(generatedInternal, startsWith('VAR-'));

      await tester.enterText(
        find.byKey(const Key('variante_codigo_proveedor')),
        'PROV-003',
      );
      await tester.enterText(
        find.byKey(const Key('variante_nombre')),
        'Perno repetido',
      );
      await tester.enterText(find.byKey(const Key('atributo_Diámetro')), '12');
      await tester.enterText(find.byKey(const Key('atributo_Largo')), '50');
      await tester.ensureVisible(find.byKey(const Key('guardar_variante')));
      tester
          .widget<ElevatedButton>(find.byKey(const Key('guardar_variante')))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ya existe una variante con 12 mm · 50 mm'),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('atributo_Largo')), '60');
      tester
          .widget<ElevatedButton>(find.byKey(const Key('guardar_variante')))
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(bloc.state.variantes, hasLength(3));
      expect(bloc.state.variantes.last.sku, generatedInternal);
      expect(bloc.state.variantes.last.codigoProveedor, 'PROV-003');

      final originalInternal = bloc.state.variantes.last.sku;
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('duplicar_variante_lista')),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();

      expect(bloc.state.variantes, hasLength(4));
      expect(bloc.state.variantes.last.sku, startsWith('VAR-'));
      expect(bloc.state.variantes.last.sku, isNot(originalInternal));
      expect(bloc.state.variantes.last.codigoProveedor, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

'''

tests = regex_once(
    tests,
    r'''  testWidgets\(
    'el paso 3 selecciona una variante y valida SKU y combinación duplicados',
.*?
  \);

  testWidgets\(
    'el paso 4 configura venta, logística y contenido sin desbordar',''',
    list_test
    + "  testWidgets(\n"
    "    'el paso 4 configura venta, logística y contenido sin desbordar',",
    "actualizar prueba de lista",
)

serialization_test = '''  test('serializa y restaura el código del proveedor', () {
    const variante = ProductoVariante(
      id: 'variante-1',
      sku: 'VAR-1234567890',
      codigoProveedor: 'UY-ITL02-202',
      nombreCorto: 'Taladro 20 V',
      atributos: [],
    );

    final restored = ProductoVariante.fromMap(variante.toMap());

    expect(restored.sku, 'VAR-1234567890');
    expect(restored.codigoProveedor, 'UY-ITL02-202');
  });

'''

tests = replace_once(
    tests,
    "  test('precarga y actualiza un producto existente', () async {",
    serialization_test
    + "  test('precarga y actualiza un producto existente', () async {",
    "prueba de serialización del proveedor",
)
contents["tests"] = tests

optional_updates: dict[Path, str] = {}

for schema_name in [
    "sqlite_schema_app_catalogo_v4.sql",
    "mysql_schema_app_catalogo_v4.sql",
]:
    schema_path = ROOT / schema_name
    if not schema_path.exists():
        continue
    schema = read(schema_path)
    if "codigo_proveedor" not in schema:
        if schema_name.startswith("sqlite"):
            schema = replace_once(
                schema,
                "    codigo TEXT,\n    nombre_comercial TEXT NOT NULL,",
                "    codigo TEXT NOT NULL,\n"
                "    codigo_proveedor TEXT,\n"
                "    nombre_comercial TEXT NOT NULL,",
                "schema SQLite: códigos",
            )
            schema = replace_optional(
                schema,
                "CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);",
                "CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);\n"
                "CREATE INDEX idx_variantes_codigo_proveedor ON producto_variantes(codigo_proveedor);",
            )
        else:
            schema = replace_once(
                schema,
                "    codigo VARCHAR(100) NULL,\n"
                "    nombre_comercial VARCHAR(255) NOT NULL,",
                "    codigo VARCHAR(100) NOT NULL,\n"
                "    codigo_proveedor VARCHAR(100) NULL,\n"
                "    nombre_comercial VARCHAR(255) NOT NULL,",
                "schema MySQL: códigos",
            )
            schema = replace_optional(
                schema,
                "CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);",
                "CREATE INDEX idx_variantes_empresa_codigo ON producto_variantes(empresa_id, codigo);\n"
                "CREATE INDEX idx_variantes_codigo_proveedor ON producto_variantes(codigo_proveedor);",
            )
        optional_updates[schema_path] = schema

updates = {FILES[name]: content for name, content in contents.items()}
updates[SERVICE] = service_content
updates.update(optional_updates)

timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_dir = ROOT / f".backup_fase2_codigos_{timestamp}"
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
print("\nFase 2 aplicada con el analizador estructural v3.")
print("Ejecuta:")
print("  dart format lib test")
print("  flutter test test/producto_form_page_test.dart")
print("  flutter analyze")
