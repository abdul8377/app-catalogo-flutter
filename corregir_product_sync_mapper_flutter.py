from __future__ import annotations

from datetime import datetime
from pathlib import Path
import shutil
import sys


RELATIVE_FILE = Path(
    "lib/features/sync/data/mappers/product_sync_mapper.dart"
)

START_MARKER = "  Future<void> _restoreProjectionRows("
END_MARKER = "  Future<List<Map<String, Object?>>> _exportImages("

REPLACEMENT = r'''  Future<void> _restoreProjectionRows(
    DatabaseExecutor database, {
    required String productId,
    required Map<String, Object?> aggregate,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    for (final axis in _asMaps(aggregate['familyAxes'])) {
      final attributeId = _projectionText(axis, const [
        'categoria_atributo_id',
        'categoryAttributeId',
      ]);
      if (attributeId.isEmpty) {
        throw const FormatException(
          'PRODUCT.familyAxes contiene un eje sin categoria_atributo_id.',
        );
      }
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
    final optionRowsByAttribute = <String, List<Map<String, Object?>>>{};
    for (final option in rawOptions) {
      final attributeValueId = _projectionText(option, const [
        'producto_atributo_id',
        'productAttributeId',
      ]);
      if (attributeValueId.isNotEmpty) {
        optionRowsByAttribute
            .putIfAbsent(attributeValueId, () => <Map<String, Object?>>[])
            .add(option);
      }
    }

    final definitionByAttributeValue = <String, String>{};
    final restoredAttributeIds = <String>{};

    for (final row in _asMaps(aggregate['attributeValues'])) {
      final id = _projectionText(row, const ['id']);
      final definitionId = _projectionText(row, const [
        'categoria_atributo_id',
        'categoryAttributeId',
      ]);
      if (id.isEmpty || definitionId.isEmpty) {
        throw const FormatException(
          'PRODUCT.attributeValues requiere id y categoria_atributo_id.',
        );
      }

      final variantId = _projectionText(row, const [
        'variante_id',
        'variantId',
      ]);
      final unitRelationId = _projectionText(row, const [
        'categoria_atributo_unidad_id',
        'categoryAttributeUnitId',
      ]);
      final textValue = _projectionValue(row, const [
        'valor_texto',
        'textValue',
      ]);
      final numberValue = _projectionDouble(
        _projectionValue(row, const ['valor_numero', 'numberValue']),
      );
      final maximumValue = _projectionDouble(
        _projectionValue(row, const [
          'valor_numero_hasta',
          'valor_maximo',
          'maximumValue',
        ]),
      );
      final booleanValue = _projectionBoolean(
        _projectionValue(row, const ['valor_booleano', 'booleanValue']),
      );
      final hasOptions =
          (optionRowsByAttribute[id] ?? const <Map<String, Object?>>[]).isNotEmpty;

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
        'valor_texto': textValue,
        'valor_numero': numberValue,
        'valor_numero_hasta': maximumValue,
        'valor_booleano': booleanValue,
        'actualizado_en':
            _projectionText(row, const ['actualizado_en', 'updatedAt']).isEmpty
            ? now
            : _projectionText(row, const ['actualizado_en', 'updatedAt']),
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

      definitionByAttributeValue[id] = definitionId;
      restoredAttributeIds.add(id);
    }

    for (final row in rawOptions) {
      final attributeValueId = _projectionText(row, const [
        'producto_atributo_id',
        'productAttributeId',
      ]);
      if (!restoredAttributeIds.contains(attributeValueId)) {
        throw FormatException(
          'PRODUCT.attributeOptions referencia el atributo inexistente '
          '$attributeValueId.',
        );
      }
      final explicitDefinitionId = _projectionText(row, const [
        'categoria_atributo_id',
        'categoryAttributeId',
      ]);
      final definitionId = explicitDefinitionId.isEmpty
          ? definitionByAttributeValue[attributeValueId] ?? ''
          : explicitDefinitionId;
      final optionId = _projectionText(row, const [
        'opcion_id',
        'optionId',
      ]);
      if (definitionId.isEmpty || optionId.isEmpty) {
        throw const FormatException(
          'PRODUCT.attributeOptions requiere categoria_atributo_id '
          'y opcion_id.',
        );
      }

      final values = <String, Object?>{
        'producto_atributo_id': attributeValueId,
        'categoria_atributo_id': definitionId,
        'opcion_id': optionId,
      };
      values.removeWhere((key, _) => !optionColumns.contains(key));
      await database.insert('producto_atributo_opciones', values);
    }
  }

  Object? _projectionValue(
    Map<String, Object?> row,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (row.containsKey(key)) return row[key];
    }
    return null;
  }

  String _projectionText(
    Map<String, Object?> row,
    List<String> keys,
  ) {
    return _projectionValue(row, keys)?.toString().trim() ?? '';
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
      'SELECT unit.factor_a_base AS factor '
      'FROM categoria_atributo_unidades relation '
      'JOIN unidades_medida unit '
      'ON unit.id = relation.unidad_medida_id '
      'WHERE relation.id = ? LIMIT 1',
      [unitRelationId],
    );
    if (rows.isEmpty) return value;
    final factor = _projectionDouble(rows.single['factor']);
    return factor == null ? value : value * factor;
  }

'''


def find_app_root(start: Path) -> Path:
    for candidate in (start, start / "app_catalogo"):
        if (
            (candidate / "pubspec.yaml").exists()
            and (candidate / RELATIVE_FILE).exists()
        ):
            return candidate
    raise SystemExit(
        "No se encontro app-catalogo-flutter. Ejecuta el script desde "
        "la raiz que contiene pubspec.yaml."
    )


def main() -> None:
    app = find_app_root(Path.cwd())
    target = app / RELATIVE_FILE
    content = target.read_text(encoding="utf-8")

    print(f"Flutter detectado: {app}")
    print(f"Archivo: {target.relative_to(app)}")

    if "Future<double> _normalizedProjectionNumber(" in content:
        print("La correccion robusta de PRODUCT ya esta aplicada.")
        return

    start = content.find(START_MARKER)
    end = content.find(END_MARKER, start + 1)
    if start < 0 or end < 0 or end <= start:
        raise SystemExit(
            "No se localizaron los limites de _restoreProjectionRows. "
            "No se modifico el archivo."
        )

    backup_root = (
        app
        / ".correction_backups"
        / datetime.now().strftime("%Y%m%d_%H%M%S")
    )
    backup = backup_root / RELATIVE_FILE
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(target, backup)

    updated = content[:start] + REPLACEMENT + content[end:]
    required = (
        "'actualizado_en':",
        "'producto_id': variantId.isEmpty ? productId : null",
        "'variante_id': variantId.isEmpty ? null : variantId",
        "'categoria_atributo_id': definitionId",
        "Future<double> _normalizedProjectionNumber(",
    )
    if not all(fragment in updated for fragment in required):
        raise SystemExit(
            "La validacion interna del parche fallo. No se guardo el archivo."
        )

    target.write_text(updated, encoding="utf-8", newline="\n")
    print("Correccion Flutter aplicada.")
    print(f"Copia: {backup.relative_to(app)}")
    print()
    print("Ejecuta:")
    print(r"  & 'D:\flutter\bin\dart.bat' format lib test")
    print(r"  & 'D:\flutter\bin\dart.bat' analyze --no-fatal-warnings")
    print(r"  & 'D:\flutter\bin\flutter.bat' test --no-pub --exclude-tags baseline-known-failure")
    print(r"  & 'D:\flutter\bin\flutter.bat' run")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise
