import '../../domain/entities/producto.dart';

class ProductoModel extends Producto {
  const ProductoModel({
    required super.id,
    required super.nombre,
    required super.categoriaId,
    required super.precio,
    super.descripcion,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      categoriaId: map['categoria_id'] as String,
      precio: (map['precio'] as num).toDouble(),
      descripcion: map['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria_id': categoriaId,
      'precio': precio,
      'descripcion': descripcion,
    };
  }
}
