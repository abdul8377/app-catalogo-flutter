import 'package:equatable/equatable.dart';

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
      r'^([-+]?[0-9]+(?:[.,][0-9]+)?)\s*([^\d\s].*)$',
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
