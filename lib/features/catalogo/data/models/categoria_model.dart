import '../../domain/entities/categoria.dart';

class CategoriaModel extends Categoria {
  const CategoriaModel({required super.id, required super.nombre});

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre};
  }
}
